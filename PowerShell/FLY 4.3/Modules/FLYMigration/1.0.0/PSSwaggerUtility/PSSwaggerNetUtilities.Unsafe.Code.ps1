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
# MIIfPgYJKoZIhvcNAQcCoIIfLzCCHysCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZKvdLkkcQHVwIz7Pg2YS4EZd
# J9agghlsMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# ggVZMIIEQaADAgECAhA9eNf5dklgsmF99PAeyoYqMA0GCSqGSIb3DQEBCwUAMIHK
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsT
# FlZlcmlTaWduIFRydXN0IE5ldHdvcmsxOjA4BgNVBAsTMShjKSAyMDA2IFZlcmlT
# aWduLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkxRTBDBgNVBAMTPFZl
# cmlTaWduIENsYXNzIDMgUHVibGljIFByaW1hcnkgQ2VydGlmaWNhdGlvbiBBdXRo
# b3JpdHkgLSBHNTAeFw0xMzEyMTAwMDAwMDBaFw0yMzEyMDkyMzU5NTlaMH8xCzAJ
# BgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0GA1UE
# CxMWU3ltYW50ZWMgVHJ1c3QgTmV0d29yazEwMC4GA1UEAxMnU3ltYW50ZWMgQ2xh
# c3MgMyBTSEEyNTYgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEAl4MeABavLLHSCMTXaJNRYB5x9uJHtNtYTSNiarS/WhtR96MN
# GHdou9g2qy8hUNqe8+dfJ04LwpfICXCTqdpcDU6kDZGgtOwUzpFyVC7Oo9tE6VIb
# P0E8ykrkqsDoOatTzCHQzM9/m+bCzFhqghXuPTbPHMWXBySO8Xu+MS09bty1mUKf
# S2GVXxxw7hd924vlYYl4x2gbrxF4GpiuxFVHU9mzMtahDkZAxZeSitFTp5lbhTVX
# 0+qTYmEgCscwdyQRTWKDtrp7aIIx7mXK3/nVjbI13Iwrb2pyXGCEnPIMlF7AVlIA
# SMzT+KV93i/XE+Q4qITVRrgThsIbnepaON2b2wIDAQABo4IBgzCCAX8wLwYIKwYB
# BQUHAQEEIzAhMB8GCCsGAQUFBzABhhNodHRwOi8vczIuc3ltY2IuY29tMBIGA1Ud
# EwEB/wQIMAYBAf8CAQAwbAYDVR0gBGUwYzBhBgtghkgBhvhFAQcXAzBSMCYGCCsG
# AQUFBwIBFhpodHRwOi8vd3d3LnN5bWF1dGguY29tL2NwczAoBggrBgEFBQcCAjAc
# GhpodHRwOi8vd3d3LnN5bWF1dGguY29tL3JwYTAwBgNVHR8EKTAnMCWgI6Ahhh9o
# dHRwOi8vczEuc3ltY2IuY29tL3BjYTMtZzUuY3JsMB0GA1UdJQQWMBQGCCsGAQUF
# BwMCBggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCAQYwKQYDVR0RBCIwIKQeMBwxGjAY
# BgNVBAMTEVN5bWFudGVjUEtJLTEtNTY3MB0GA1UdDgQWBBSWO1PweTOXr32D7y4r
# zMq3hh5yZjAfBgNVHSMEGDAWgBR/02Wnwt3su/AwCfNDOfoCrzMxMzANBgkqhkiG
# 9w0BAQsFAAOCAQEAE4UaHmmpN/egvaSvfh1hU/6djF4MpnUeeBcj3f3sGgNVOftx
# lcdlWqeOMNJEWmHbcG/aIQXCLnO6SfHRk/5dyc1eA+CJnj90Htf3OIup1s+7NS8z
# WKiSVtHITTuC5nmEFvwosLFH8x2iPu6H2aZ/pFalP62ELinefLyoqqM9BAHqupOi
# DlAiKRdMh+Q6EV/WpCWJmwVrL7TJAUwnewusGQUioGAVP9rJ+01Mj/tyZ3f9J5TH
# ujUOiEn+jf0or0oSvQ2zlwXeRAwV+jYrA9zBUAHxoRFdFOXivSdLVL4rhF4PpsN0
# BQrvl8OJIrEfd/O9zUPU8UypP7WLhK9k8tAUITCCBZowggOCoAMCAQICCmEZk+QA
# AAAAABwwDQYJKoZIhvcNAQEFBQAwfzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEpMCcGA1UEAxMgTWljcm9zb2Z0IENvZGUgVmVyaWZpY2F0aW9u
# IFJvb3QwHhcNMTEwMjIyMTkyNTE3WhcNMjEwMjIyMTkzNTE3WjCByjELMAkGA1UE
# BhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQLExZWZXJpU2ln
# biBUcnVzdCBOZXR3b3JrMTowOAYDVQQLEzEoYykgMjAwNiBWZXJpU2lnbiwgSW5j
# LiAtIEZvciBhdXRob3JpemVkIHVzZSBvbmx5MUUwQwYDVQQDEzxWZXJpU2lnbiBD
# bGFzcyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0aG9yaXR5IC0g
# RzUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCvJAgIKXo1nmAMqudL
# O07cfLw8RRy7K+D+KQL5VwijZIUVJ/XxrcgxiV0i6CqqpkKzj/i5Vbext0uz/o9+
# B1fs70PbZmIVYc9gDaTY3vjgw2IIPVQT60nKWVSFJuUrjxuf6/WhkcIzSdhDY2pS
# S9KP6HBRTdGJaXvHcPaz3BJ023tdS1bTlr8Vd6Gw9KIl8q8ckmcY5fQGBO+QueQA
# 5N06tRn/Arr0PO7gi+s3i+z016zy9vA9r911kTMZHRxAy3QkGSGT2RT+rCpSx4/V
# BEnkjWNHiDxpg8v+R70rfk/Fla4OndTRQ8Bnc+MUCH7lP59zuDMKz10/NIeWiu5T
# 6CUVAgMBAAGjgcswgcgwEQYDVR0gBAowCDAGBgRVHSAAMA8GA1UdEwEB/wQFMAMB
# Af8wCwYDVR0PBAQDAgGGMB0GA1UdDgQWBBR/02Wnwt3su/AwCfNDOfoCrzMxMzAf
# BgNVHSMEGDAWgBRi+wohW39DbhHaCVRQa/XSlnHxnjBVBgNVHR8ETjBMMEqgSKBG
# hkRodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNy
# b3NvZnRDb2RlVmVyaWZSb290LmNybDANBgkqhkiG9w0BAQUFAAOCAgEAgSqCFow0
# ZyvlA+s0e4yio1CK9FWG8R6Mjq597gMZznKVGEitYhH9IP0/RwYBWuLgb4wVLE48
# alBsCzajz3oNnEK8XPgZ1WDjaebiI0FnjGiDdiuPk6MqtX++WfupybImj8qi84Ib
# mD6RlSeXhmHuW10Ha82GqOJlgKjiFeKyviMFaroM80eTTaykjAd5OcBhEjoFDYmj
# 7J9XiYT77Mp8R2YUkdi2Dxld5rhKrLxHyHFDluYyIKXcd4b9POOLcdt7mwP8tx0y
# ZOsWUqBDo/ourVmSTnzH8jNCSDhROnw4xxskIihAHhpGHxfbGPfwJzVsuGPZzblk
# XSulXu/GKbTyx/ghzAS6V/0BtqvGZ/nn05l/9PUi+nL1/f86HEI6ofmAGKXujRzU
# Zp5FAf6q7v/7F48w9/HNKcWd7LXVSQA9hbjLu5M6J2pJwDCuZsn3Iygydvmkg1bI
# SM5alqqgzAzEf7SOl69t41Qnw5+GwNbkcwiXBdvQVGJeA0jC1Z9/p2aM0J2wT9TT
# mF9Lesl/silS0BKAxw9Uth5nzcagbBEDhNNIdecq/rA7bgo6pmt2mQWj8XdoYTMU
# Rwb8U39SvZIUXEokameMr42QqtD2eSEbkyZ8w84evYg4kq5FxhlqSVCzBfiuWTeK
# aiUDlLFZgVDouoOAtyM19Ha5Zx1ZGK0gjZQwggXUMIIEvKADAgECAhA3bEo5LxqW
# 1vtLJfCtzt0GMA0GCSqGSIb3DQEBCwUAMH8xCzAJBgNVBAYTAlVTMR0wGwYDVQQK
# ExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0GA1UECxMWU3ltYW50ZWMgVHJ1c3Qg
# TmV0d29yazEwMC4GA1UEAxMnU3ltYW50ZWMgQ2xhc3MgMyBTSEEyNTYgQ29kZSBT
# aWduaW5nIENBMB4XDTE3MTAwNTAwMDAwMFoXDTIwMTAzMDIzNTk1OVowbDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgMCk5ldyBKZXJzZXkxFDASBgNVBAcMC0plcnNleSBD
# aXR5MREwDwYDVQQKDAhBdmVQb2ludDEMMAoGA1UECwwDUiZEMREwDwYDVQQDDAhB
# dmVQb2ludDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALDVR6zALn+y
# /aQjTGT1uEMQpR8ucaDiCqifToKjyT2O65HWRMTXPb8ytW5Qpoy7UgBxnq+CmfAn
# Oxwqe5FLAT/wiV7OG/tYBdRmS8UmSkLOzoB0jE43X7SeiZizHwv7XZBThDJqjZIg
# RWCb812h91DExu687M7UKnOIs9Wu91yeMBN7lteV5ZpMl+ga4l3Y/V90F8dzhdh2
# tdmpLm+k0g9AdEWZrdBrLKmeKFKsciiSzsyMOg3sJ+YQ8ufsywIXP44B16KOptz4
# mWJvpXb96qYx+gENFX3rzr0f60s9tnxZ1EAFIoEphSgnnLdGEtlR2dA78BBRWtnY
# Kuf4XhF2evaHYhiswtiWZ04ufKby+Ic8XqsfdHmxy6mBYdAL/ak3eZ5lM6LsfCL3
# 0QhyTks5FK/CiJLdtSiYB7Jd1Aitl2cxUImSYDihpvoNXaFNVpr3DhL460qCUmJ5
# LFlKpWWi5rv6KBFhesbYoFH/gC1Yjd2fS93GrOJSpsFTplDNWA60pSgAUfLJTDWB
# B825W0pMnW9XhbKjGXRV4Dbt/5xX5ogIeAdaTyXRGmd+QF6MgbZdQPwrvmD/DjYP
# Hf4FIl7ic52OyN7Go4AwzqBvbJfsUC8TxH+gYGVKFyZxzO3+kliXKNDoX6UGfqrD
# eFjfz1CvJnij8L3A2lfefl2SW/U4K4cBAgMBAAGjggFdMIIBWTAJBgNVHRMEAjAA
# MA4GA1UdDwEB/wQEAwIHgDArBgNVHR8EJDAiMCCgHqAchhpodHRwOi8vc3Yuc3lt
# Y2IuY29tL3N2LmNybDBhBgNVHSAEWjBYMFYGBmeBDAEEATBMMCMGCCsGAQUFBwIB
# FhdodHRwczovL2Quc3ltY2IuY29tL2NwczAlBggrBgEFBQcCAjAZDBdodHRwczov
# L2Quc3ltY2IuY29tL3JwYTATBgNVHSUEDDAKBggrBgEFBQcDAzBXBggrBgEFBQcB
# AQRLMEkwHwYIKwYBBQUHMAGGE2h0dHA6Ly9zdi5zeW1jZC5jb20wJgYIKwYBBQUH
# MAKGGmh0dHA6Ly9zdi5zeW1jYi5jb20vc3YuY3J0MB8GA1UdIwQYMBaAFJY7U/B5
# M5evfYPvLivMyreGHnJmMB0GA1UdDgQWBBTKXz1mZ/pkeJj8KpUzdiwuV/fNMDAN
# BgkqhkiG9w0BAQsFAAOCAQEACuccjZ4WK8gwBinBof2wrpf3YQzYpxhXU+TQendr
# uXt4ywceW9zp/QaFDWKtrtW/n4ZhhYjxgAmdYjXSbNQEdIc55mYVVUjaimPySfuM
# HAJotG4zRkbCwZdfepP525oMxvfUGuQJ82+cEmlRGxRVb8zP0Nym898JFGuwG/mv
# 2ScCPH3tB++LV2l0kVDGo/Mfi2fvUtdLIGq3nsJrlA8Ekk+CR38/wuitWxuyaQ/c
# cMnu6zUzh9W6Ijd2Q+3ZMJHpiaIncPaQllkSHPBmYvfHitoFXhvMj9TXEqboAkf3
# CHpajoWla+0cuhugQmTH9n/Ho3lv2OrwO5EguQJEsN2pcTGCBTwwggU4AgEBMIGT
# MH8xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEf
# MB0GA1UECxMWU3ltYW50ZWMgVHJ1c3QgTmV0d29yazEwMC4GA1UEAxMnU3ltYW50
# ZWMgQ2xhc3MgMyBTSEEyNTYgQ29kZSBTaWduaW5nIENBAhA3bEo5LxqW1vtLJfCt
# zt0GMAkGBSsOAwIaBQCgcDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkq
# hkiG9w0BCQQxFgQUmpAX9Lnb+RD0pU0M+VitFsEh/K0wDQYJKoZIhvcNAQEBBQAE
# ggIAmBWiq1HS3ty4n194vwVlIctzXvWUVd9/0eFgN4S7XtT26xhVekGYgIAzCUiF
# dBBxSJSiXBtDPMUU8pr45xnh7GN6LlmgkdQTYhKmiFWQabLSuDQW2Z7UipgYnB32
# MY2cezmtcPv7b3SzFl8G8ffMmcXTHkxYYfuj2AKjX+EX1ZK2+3P3Mh6VbctWfbNY
# X35luphP7nu9d9hy8DEFMyazw00EguodkvfJGRksFmBSxINsuvkpVXnRxUut7ubS
# E7avZBwOiVEgtgn7sFWuPdH58vM7iWrzshnyF2Qr2uIt0UDWKw5/WJ25eMsc4DIG
# 8wsJhPdU+9ixxEt1HNmYvW89RpB+s0yqKFipejBJWGNYa1BzX2Dno/Gkk6O/Ki36
# G7v7QWJDoFQJlHQhZuZwToGfkqcxmTg2OaEboLCXrslSFrbmf8BgxJuq7GqJmCzD
# 1rhAq/XJOgelJKFAlA60JGYlBKXEW6PXdFiehcOw1YO23/y2fE4gtz8lXfMpjujl
# SWQuzZqyxnzVNdVAFedDTbNWEb2yPYvdbyYsD05tz6Y3fQAZrBJcLNPKvjPH9qPx
# FMaE/O6xLDg+BfEGWLxK7MwuzU3mzCdv8Vil+yw0xNdcrWvnZK5u5KBCYYEFxiX2
# Fmp67eVIotUBDYYsx9Cds+Es24A0AHxnND0ymzS0DImTT4yhggILMIICBwYJKoZI
# hvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3lt
# YW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBp
# bmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUA
# oF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkw
# OTEzMDMwOTUzWjAjBgkqhkiG9w0BCQQxFgQUyIMnqT0Gz3EK4wunJOWDgom/vXMw
# DQYJKoZIhvcNAQEBBQAEggEAXJnyNZK2kqdr97cW3ZZtCzGc/QazS/Ddzu5Mvvoa
# T+F5XfBURAgvJ3A+3jsESoCuFvyUHhdKRGWv/T6q2epXObOIH7sHOoAhUFIk0oz3
# rLmI2FiTIh0JJoJgWL+p2N9WoUE989carL7A+MW23GvlM2fYf9LueTmKKC5Lqd44
# 4wW+t70yN+595B99CgTzVQDVxDnBhRH9vVtIRpmzUayr14i/63aqARwSrusp3kdn
# 8LNR7ZvMvqGt+PbgBUaS70/tNKG6SUk98DBsYy9oXyJxp2yBErSr44ZNIFfkzS/m
# FmS4tdnwa3V3iUTP2lQ3T4mFRtbhh5pMclRD+DA9y+TtrA==
# SIG # End signature block
