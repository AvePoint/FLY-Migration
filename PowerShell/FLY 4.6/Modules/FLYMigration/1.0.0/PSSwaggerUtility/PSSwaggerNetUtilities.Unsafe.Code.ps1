// Copyright (c) Microsoft Corporation. All rights reserved.

// Licensed under the MIT license.

// PSSwaggerUtility Module
namespace Microsoft.PowerShell.Commands.PSSwagger
{
	using Microsoft.Rest;
    using System;
    using System.Net.Http;
    using System.Net.Http.Headers;
    using System.Runtime.CompilerServices;
    using System.Runtime.InteropServices;
    using System.Security;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
	
	public class PSBasicAuthenticationEx : ServiceClientCredentials
    {
        public string UserName { get; set; }
        public SecureString Password { get; set; }
        public PSBasicAuthenticationEx(string userName, SecureString password)
        {
            this.UserName = userName;
            this.Password = password;
        }

        public override async Task ProcessHttpRequestAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            await Task.Run(() => ProcessHttpRequest(request), cancellationToken);
        }

        private void ProcessHttpRequest(HttpRequestMessage request)
        {
            int passwordLength = this.Password.Length;
            int userNameLength = this.UserName.Length;
            int totalCredsLength = passwordLength + userNameLength + 1;
            int base64size = Base64Encoder.PredictSize(totalCredsLength);
            byte[] userNameBytes = Encoding.UTF8.GetBytes(this.UserName);
            // This array ensures we clean up the string concatenation of "username:password"
            byte[] clientCredsArr = new byte[totalCredsLength];
            // And here we need to clean up the base64 encoded string
            // 3 bytes == 4 characters, + padding
            // totalCredsLength is the number of bytes we'll eventually encode
            char[] base64string = new char[base64size];
            GCHandle byteHandle = new GCHandle();
            GCHandle strHandle = new GCHandle();
            // Ensure the insecure client cred string and the GC handle are cleaned up
            RuntimeHelpers.ExecuteCodeWithGuaranteedCleanup(delegate
            {
                // This block pins the insecure client cred string, converts the SecureString to the insecure password, frees the unpinned string, then generates the basic auth headers
                RuntimeHelpers.PrepareConstrainedRegions();
                try { }
                finally
                {
                    byteHandle = GCHandle.Alloc(clientCredsArr, GCHandleType.Pinned);
                    strHandle = GCHandle.Alloc(base64string, GCHandleType.Pinned);
                }

                
                IntPtr pBstr = IntPtr.Zero;
                // Ensure bBstr is properly cleaned up
                RuntimeHelpers.ExecuteCodeWithGuaranteedCleanup(delegate
                    {
                        RuntimeHelpers.PrepareConstrainedRegions();
                        try { }
                        finally
                        {
                            pBstr = Marshal.SecureStringToBSTR(this.Password);
                        }

                        unsafe
                        {
                            char* pTempPassword = (char*)pBstr;
                            byte* pClientCreds = (byte*)byteHandle.AddrOfPinnedObject();
                            Encoding.UTF8.GetBytes(pTempPassword, passwordLength, pClientCreds + userNameLength + 1, passwordLength);
                            for (int i = 0; i < userNameLength; i++)
                            {
                                pClientCreds[i] = userNameBytes[i];
                            }
                            pClientCreds[userNameLength] = (byte)':';
                            Base64Encoder.Encode(clientCredsArr, base64string);
                        }
                    },
                    delegate
                    {
                        if (pBstr != IntPtr.Zero)
                        {
                            Marshal.ZeroFreeBSTR(pBstr);
                        }
                    }, null);

                // Not using BasicAuthenticationCredentials here because: 1) async, 2) need to have the handle to the pinned base64 encoded string
                // NOTE: URL safe encoding?
                request.Headers.Authorization = new AuthenticationHeaderValue("Basic", new string(base64string));
            }, delegate
            {
                if (byteHandle.IsAllocated)
                {
                    unsafe
                    {
                        byte* pClientCreds = (byte*)byteHandle.AddrOfPinnedObject();
                        for (int i = 0; i < totalCredsLength; i++)
                        {
                            pClientCreds[i] = 0;
                        }

                        byteHandle.Free();

                        char* pBase64String = (char*)strHandle.AddrOfPinnedObject();
                        for (int i = 0; i < base64size; i++)
                        {
                            pBase64String[i] = '\0';
                        }

                        strHandle.Free();
                    }
                }
            }, null);
        }
    }

     public static class Base64Encoder
    {
        private const byte ls6mask = 0x3F;
        private const byte ls4mask = 0x0F;
        private const byte ls2mask = 0x03;
        private const byte ms6mask = 0xFC;
        private const byte ms4mask = 0xF0;
        private const byte ms2mask = 0xC0;
        private static char[] base64encoding = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
                                                 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
                                                 '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/' };
        private static Func<byte?, byte?, byte>[] base64encoder =
        {
            (b1, b2) =>
            {
                // MS6 of b2
                return (byte)((b2 & ms6mask) >> 2);
            },
            (b1, b2) =>
            {
                // LS2 of b1 + MS4 of b2
                return (byte)((byte)((b1 & ls2mask) << 4) | (byte)((b2 & ms4mask) >> 4));
            },
            (b1, b2) =>
            {
                // LS4 of b1 + MS2 of b2
                return (byte)((byte)((b1 & ls4mask) << 2) | (byte)((b2 & ms2mask) >> 6));
            },
            (b1, b2) =>
            {
                // LS6 of b1
                return (byte)(b1 & ls6mask);
            }
        };

        public static void Encode(byte[] bytesToEncode, char[] charsToCopyOut)
        {
            int charOutIndex = 0;
            byte[] currentEncodingBuffer = new byte[2];
            int indexToAddByte;
            if (BitConverter.IsLittleEndian)
            {
                currentEncodingBuffer[1] = 0;
                indexToAddByte = 0;
            }
            else
            {
                currentEncodingBuffer[0] = 0;
                indexToAddByte = 1;
            }

            int encodingActionIndex = 0;
            byte? lastByte = null;
            for (int i = 0; i < bytesToEncode.Length; i++)
            {
                if (charOutIndex >= charsToCopyOut.Length)
                {
                    throw new Exception("Out char buffer is not big enough for base64 encoded string.");
                }

                charsToCopyOut[charOutIndex++] = GetChar(base64encoder[encodingActionIndex](lastByte, bytesToEncode[i]),
                    currentEncodingBuffer, indexToAddByte);
                if (encodingActionIndex == bytesToEncode.Length - 1)
                {
                    // Last step resets the next lastByte to null
                    lastByte = null;
                }
                else
                {
                    lastByte = bytesToEncode[i];
                }

                encodingActionIndex = (encodingActionIndex + 1) % base64encoder.Length;

                // If the next action is the last one, run it now and reset lastByte
                if (encodingActionIndex == base64encoder.Length - 1)
                {
                    if (charOutIndex >= charsToCopyOut.Length)
                    {
                        throw new Exception("Out char buffer is not big enough for base64 encoded string.");
                    }

                    charsToCopyOut[charOutIndex++] = GetChar(base64encoder[encodingActionIndex](bytesToEncode[i], null),
                        currentEncodingBuffer, indexToAddByte);
                    encodingActionIndex = (encodingActionIndex + 1) % base64encoder.Length;
                    lastByte = null;
                }
                else
                {
                    lastByte = bytesToEncode[i];
                }
            }

            // One more phase to run on the last byte
            if (encodingActionIndex != 0)
            {
                if (charOutIndex >= charsToCopyOut.Length)
                {
                    throw new Exception("Out char buffer is not big enough for base64 encoded string.");
                }

                charsToCopyOut[charOutIndex++] = GetChar(base64encoder[encodingActionIndex](lastByte, 0),
                    currentEncodingBuffer, indexToAddByte);
            }

            int charsLeft = charOutIndex % 4;
            if (charsLeft != 0)
            {
                int padding = 4 - charsLeft;
                while (padding-- > 0)
                {
                    charsToCopyOut[charOutIndex++] = '=';
                }
            }
        }

        public static int PredictSize(int numberOfBytes)
        {
            return (int)(4 * Math.Ceiling((double)numberOfBytes / 3));
        }

        private static char GetChar(byte b, byte[] buffer, int index)
        {
            buffer[index] = b;
            return base64encoding[BitConverter.ToInt16(buffer, 0)];
        }
    }
}

