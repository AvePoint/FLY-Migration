//********************************************************************
//*
//*  PROPRIETARY and CONFIDENTIAL
//*
//*  This file is licensed from, and is a trade secret of:
//*
//*                   AvePoint, Inc.
//*                   525 Washington Blvd, Suite 1400
//*                   Jersey City, NJ 07310
//*                   United States of America
//*                   Telephone: +1-201-793-1111
//*                   WWW: www.avepoint.com
//*
//*  Refer to your License Agreement for restrictions on use,
//*  duplication, or disclosure.
//*
//*  RESTRICTED RIGHTS LEGEND
//*
//*  Use, duplication, or disclosure by the Government is
//*  subject to restrictions as set forth in subdivision
//*  (c)(1)(ii) of the Rights in Technical Data and Computer
//*  Software clause at DFARS 252.227-7013 (Oct. 1988) and
//*  FAR 52.227-19 (C) (June 1987).
//*
//*  Copyright © 2017-2024 AvePoint® Inc. All Rights Reserved.
//*
//*  Unpublished - All rights reserved under the copyright laws of the United States.
//*
//********************************************************************

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
# MIIoGAYJKoZIhvcNAQcCoIIoCTCCKAUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDWxww4eZpfAHba
# 78vY4JvkoinphD5UEAj6R5Dtui58WaCCDZowggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggbiMIIEyqADAgECAhAPc9sqd/BkUUsWn0FQMB0UMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjMxMTAzMDAwMDAwWhcNMjYxMTE0
# MjM1OTU5WjBqMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIG
# A1UEBxMLSmVyc2V5IENpdHkxFzAVBgNVBAoTDkF2ZVBvaW50LCBJbmMuMRcwFQYD
# VQQDEw5BdmVQb2ludCwgSW5jLjCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoC
# ggGBAOEW7Ii2pvR9/732eojqygVHkWY2HMdaefS7g4Z4EOt6ABrXYcTFvIMax1DN
# 7ZCbfarSe6B0jsXnrNbhTZKJiphzbLAIs4NOi4EMxdWzDbc8oZqByMX77NxSiaR3
# PhqFGI99Utr9NUIBsruS6AccQ6CkP2nNejixv6BrsGJbUDrgz6A66x7V4WhYa6df
# qmMU8EucSyjcZB2A4h21H+jURe95N1SZThOw6vfFKn5JPnKvGTCuH0u19xi8d90j
# ZItOntrR92wzFG2jSd4Z3DeKyvIDWxGGqaDqloA7thXNGN/URNqTZfeXdsF6uUU2
# IojpWh8gYBTnu9i8cM9PVDOB420h5JaV+1XLO8m10LtnYBSWZWgUHpcTq7Suwbah
# 0/yiur0ltzR13dQ0wk2Xe1i/G8PlKw4IlyqESqizT3YxUGlqwcojIAYwaGBtATTf
# kCKq32rornXSmCqfrQICoA8dR7pry8hl/JloSD/+riT62F8r8mQTlLUw5xNiqBqE
# kIQvuQIDAQABo4ICAzCCAf8wHwYDVR0jBBgwFoAUaDfg67Y7+F8Rhvv+YXsIiGX0
# TkIwHQYDVR0OBBYEFJxiV1oIFotUW4UTNkwFNyJScORPMD4GA1UdIAQ3MDUwMwYG
# Z4EMAQQBMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQ
# UzAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwgbUGA1UdHwSB
# rTCBqjBToFGgT4ZNaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcmwwU6BRoE+G
# TWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVT
# aWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMIGUBggrBgEFBQcBAQSBhzCB
# hDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFwGCCsGAQUF
# BzAChlBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVk
# RzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNydDAJBgNVHRMEAjAA
# MA0GCSqGSIb3DQEBCwUAA4ICAQDE9SZRwvtvpHrw4OjJ1AKL0aabKlOUkxidOjEC
# wrWr4yFKJdHWHpouUFTye7M8gQS4FQDQqD4ys7a1joCQVd+WEiQIyy0TzJXxT7US
# tkhg8lD41cT7i857dgnSrX7Prp0Es/xFBhEKR0fMs3Sj20+qcnJNTB4TA9CPnUd4
# UL1Ve/bqsr5lVZgoPp6wbs0lXjsTEfzrio++T4ssc42eTxfv6YZgTmdrPEQNqLUa
# hQuQ0x5j8lVBBtt5PrC7TikkVB/GBZ+01EJrUQvcX3arZky1tviINBQ3EXRhyGkx
# zSz6Vk9NxwJVkdavIUkdDuUuqNVqp2a3Zsv2L3mwlr0UnKMgpBiPnxgC9u6e5tjR
# +plDe3fmD20XQTt/p61FueC7w92HC6YizDrynRX58h6KuRv2j/u2yZU3nipaiGlz
# 8jURf2ySxZXI2QG228Nfsg4y1Z61tPfYb4kcqTfVcaxh7azpP6BU33dkIyC7dmv4
# q3PueRcSyweKjqlQqeswnTeBS3+met1BbjkMdJJzqbIu5WONTBIHHH1RGsQYPn8i
# ms3pE0GhGl9c1r1BpufehQwSjCZRc/vHrHUOQyNimVKoOtls5UAxU5FXO3PKaHPO
# M6dFS1b+EF6drXV0M9/KdJVyyP4EK6CJQVt7RrQBRSSdQCKCYJ63VUF5amRuzY0s
# EqLoRTGCGdQwghnQAgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2ln
# bmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQD3PbKnfwZFFLFp9BUDAdFDAN
# BglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCBpBkvuvF1qgJFAouI+023gu6tKxVhjQtdBry+sq3KhfjANBgkq
# hkiG9w0BAQEFAASCAYADK3iySp4NiJD2cqgeZPMCDYayzFEu+L7ofj3r9Acee2s3
# Ju1qBervPHcUysBhm5rpKhR0BDpHXiNgoRRbWcyBVMMZt4KIGk/VtXr9+boxQRn3
# wsm0uCwnIGZfotZxM6W/1jBujm+fJWj47sK7uDs772RKhlVAsg5OdHRMFf+nPENI
# NEdK/iN0a5GTsLOu8C1QjOFRBWWGNtogCgSXObZ3L6rroeJLs52s7G2emzcOOvjG
# IW8d8Mi6OyqAMiKiasDHwT4I33rN67OyoNsGjUkqmquwFCQ5M7mNqEovSK/G5JB7
# LQBWcKAd2XxapG0IsRFw8yMb7c92orTcUVVAiha1BnS/HxU8Gu2/LWho5HXYsNLD
# WKpbw221VCGE3l5S7RxdAI+iO2aOtABgikKnGtjDgKQb48uEc6Hm5qn6y+lHpisf
# O1DY7Rp5SlWZCifC4uhX5odovFzmriFk3xQsW7Bg+y5O/2/AYR368WzYrT+LCr+C
# TfwzvIAKeC9OTGDcxbuhghcqMIIXJgYKKwYBBAGCNwMDATGCFxYwghcSBgkqhkiG
# 9w0BBwKgghcDMIIW/wIBAzEPMA0GCWCGSAFlAwQCAQUAMGgGCyqGSIb3DQEJEAEE
# oFkEVzBVAgEBBglghkgBhv1sBwEwITAJBgUrDgMCGgUABBTRx55mC2PiHWDXfnLK
# EXl/rQiqSQIRAKYAcObS+ROG4Wq2sHdf+tIYDzIwMjQxMjA0MDQzNzUwWqCCEwMw
# gga8MIIEpKADAgECAhALrma8Wrp/lYfG+ekE4zMEMA0GCSqGSIb3DQEBCwUAMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0EwHhcNMjQwOTI2MDAwMDAwWhcNMzUxMTI1MjM1OTU5WjBCMQswCQYDVQQGEwJV
# UzERMA8GA1UEChMIRGlnaUNlcnQxIDAeBgNVBAMTF0RpZ2lDZXJ0IFRpbWVzdGFt
# cCAyMDI0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvmpzn/aVIauW
# MLpbbeZZo7Xo/ZEfGMSIO2qZ46XB/QowIEMSvgjEdEZ3v4vrrTHleW1JWGErrjOL
# 0J4L0HqVR1czSzvUQ5xF7z4IQmn7dHY7yijvoQ7ujm0u6yXF2v1CrzZopykD07/9
# fpAT4BxpT9vJoJqAsP8YuhRvflJ9YeHjes4fduksTHulntq9WelRWY++TFPxzZrb
# ILRYynyEy7rS1lHQKFpXvo2GePfsMRhNf1F41nyEg5h7iOXv+vjX0K8RhUisfqw3
# TTLHj1uhS66YX2LZPxS4oaf33rp9HlfqSBePejlYeEdU740GKQM7SaVSH3TbBL8R
# 6HwX9QVpGnXPlKdE4fBIn5BBFnV+KwPxRNUNK6lYk2y1WSKour4hJN0SMkoaNV8h
# yyADiX1xuTxKaXN12HgR+8WulU2d6zhzXomJ2PleI9V2yfmfXSPGYanGgxzqI+Sh
# oOGLomMd3mJt92nm7Mheng/TBeSA2z4I78JpwGpTRHiT7yHqBiV2ngUIyCtd0pZ8
# zg3S7bk4QC4RrcnKJ3FbjyPAGogmoiZ33c1HG93Vp6lJ415ERcC7bFQMRbxqrMVA
# Niav1k425zYyFMyLNyE1QulQSgDpW9rtvVcIH7WvG9sqYup9j8z9J1XqbBZPJ5XL
# ln8mS8wWmdDLnBHXgYly/p1DhoQo5fkCAwEAAaOCAYswggGHMA4GA1UdDwEB/wQE
# AwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMCAGA1Ud
# IAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAWgBS6FtltTYUv
# cyl2mi91jGogj57IbzAdBgNVHQ4EFgQUn1csA3cOKBWQZqVjXu5Pkh92oFswWgYD
# VR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNybDCBkAYIKwYB
# BQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNv
# bTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNydDANBgkq
# hkiG9w0BAQsFAAOCAgEAPa0eH3aZW+M4hBJH2UOR9hHbm04IHdEoT8/T3HuBSyZe
# q3jSi5GXeWP7xCKhVireKCnCs+8GZl2uVYFvQe+pPTScVJeCZSsMo1JCoZN2mMew
# /L4tpqVNbSpWO9QGFwfMEy60HofN6V51sMLMXNTLfhVqs+e8haupWiArSozyAmGH
# /6oMQAh078qRh6wvJNU6gnh5OruCP1QUAvVSu4kqVOcJVozZR5RRb/zPd++PGE3q
# F1P3xWvYViUJLsxtvge/mzA75oBfFZSbdakHJe2BVDGIGVNVjOp8sNt70+kEoMF+
# T6tptMUNlehSR7vM+C13v9+9ZOUKzfRUAYSyyEmYtsnpltD/GWX8eM70ls1V6QG/
# ZOB6b6Yum1HvIiulqJ1Elesj5TMHq8CWT/xrW7twipXTJ5/i5pkU5E16RSBAdOp1
# 2aw8IQhhA/vEbFkEiF2abhuFixUDobZaA0VhqAsMHOmaT3XThZDNi5U2zHKhUs5u
# HHdG6BoQau75KiNbh0c+hatSF+02kULkftARjsyEpHKsF7u5zKRbt5oK5YGwFvgc
# 4pEVUNytmB3BpIiowOIIuDgP5M9WArHYSAR16gc0dP2XdkMEP5eBsX7bf/MGN4K3
# HP50v/01ZHo/Z5lGLvNwQ7XHBx1yomzLP8lx4Q1zZKDyHcp4VQJLu2kWTsKsOqQw
# ggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbS
# g9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9
# /UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXn
# HwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0
# VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4f
# sbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40Nj
# gHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0
# QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvv
# mz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T
# /jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk
# 42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5r
# mQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcG
# CCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNV
# HSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIB
# AH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxp
# wc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIl
# zpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQ
# cAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfe
# Kuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+j
# Sbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJsh
# IUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6
# OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDw
# N7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR
# 81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2
# VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIFjTCCBHWgAwIBAgIQ
# DpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAx
# MDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQD
# ExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4IC
# DwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aa
# za57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllV
# cq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT
# +CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd
# 463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+
# EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92k
# J7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5j
# rubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7
# f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJU
# KSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+wh
# X8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQAB
# o4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0P
# AQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDww
# OqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IB
# AQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229
# GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FD
# RJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVG
# amlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCw
# rFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvR
# XKwYw02fc7cBqZ9Xql4o4rmUMYIDdjCCA3ICAQEwdzBjMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0
# ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhALrma8Wrp/lYfG
# +ekE4zMEMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAcBgkqhkiG9w0BCQUxDxcNMjQxMjA0MDQzNzUwWjArBgsqhkiG9w0BCRAC
# DDEcMBowGDAWBBTb04XuYtvSPnvk9nFIUIck1YZbRTAvBgkqhkiG9w0BCQQxIgQg
# c8flNVAfW66NXJd8lJ9zgaQodiTQZdLeDODhSUyn8/4wNwYLKoZIhvcNAQkQAi8x
# KDAmMCQwIgQgdnafqPJjLx9DCzojMK7WVnX+13PbBdZluQWTmEOPmtswDQYJKoZI
# hvcNAQEBBQAEggIApkO9dpgCaKrS6pggyd6Lzvz6xRKmun/q94KEltMf8+2uhqVs
# J6+uwvNaVyYWJj5vofMOGV/t6uhHMCG2LKhv6QoZphQPuY+18n5G5ZAQ0nopDUWx
# Tw83/uiCO62ewUPsfKbMSILtgEv6ReSXkhArYt/kfggSBVVZaYFkuSzmK4Pex1/k
# sxJBF01KY1Nf3bw2ipgp687ONkKuKAjNgSeGuo9HXY5hAMsSAQ1ID8qs0BL8ahu1
# qaA9mRemEd7+F6XdTflW5triJytnLqOPLm0bt5WTePpjFFKjxOC1p6TbHHN7NkWW
# JMopUh5Bv47ynKuyXo2WS9o6ohiGiDta6a7oiVq6QK1RlGRsJvw4wmDMtD8j8BL9
# ua7+hreaxoN1jp4UwWMv3dsNUGY0zG+P2ZTehrnkYkh0lf0h/7Z4wpGkGCNVzsdD
# 455OKgRnoZZkcMtyLQftekqdlV6SX6o3VnbfyzaFIjxfyvRZun8DAIy1ULY6aCKv
# D8tpAjNFVJ8CHpZ3jnf8fRVRM7AEiV63RDjy3WSvIAojXfvwhnZbmAJn8rlf+fkA
# /luEKR3EqW8Y+sOyYFA2CtM+I+LVseRJg36tEjZtBf9BH6FWV+rTLKjC1IFu9avF
# PpDXQqzy2R4QrLJoqBeM1Ct30j2W8V+oUsMyM9gvvDBTVOSLZvoMu6TCP74=
# SIG # End signature block
