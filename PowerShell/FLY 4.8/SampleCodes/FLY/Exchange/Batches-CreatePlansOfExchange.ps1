﻿<# /********************************************************************
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
 *  Copyright © 2017-2021 AvePoint® Inc. All Rights Reserved.
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
$BaseUri = '<base uri>'

# For example: 
# Once : $Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')
# Daily : $Schedule = New-SimpleScheduleObject -IntervalType Daily -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o') -LastIncrementalMigrationStartTime ([Datetime]::Now).AddDays(1).ToString('o')
# For more information about the schedule setting format, please see the  New-ScheduleObject.ps1 file in '...\SampleCodes\FLY\Common\' directory 
$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')


# For example: $PlanGroups=@('group id1 or name1','group id2 or name2')
$PlanGroups=@()

# The Policy cannot be empty, this is a required field.
# For example: $Policy = 'policy id or name'
$Policy = ''

# Verify the mailboxes exist and are available for migration.
# For example: $VerifyMapping = $true/$false
$VerifyMapping = $false;

# For example:$Database = 'database id' or $Database = 'database id or Database Name(Database Server)'
$Database=''

try{

    $CSVFilePath = Join-Path -Path $Path -ChildPath 'PlanCSVs'
	$NewFilePath = $CSVFilePath+"\"+"ImportPlanTemplate-result.csv"
	$ImportCsv = Import-Csv -Path $CSVFilePath"\ImportPlanTemplate.csv"
	$ImportCsv | Select-Object *,"Status","Comment" | Export-Csv -Path $NewFilePath -NoTypeInformation
	$connections  = Import-Csv -Path $NewFilePath
	$mappings = Import-Csv -Path $NewFilePath -Encoding UTF8
	
	foreach($connection in $connections)
	{
		try{
		   $sourConnectionType = Set-connectionType -type $connection."Source Type"
		   $destConnectionType = Set-connectionType -type $connection."Destination Type"

		   $sourceConnection = Set-connection -id $connection."Source Connection" -isOnlie $sourConnectionType 
		   $destConnection = Set-connection -id $connection."Destination Connection" -isOnlie $destConnectionType

		   $Csvs = $connection."Mapping Csv"
		   
		   foreach($csv in $Csvs)
		   {
			 $mappings = Import-Csv -Path $CSVFilePath"\$csv" -Encoding UTF8

			 $PlanNameLabel =  $csv.Remove($csv.IndexOf("."))

			 $mappingList = @()


			foreach($mapping in $mappings)
			{
				$Source = New-ExchangeMailboxObject -Mailbox $mapping."Source Email Address" -MailboxType $mapping."Source Type"

				$Destination = New-ExchangeMailboxObject -Mailbox  $mapping."Destination Email Address" -MailboxType $mapping."Destination Type"

				$MigrateArchive = $false

				$MigrateDeletonsFolder = $false
				$MigrateSharedMailbox = $false
				if($mapping."Migrate Archive Mailbox".ToLower() -eq "true")
				{
					$MigrateArchive = $true

				}
				if($mapping."Migrate Deletions Folder".ToLower() -eq "true")
				{
					$MigrateDeletonsFolder = $true

				}
				if($mapping."Convert To Shared Mailbox".ToLower() -eq "true"){
					$MigrateSharedMailbox = $true
				} 
				$MappingContent = New-ExchangeMappingContentObject -Source $Source -Destination $Destination -MigrateArchiveMailbox:$MigrateArchive -MigrateDeletonsFolder:$MigrateDeletonsFolder -ConvertToSharedMailbox:$MigrateSharedMailbox

				$mappingList += $MappingContent
			}
			$Mappings = New-ExchangeMappingObject -Source $sourceConnection -Destination $destConnection -Contents @($mappingList) -VerifyMapping:$VerifyMapping

			# If you want to check the checkbox on the fly setting page of the create plan, please add this parameter here. 
			# For example: the following SynchronizeDeletion parameter indicates that SynchronizeDeletion is checked. If you do not want to check, please do not fill in the corresponding parameters.
			# If you do not want to set the Schedule, please remove the '-Schedule $Schedule ' parameter below.

			$PlanSettings = New-ExchangePlanSettingsObject -DisplayName  $PlanNameLabel -PolicyId $Policy -DatabaseId $Database  -PlanGroups $PlanGroups -Schedule $Schedule -MigrateMailboxRules -MigrateMailboxPermissions -SynchronizeDeletion -MigrateAutoCompleteList -MigrateContacts

			$Plan = New-ExchangePlanObject -Settings $PlanSettings -Mappings $Mappings
			$Response = Add-ExchangePlan -Plan $Plan -BaseUri $BaseUri -APIKey $ApiKey
			$Response.Content
            $Response.Errors.Description -creplace (';', "`n")
			$connection.Status = "Succeed";
		}
        }
		Catch
		{
			$ErrorMessage = $Error[0].Exception
			Write-Host -ForegroundColor Red $ErrorMessage.Message
			Write-Host -ForegroundColor Red $ErrorMessage.Response.Content
			$connection.Status = "Failed";
			$connection.Comment = $ErrorMessage.Message + $ErrorMessage.Response.Content
		}
	  }

  $connections|Export-Csv -Path $NewFilePath -NoTypeInformation
  
}
Catch
{
	$ErrorMessage = $Error[0].Exception
	Write-Host -ForegroundColor Red $ErrorMessage.Message
	Write-Host -ForegroundColor Red $ErrorMessage.Response.Content
}
# SIG # Begin signature block
# MIIevgYJKoZIhvcNAQcCoIIerzCCHqsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUA714anGU9i5t7GqX8SRLYU3p
# sRCgghnUMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIxMDEwMTAwMDAwMFoXDTMxMDEw
# NjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQikRcpja1HXOhFCvQp1dU2UtAxQ
# tSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cLnGP9NmqB+in43Stwhd4CGPN4
# bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHTWjaPxqPhLxs6t2HWc+xObTOK
# fF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WHIOsOjizVI9r0TXhG4wODMSlK
# XAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6BqrW7EdMMKbaYK02/xWVLwfoYer
# vnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+DUmEvQECAwEAAaOCAbgwggG0
# MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcBMCkwJwYIKwYBBQUHAgEWG2h0
# dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNVHSMEGDAWgBT0tuEgHf4prtLk
# YaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+vCgtHUQ23eNqerwwcQYDVR0f
# BGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJl
# ZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRFRpbWVzdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctemaI7znGucgDo5nRv1CclF0CiNH
# o6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+RAJmTe1ppA/2uHDPYuj1UUp4
# eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+t2R3Y18jUmmDgvoaU+2QzI2h
# F3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8gQ74wOFcz8QRcucbZEnYIpp1
# FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1HavWPWH1ub9y4bTxMd90oNcX6X
# t/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHLKNpbh6aKLzCCBS0wggQV
# oAMCAQICEAMmzPECcthqkUhxrnGIVd0wDQYJKoZIhvcNAQELBQAwcjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUg
# U2lnbmluZyBDQTAeFw0yMDExMDMwMDAwMDBaFw0yMzExMDcyMzU5NTlaMGoxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkg
# Q2l0eTEXMBUGA1UEChMOQXZlUG9pbnQsIEluYy4xFzAVBgNVBAMTDkF2ZVBvaW50
# LCBJbmMuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA25HqHTGU8iMU
# K/1be1ZQ6Y5vQ/ZsUSe1d4NX/NspXT8gD9T5QXMx5JcPYBffpEkF0ver9H50HEFr
# XuRcdvUzCp6JgICrzJK/yyXNFtHWR8iJetQwlIUGbuidm0+kz0CiLle3kNWWLPkv
# sGsPEjfnRN1l/Kndd9TpS+6tshy09BK2GUDm4L9/S9mevrt3RPDBcgFJlg0J3q2N
# frHG+/JDcFUuKNscYugCnixUPmVhYesDNpXKID8Ak4dJiNXFPvgBzuIFYB/cj3O+
# aGWtBsysx/Xapn/DlvrZ0JPUDwIVj+hC7Za5twILBnxj/s3GiAdSaAGwEV/bHpN7
# 5E8d7eVwIQIDAQABo4IBxTCCAcEwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt
# 9mV1DlgwHQYDVR0OBBYEFOyYwss5KyzTx5mZqk7DzZlBLArqMA4GA1UdDwEB/wQE
# AwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOg
# MYYvaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5j
# cmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6
# Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwBBAEwgYQGCCsGAQUFBwEBBHgw
# djAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsGAQUF
# BzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNz
# dXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0B
# AQsFAAOCAQEAeM+lpkJgU7WywjheIlM3Ctg47zhJL9bpESzxEgcTAhE+rWOuufQB
# ygYFz/7CjCAyFZx7PMdIm/QJJUm2WXMm7XCPxO9oi2i++prTKdqTWyt3pFRSBOQr
# A+SCn05IpQ7jwtpMsYs7FhhOK+nlxGMxjxjuCwSBA3UZeiZnX9yTEVAHem42rngP
# DabRfNxFQIf/k7T6ckHUSwUvut+tuc9N4VBlyn795tVYyBZ872fFevb/tIb7gl40
# dmNTLPIJ9YVkTaz2hhP8WoTzYgbGnv/9eToJq7tddsEQJARa4+9TFk5Bo2Cr0GSz
# ylCAoI/zv1cTlMhJ8pHyZn5OAIckaXZDEDCCBTAwggQYoAMCAQICEAQJGBtf1btm
# dVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UE
# AxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAwMFoX
# DTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNl
# cnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1f+Wo
# ndsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+yknx9N7
# I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4cSocI
# 3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTmK/5s
# y350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/Bougs
# UfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0wggHJ
# MBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4
# MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVk
# SURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGln
# aUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9bAAC
# BDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAoG
# CGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNVHSME
# GDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEAPuwN
# WiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH20ZJ1
# D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV+7qv
# tVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyPu6j4
# xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD2rOw
# jNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6Skepo
# bEQysmah5xikmmRR7zCCBTEwggQZoAMCAQICEAqhJdbWMht+QeQF2jaXwhUwDQYJ
# KoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQg
# QXNzdXJlZCBJRCBSb290IENBMB4XDTE2MDEwNzEyMDAwMFoXDTMxMDEwNzEyMDAw
# MFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1
# cmVkIElEIFRpbWVzdGFtcGluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAL3QMu5LzY9/3am6gpnFOVQoV7YjSsQOB0UzURB90Pl9TWh+57ag9I2z
# iOSXv2MhkJi/E7xX08PhfgjWahQAOPcuHjvuzKb2Mln+X2U/4Jvr40ZHBhpVfgsn
# fsCi9aDg3iI/Dv9+lfvzo7oiPhisEeTwmQNtO4V8CdPuXciaC1TjqAlxa+DPIhAP
# dc9xck4Krd9AOly3UeGheRTGTSQjMF287DxgaqwvB8z98OpH2YhQXv1mblZhJymJ
# hFHmgudGUP2UKiyn5HU+upgPhH+fMRTWrdXyZMt7HgXQhBlyF/EXBu89zdZN7wZC
# /aJTKk+FHcQdPK/P2qwQ9d2srOlW/5MCAwEAAaOCAc4wggHKMB0GA1UdDgQWBBT0
# tuEgHf4prtLkYaWyoiWyyBc1bjAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd
# 823IDzASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUE
# DDAKBggrBgEFBQcDCDB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0f
# BHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBQBgNVHSAESTBHMDgGCmCGSAGG
# /WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQ
# UzALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggEBAHGVEulRh1Zpze/d2nyq
# Y3qzeM8GN0CE70uEv8rPAwL9xafDDiBCLK938ysfDCFaKrcFNB1qrpn4J6Jmvwmq
# YN92pDqTD/iy0dh8GWLoXoIlHsS6HHssIeLWWywUNUMEaLLbdQLgcseY1jxk5R9I
# EBhfiThhTWJGJIdjjJFSLK8pieV4H9YLFKWA1xJHcLN11ZOFk362kmf7U2GJqPVr
# lsD0WGkNfMgBsbkodbeZY4UijGHKeZR+WfyMD+NvtQEmtmyl7odRIeRYYJu6DC0r
# baLEfrvEJStHAgh8Sa4TtuF8QkIoxhhWz0E0tmZdtnR79VYzIi8iNrJLokqV2PWm
# jlIwggU0MIIDHKADAgECAgphHLKKAAAAAAAmMA0GCSqGSIb3DQEBBQUAMH8xCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAMTIE1pY3Jv
# c29mdCBDb2RlIFZlcmlmaWNhdGlvbiBSb290MB4XDTExMDQxNTE5NDEzN1oXDTIx
# MDQxNTE5NTEzN1owZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQg
# QXNzdXJlZCBJRCBSb290IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEArQ4VzuRDgFyxh/O3YPlxEqWu3CaUiKr0zvUgOShYYAz4gNqpFZUyYTy1sSiE
# iorcnwoMgxd6j5Csiud5U1wxhCr2D5gyNnbM3t08qKLvavsh8lJh358g1x/isdn+
# GGTSEltf+VgYNbxHzaE2+Wt/1LA4PsEbw4wz2dgvGP4oD7Ong9bDbkTAYTWWFv5Z
# nIt2bdfxoksNK/8LctqeYNCOkDXGeFWHIKHP5W0KyEl8MZgzbCLph9AyWqK6E4IR
# 7TkXnZk6cqHm+qTZ1Rcxda6FfSKuPwFGhvYoecix2uRXF8R+HA6wtJKmVrO9spft
# qqfwt8WoP5UW0P+hlusIXxh3TwIDAQABo4HLMIHIMBEGA1UdIAQKMAgwBgYEVR0g
# ADALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUReuir/SS
# y4IxLVGLp6chnfNtyA8wHwYDVR0jBBgwFoAUYvsKIVt/Q24R2glUUGv10pZx8Z4w
# VQYDVR0fBE4wTDBKoEigRoZEaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9j
# cmwvcHJvZHVjdHMvTWljcm9zb2Z0Q29kZVZlcmlmUm9vdC5jcmwwDQYJKoZIhvcN
# AQEFBQADggIBAFz1si0Czu0BtTUS2BP3qkAUx6FcoIpV7X5V6mrEVxdv0EciQjZY
# 78WsYcX2LFLOaubIDYXaszRCDqQCJRgmcrkqTqV+SxbyoOQMRJziTZr0dPD5J6Zp
# kDHCRGVDSMdIadD8hAnyhhQKwimWhX8R64cTF27T7Gv/HVeKsXsepaB86aJ6aOX6
# xrFh1nJj+jeRY4NVmfgdYU8Mb6P3vLEVKsyNheMUF+9+SUQ/sCLA8Ky+L9vhDIaw
# 9FhcWhCpS83zRIpGUgg+CmIQ6UWVBLeLjUsHT1ANt7vn+4yieHjGxTt2Y7LP5SGE
# Wmb84Ex5g07PqO5wBYZYfMKc1zyjrTx+dmJch9DtfNXFWxQh9L51onXS6eFa0CAw
# eEFiTWtebhsXECRK2FiHddAV12K7/RhWZYQlYZd/qtSd9PNdbaAxwuGeAqw+kMMy
# fugykDQW0IsUz5WszuWMVKJluL/tGGpXBz7T55pKLwgaBBxJhxqK5hsIo2XYHDHF
# DZy6s2jd9FB2FgZ1/sQD59E+39yGLhACfmYSllNOevM2WHmxIELYlj81vj+O8pmX
# Q/XkDOE8aHKMjUnXWlK1c/t6NZQ6YbCEgsBIhcGXMtObcl+g0jSPfvBGfPKMcpTH
# B7DXtbIwuBll8JyDJ7Cgq9Cicn4FD7Ou3blbm0K8wyZjRWuG8R1GQ+3IMYIEVDCC
# BFACAQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hB
# MiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQQIQAybM8QJy2GqRSHGucYhV3TAJ
# BgUrDgMCGgUAoHAwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisG
# AQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcN
# AQkEMRYEFKWleaTvbff0NEIsi9FUlNXroK8YMA0GCSqGSIb3DQEBAQUABIIBAGDC
# o/bZtpqRUjMgPL2+G1me5dQGMjTKxazqSK56kUtE/MdtIA4ru6JPyn/dP8Q3mRr7
# 9UgQ+eqzC3Ak0UyW46rZIVnGIfa8iWSqXsEBdg3xxVnakM+6FaZ5s/uCCrRSS0Pz
# RmwTRAYQUWiHnCbNygp/hzHEMuVHCeUZiS/r1bn9YjXBTJ1DOfWsyzLKH5wKTxQP
# +50vUPLbD2z7W8Ji2rIGatqi6DDa4pQzhRACO3u82rs1oMvxX1Mpjv0I9dtg9ZM2
# eDxowCwTfQPeiaiQVdiF8Ei6NB/AqUT31UiacTkbwfzZxIK/xE9aL5+Ha8fEPxND
# mvPfEIoLxtdjOIsGt+ahggIwMIICLAYJKoZIhvcNAQkGMYICHTCCAhkCAQEwgYYw
# cjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVk
# IElEIFRpbWVzdGFtcGluZyBDQQIQDUJK4L46iP9gQCHOFADw3TANBglghkgBZQME
# AgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTIxMTEyMzA5MTU0NlowLwYJKoZIhvcNAQkEMSIEIN7HFkAhsuu6PaHkvCFG6gCK
# 80AzUPBTpcv6by0qbaKgMA0GCSqGSIb3DQEBAQUABIIBAGFTHxtkRChN0ERDMqWH
# AnZeQjjTy7iOCRLUsyTNW3QcS3e+vBUKfVfgvtBNAl6/4hq9YPNuOjKupxeQG+4a
# ttYW4rniWkO9NuoQ+G8o1qNvpkMTqkaQ2ogkJOQrgOzadaxTXmKK8x3sCwg+e4Nr
# h/ZSI5h5B9gVspyKuBiZt7ZZCDUAhrVdaE6WnnOVSoOA5uBXr91kJ8pqfNJyD2NI
# nOazSmFDwGJKXUttvIkI5bp3qimIwp05IUeq+xAiZmU0e/zDKgy5sTmUdga2XeUf
# XvocrTm6qbc9Rvttu81jn6dcUCdp6KBhOBdUhjZDMU3quAfCPMnD0XIkbYxeUg9P
# XLc=
# SIG # End signature block