# SIG # Begin signature block
# MIIXwwYJKoZIhvcNAQcCoIIXtDCCF7ACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZKvdLkkcQHVwIz7Pg2YS4EZd
# J9agghL+MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggUtMIIEFaADAgECAhADJszxAnLYapFIca5xiFXdMA0GCSqGSIb3DQEBCwUAMHIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJ
# RCBDb2RlIFNpZ25pbmcgQ0EwHhcNMjAxMTAzMDAwMDAwWhcNMjMxMTA3MjM1OTU5
# WjBqMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxML
# SmVyc2V5IENpdHkxFzAVBgNVBAoTDkF2ZVBvaW50LCBJbmMuMRcwFQYDVQQDEw5B
# dmVQb2ludCwgSW5jLjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANuR
# 6h0xlPIjFCv9W3tWUOmOb0P2bFEntXeDV/zbKV0/IA/U+UFzMeSXD2AX36RJBdL3
# q/R+dBxBa17kXHb1MwqeiYCAq8ySv8slzRbR1kfIiXrUMJSFBm7onZtPpM9Aoi5X
# t5DVliz5L7BrDxI350TdZfyp3XfU6UvurbIctPQSthlA5uC/f0vZnr67d0TwwXIB
# SZYNCd6tjX6xxvvyQ3BVLijbHGLoAp4sVD5lYWHrAzaVyiA/AJOHSYjVxT74Ac7i
# BWAf3I9zvmhlrQbMrMf12qZ/w5b62dCT1A8CFY/oQu2WubcCCwZ8Y/7NxogHUmgB
# sBFf2x6Te+RPHe3lcCECAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl
# 6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTsmMLLOSss08eZmapOw82ZQSwK6jAOBgNV
# HQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOg
# MYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5j
# cmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQt
# Y3MtZzEuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEW
# HGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEF
# BQcBAQR4MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBO
# BggrBgEFBQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# U0hBMkFzc3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJ
# KoZIhvcNAQELBQADggEBAHjPpaZCYFO1ssI4XiJTNwrYOO84SS/W6REs8RIHEwIR
# Pq1jrrn0AcoGBc/+wowgMhWcezzHSJv0CSVJtllzJu1wj8TvaItovvqa0ynak1sr
# d6RUUgTkKwPkgp9OSKUO48LaTLGLOxYYTivp5cRjMY8Y7gsEgQN1GXomZ1/ckxFQ
# B3puNq54Dw2m0XzcRUCH/5O0+nJB1EsFL7rfrbnPTeFQZcp+/ebVWMgWfO9nxXr2
# /7SG+4JeNHZjUyzyCfWFZE2s9oYT/FqE82IGxp7//Xk6Cau7XXbBECQEWuPvUxZO
# QaNgq9Bks8pQgKCP879XE5TISfKR8mZ+TgCHJGl2QxAwggUwMIIEGKADAgECAhAE
# CRgbX9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# JDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEwMjIx
# MjAwMDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMT
# KERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7RZmx
# OttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p0WfT
# xvspJ8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6Ygs
# IJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grkV7tK
# tel05iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0
# xY4PwaLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMBAAGj
# ggHNMIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNV
# HSUEDDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYD
# VR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgGCmCG
# SAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29t
# L0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1Dlgw
# HwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQAD
# ggEBAD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q3yBV
# N7Dh9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEb
# Bw6RFfu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dcIFzZ
# cbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6dGRr
# sutmQ9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT+hKU
# GIUukpHqaGxEMrJmoecYpJpkUe8xggQvMIIEKwIBATCBhjByMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWdu
# aW5nIENBAhADJszxAnLYapFIca5xiFXdMAkGBSsOAwIaBQCgcDAQBgorBgEEAYI3
# AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUmpAX9Lnb+RD0pU0M+Vit
# FsEh/K0wDQYJKoZIhvcNAQEBBQAEggEAYJ6cFZ57Tm7mzWVWOZeYm21B/mtSV3Dp
# b3lmvVrFQ4XJwdSOErHRkA/Q3egyv/ifHL+0z56cyA2Zd/fDnN0FiTB1MMdElcAr
# Bm7ueo61GuHfdxqEGIEh9jdA/bXc01pTxGTBsy+824Gdbv76vK7UkIlMsc5GUg7h
# tWNOYvSP5IXIu5aHU5jGeMkgz7g+Bygv4917gQrKrpiOFm6Ypi8EIK5MDcnBlPRx
# 2YEwXNrnP5KzM2Ao0cjkDysuLrtpPPVaQlianVKDTkUTubXXLC8YpUy7IF0uwWQa
# YnvCPfsmEdL343Tp99F1DC8tmj3JS/SFybWO3a9NK0u+9klGMI4TGqGCAgswggIH
# BgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQK
# ExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBT
# dGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsO
# AwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yMDEyMDkwNjU0MzBaMCMGCSqGSIb3DQEJBDEWBBTxKlo7qwlXjQ70r/ed6kV3
# H4YWVzANBgkqhkiG9w0BAQEFAASCAQCdVUHvYG9odMeCMme7Sy/wMUTAylw941YJ
# Gt2z3SSz3J+5sIEok+2WXY87SIJEFC9LzrqzEKYIxYaAbcOey0kQJ2OlTucxcmuy
# cUdTMXOGx2PdLxTE7W7kQ5z5BhWJhKv+rPUva5PuRN/HRFzzvGNpo8Pj7poTfqv0
# LHeshMDcjMlH++wKCzJXwvCOe1rzlSM5z4PUrXqgtty8YCXkqYCrgvFIMRgZMO9B
# bVGC3qXqVIg2Ehll1SaApXUhIvOX9HoxFfB0muxW/naKZcdz5MbRwiBM7+fGYbWU
# RRE7voafNu+MvguHY0CgNNCAXX11pJLPAvWwcxBGAJtIcc5rjDWC
# SIG # End signature block
