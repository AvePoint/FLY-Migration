<# /********************************************************************
 *
 *  PROPRIETARY and CONFIDENTIAL
 *
 *  This file is licensed from, and is a trade secret of:
 *
 *                   AvePoint, Inc.
 *                   Harborside Financial Center
 *                   9th Fl.   Plaza Ten
 *                   Jersey City, NJ 07311
 *                   United States of America
 *                   Telephone: +1-800-661-6588
 *                   WWW: www.avepoint.com
 *
 *  Refer to your License Agreement for restrictions on use,
 *  duplication, or disclosure.
 *
 *  RESTRICTED RIGHTS LEGEND
 *
 *  Use, duplication, or disclosure by the Government is
 *  subject to restrictions as set forth in subdivision
 *  (c)(1)(ii) of the Rights in Technical Data and Computer
 *  Software clause at DFARS 252.227-7013 (Oct. 1988) and
 *  FAR 52.227-19 (C) (June 1987).
 *
 *  Copyright © 2017-2020 AvePoint® Inc. All Rights Reserved.
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>
$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PolicyId = '<policy id>'
$DatabseId = '<migration database id>'

$BasicCredential = New-BasicCredentialObject -Username '<Username>' -Password '<password>'

$DestinationConnOption = New-ExchangeOnlineConnectionOptionObject -BasicCredential $BasicCredential

$DestinationConnection = New-ExchangeConnectionObject -OnlineConnectionOption $DestinationConnOption

# exchange online connection example:

# $DestinationConnOption  = New-ExchangeOnlineConnectionOptionObject -ConnectionId "<exchange connection id or name>"

# $DestinationConnection = New-ExchangeConnectionObject -OnlineConnectionOption $DestinationConnOption

# exchange on-premises service account exmaple:

# $ServerOption = New-ExchangeServerOptionObject -Host '<exchange server host>' -Version Exchange2010

# $BasicCredential = New-BasicCredentialObject -Username '<Username>' -Password '<Password>'

# $DestinationConnOption = New-ExchangeOnPremisesConnectionOptionObject -BasicCredential $BasicCredential -ExchangeServerOption $ServerOption

# $DestinationConnection = New-ExchangeConnectionObject -OnPremisesConnectionOption BasicCredential

# exchange on-premises connection examole:

# $DestinationConnOption = New-ExchangeOnPremisesConnectionOptionObject -ConnectionId '<exchange migration connection id>'

# $DestinationConnection = New-ExchangeConnectionObject -OnPremisesConnectionOption $DestinationConnOption

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit>' -Wave '<wave>' -Name '<name>'

$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([System.DateTime]::Now).AddMinutes(2).ToString("o")

$PlanSettings = New-IMAPPOP3PlanSettingsObject -NameLabel $PlanNameLabel -Schedule $Schedule -PolicyId $PolicyId -DatabaseId $DatabseId -SynchronizeDeletion

$SourceConnection = New-IMAPPOP3ConnectionObject -Type Outlook -ServerName 'imap-mail.outlook.com' -Port 993 -EnableSSL

$Source1 = New-IMAPPOP3MailBoxObject -Mailbox '<outlook mailbox>' -Password '<password>'
$Source2 = New-IMAPPOP3MailBoxObject -Mailbox '<outlook mailbox>' -Password '<password>'

$Dest1 = New-ImapMigrationExchangeMailboxObject -Mailbox '<mailbox address>' -MailboxType UserMailbox
$Dest2 = New-ImapMigrationExchangeMailboxObject -Mailbox '<mailbox address>' -MailboxType ArchivedMailbox

$MappingContent1 = New-IMAPPOP3MappingContentObject -Source $Source1 -DestinationMailbox $Dest1 -MigrateArchivedMailboxOrFolder
$MappingContent2 = New-IMAPPOP3MappingContentObject -Source $Source2 -DestinationMailbox $Dest2 -MigrateArchivedMailboxOrFolder

$Mappings = New-IMAPPOP3MappingObject -Source $SourceConnection -Destination $DestinationConnection -Contents @($MappingContent1, $MappingContent2)

$Plan = New-IMAPPOP3PlanObject -Settings $PlanSettings -Mappings $Mappings



try
{
    $Response = Add-IMAPPOP3Plan -APIKey $ApiKey -BaseUri $BaseUri -Plan $Plan

	$Response.Content
}
Catch
{
   $ErrorMessage = $Error[0].Exception
   Write-Host -ForegroundColor Red $ErrorMessage.Message
   Write-Host -ForegroundColor Red $ErrorMessage.Response.Content
}
# SIG # Begin signature block
# MIIXwwYJKoZIhvcNAQcCoIIXtDCCF7ACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5hv2JkH64DqJOL+iW7lTW0xk
# BT+gghL+MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUdPSHGcMcpsXjwCyS6/tW
# ZwLEZ8MwDQYJKoZIhvcNAQEBBQAEggEALL6gZhNCHgnAamLAA/zXtu+180b9f33n
# cRY5cJCqlZ4HE3RNdK3A1u1g2p59eRXCsnBi7cOwopPdU6NwIDL5BsEdfi1dNe8y
# Ln37F4jYgghebzAwudnUkikZyFNHDcUXRZBMAikDdvokFXZrXVYJlsuNdTxutPhN
# Pys/bOS3lectiyPcb5+AnpyvavQkyiUbnvHWGDSBjbs/29X6m2OubvlEVcCzTuOh
# AsOOugoNdatB/wr1FLXtIv/6ywL6NnfXccBXCYLW6RIGcPP8rgC5M1cBTm64biYZ
# Yhv3xmNvwHa8DR6Cb+UPjCdoKuSHbkf18nni9yLdFmLk2pRLIx959KGCAgswggIH
# BgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQK
# ExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBT
# dGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsO
# AwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yMDEyMDkwNjU0NDRaMCMGCSqGSIb3DQEJBDEWBBR35WZY+IQaPspFb4giM9Hs
# nboTQDANBgkqhkiG9w0BAQEFAASCAQBiSyjsR9qhsFR+hxwADQSxGH72kA41T7t/
# 4Tgf+omTUQlqQR2pCRNbSeIeTYOmCQL9TKYmNNVnRkvTCJzty/CCW41QEUGvA/kj
# g83jnuBR1inPDDGj0eVP4MGQmqnEdvJiYp1APpZVOa9JBbXcXETFdY3aQnxvfyHc
# sQJ0twAyIMmuMYoWDiRRAoi7/ormZ9LjXCuUwzwAEAuedPwnVnrfITcp2Ti4nNU0
# 6Z1TmJc3ZnWcOSDXUQTnqHIYLWn1KCsMMLEzY/AIXivpVhf4C9vxD60LKLwvXrNo
# /hj1p08Tkvhy7rDulgOZVUWr10Kz34FJYV/00Qm0xseQP7Al/upS
# SIG # End signature block
