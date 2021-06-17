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
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

function Set-connection ([string]$id,[bool]$isOnlie)
{
    if($isOnlie -eq $true)
    {
       $result =  New-ExchangeOnlineConnectionOptionObject -ConnectionId $id
       return  New-ExchangeConnectionObject -OnlineConnectionOption $result
    }else
    {
        $result = New-ExchangeOnPremisesConnectionOptionObject -ConnectionId $id
        return New-ExchangeConnectionObject  -OnPremisesConnectionOption $result
    }
}

function Set-connectionType([string] $type)
{
    if($type -eq "Online"){
        return $true
    }
    return $false
}

$Path = Get-ScriptDirectory

$ApiKey = '<api key>'
$BaseUri = '<base url>'



$CSVFilePath = Join-Path -Path $Path -ChildPath 'PlanCSVs'

$CSVFiles = Get-ChildItem $CSVFilePath
$connctions  = Import-Csv -Path $CSVFilePath"\ImportPlanTemplate.csv"

$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')


# For example: $PlanGoups=@("group1","group2")
$PlanGroups=@()


$Policy = '<Policy id or name>'

$Database='<Database id or name>'


foreach($connection in $connctions)
{
   $sourConnectionType = Set-connectionType -type $connection."Source Type"
   $destConnectionType = Set-connectionType -type $connection."Destination Type"

   $sourceConnection = Set-connection -id $connection."Source Connection" -isOnlie $sourConnectionType
   $destConnection = Set-connection -id $connection."Destination Connection" -isOnlie $destConnectionType
   

   $Csvs = $connection."Mapping Csv" -split ","
   
   foreach($csv in $Csvs)
   {
     $mappings = Import-Csv -Path $CSVFilePath"\$csv" -Encoding UTF8


     $PlanNames =  $csv -split "_"
     $PlanNameLabel = New-PlanNameLabelObject -BusinessUnit $PlanNames[0] -Wave $PlanNames[1] -Name $PlanNames[2].Remove($PlanNames[2].IndexOf("."))

     $mappngList = @()


    foreach($mapping in $mappings)
    {
        $Source = New-ExchangeMailboxObject -Mailbox $mapping."Source Email Address" -MailboxType $mapping."Source Type"

        $Destination = New-ExchangeMailboxObject -Mailbox  $mapping."Destination Email Address" -MailboxType $mapping."Destination Type"

        $MigrateArchive = $false

        $MigrateRecoverable = $false

        if($mapping."Migrate Archived Mailboxes" -eq "true")
        {
            $MigrateArchive = $true

        }
        if($mapping."Migrate Recoverable Item Folder" -eq "true")
        {
            $MigrateRecoverable = $true

        }
        if($mapping."Convert To Shared Mailbox" -eq "true"){
            $MigrateSharedMailbox = $true
        } 
        $MappingContent = New-ExchangeMappingContentObject -Source $Source -Destination $Destination -MigrateArchivedMailboxOrFolder:$MigrateArchive -MigrateRecoverableItemsFolder:$MigrateRecoverable -ConvertToSharedMailbox:$MigrateSharedMailbox

        $mappngList += $MappingContent
    }
    $Mappings = New-ExchangeMappingObject -Source $sourceConnection -Destination $destConnection -Contents @($mappngList)

    # If you want to check the checkbox on the fly setting page of the create plan, please add this parameter here. 
    # For example: the following SynchronizeDeletion parameter indicates that SynchronizeDeletion is checked. If you do not want to check, please do not fill in the corresponding parameters.
    # If you do not want to set the Schedule, please remove the '-Schedule $Schedule ' parameter below.

    $PlanSettings = New-ExchangePlanSettingsObject -NameLabel $PlanNameLabel -PolicyId $Policy -DatabaseId $Database  -PlanGroups $PlanGroups -Schedule $Schedule -MigrateMailboxRules -MigrateMailboxPermissions -SynchronizeDeletion -MigrateAutoCompleteList -MigrateContacts

    $Plan = New-ExchangePlanObject -Settings $PlanSettings -Mappings $Mappings

      try
    {
    
        $Response = Add-ExchangePlan -Plan $Plan -BaseUri $BaseUri -APIKey $ApiKey

        $Response.Content
    }
    Catch
    {
        $ErrorMessage = $Error[0].Exception
        Write-Host -ForegroundColor Red $ErrorMessage.Message
        Write-Host -ForegroundColor Red $ErrorMessage.Response.Content
    }

    }
  }


# SIG # Begin signature block
# MIIXwwYJKoZIhvcNAQcCoIIXtDCCF7ACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGoSazTntLcg0W1LXbvOio1Jv
# neSgghL+MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQULAn9YzN2aE4kfpF+xKbl
# ola/zB4wDQYJKoZIhvcNAQEBBQAEggEALfC0Sg40Twc4xs+pZSHpMjnD6jccscHU
# tTg6fFGa1aV4ZL1Oaa3pHpE9AUtpOhafwDln53ilVbAbHXkHmmuc57OYntuolcpT
# SViKi1sgdjZ3eIssfPeCLuPFxH65/TmBWSzJQWREuAB2+RgxpeZNAoQtG9h6byR3
# W7KuBoBL1lgF81l6BCpvm44+jKEVfHJCVAupLZVS42KfuSv13qIs4N7Ew9BIwv8w
# tnpx+hD1WpqnGH5SnKNRmSDmClptj4OKvQ+v3vxkyAMFsbzPzTuuvb4ISTgaNk7c
# G6lS+dtfVkBOhpdsbQM731rGKwhLDoSxnunZWGGcL/hYWw4fNv0yPaGCAgswggIH
# BgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQK
# ExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBT
# dGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsO
# AwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yMDEyMDkwNjU0MzVaMCMGCSqGSIb3DQEJBDEWBBTl8GILs6pNI/B+r6n9Bv/h
# CVt4SjANBgkqhkiG9w0BAQEFAASCAQA5j5BiEZcd3VQFD9qXyvg/Ao7V57J3cbPw
# xTMouLDvLa++6ivGUNns6+NH/FtOvw6P09dROp9lZolaS9nAMlEk1hCu9CbCoBvJ
# DtmNepk8gE8GnAP8leq1b7d47O6GFvVJxLPk1/Diox+rTHolp2xc+64bj4o/NNTc
# Z81qtcMmiHLVtHG/bHFpyMcXBTKEngnmBiNLB09BfbCLR3pX3TA8hzsDhUtcEpcA
# aGu9psfmpgr4SXSawYgPne7RxshAFDZocTaZfPuSnJCYRap6kfKwq2KI59unkdhW
# d1TTyYKSE2BS21cfIaY6i0gTchmOb2x1Ph8fRRwDiXkAvKbLW949
# SIG # End signature block
