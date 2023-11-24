<# /********************************************************************
 *
 *  PROPRIETARY and CONFIDENTIAL
 *
 *  This file is licensed from, and is a trade secret of:
 *
 *                   AvePoint, Inc.
 *                   525 Washington Blvd, Suite 1400
 *                   Jersey City, NJ 07310
 *                   United States of America
 *                   Telephone: +1-201-793-1111
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
 *  Copyright © 2017-2023 AvePoint® Inc. All Rights Reserved.
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

function Set-connectionType{
    param
    (
    [Parameter(Mandatory = $true)]
    [string]$type
    )
    if(("Online","OnPremises") -contains $type)
    {
        if($type -eq "Online"){
            return $true
        }
        return $false
    }
    throw "Specify the connection type parameter error, the parameter type can only be 'Online' and 'OnPremises', please check if the connection type is correct."
  
}

$Path = Get-ScriptDirectory

 
$ApiKey = '<Api Key>'
$BaseUri = '<Base Uri>'

# For example: 
# Once : $Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')
# Daily : $Schedule = New-SimpleScheduleObject -IntervalType Daily -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o') -LastIncrementalMigrationStartTime ([Datetime]::Now).AddDays(1).ToString('o')
# For more information about the schedule setting format, please see the  New-ScheduleObject.ps1 file in '...\SampleCodes\FLY\Common\' directory 
$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')


# For example: $PlanGroups = @('Group Id1 or Name1','Group Id2 or Name2')
$PlanGroups = @()

# The Policy cannot be empty, this is a required field.
# For example: $Policy = 'Policy Id or Name'
$Policy = ''

# Verify the mailboxes exist and are available for migration.
# For example: $VerifyMapping = $True/$False
$VerifyMapping = $False;

# For example: $Database = 'Database Id' or $Database = 'Database Id or Database Name(Database Server)'
$Database = ''

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
		    if($ErrorMessage.Response){
            $FromJson = ConvertFrom-Json $ErrorMessage.Response.Content;
            Write-Host -ForegroundColor Red $FromJson.error$FromJson.errors.description$FromJson.description
            }
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
	if($ErrorMessage.Response){
    $FromJson = ConvertFrom-Json $ErrorMessage.Response.Content;
    Write-Host -ForegroundColor Red $FromJson.error$FromJson.errors.description$FromJson.description
    }
}
# SIG # Begin signature block
# MIIogAYJKoZIhvcNAQcCoIIocTCCKG0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUuDTka4TDBEmSULHpIxF1lsHi
# o3GggiKmMIIFLTCCBBWgAwIBAgIQAybM8QJy2GqRSHGucYhV3TANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMTEwMzAwMDAwMFoXDTIzMTEw
# NzIzNTk1OVowajELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDAS
# BgNVBAcTC0plcnNleSBDaXR5MRcwFQYDVQQKEw5BdmVQb2ludCwgSW5jLjEXMBUG
# A1UEAxMOQXZlUG9pbnQsIEluYy4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDbkeodMZTyIxQr/Vt7VlDpjm9D9mxRJ7V3g1f82yldPyAP1PlBczHklw9g
# F9+kSQXS96v0fnQcQWte5Fx29TMKnomAgKvMkr/LJc0W0dZHyIl61DCUhQZu6J2b
# T6TPQKIuV7eQ1ZYs+S+waw8SN+dE3WX8qd131OlL7q2yHLT0ErYZQObgv39L2Z6+
# u3dE8MFyAUmWDQnerY1+scb78kNwVS4o2xxi6AKeLFQ+ZWFh6wM2lcogPwCTh0mI
# 1cU++AHO4gVgH9yPc75oZa0GzKzH9dqmf8OW+tnQk9QPAhWP6ELtlrm3AgsGfGP+
# zcaIB1JoAbARX9sek3vkTx3t5XAhAgMBAAGjggHFMIIBwTAfBgNVHSMEGDAWgBRa
# xLl7KgqjpepxA8Bg+S32ZXUOWDAdBgNVHQ4EFgQU7JjCyzkrLNPHmZmqTsPNmUEs
# CuowDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1UdHwRw
# MG4wNaAzoDGGL2h0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQt
# Y3MtZzEuY3JsMDWgM6Axhi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1h
# c3N1cmVkLWNzLWcxLmNybDBMBgNVHSAERTBDMDcGCWCGSAGG/WwDATAqMCgGCCsG
# AQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEEATCB
# hAYIKwYBBQUHAQEEeDB2MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vy
# dC5jb20wTgYIKwYBBQUHMAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydFNIQTJBc3N1cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMBAf8E
# AjAAMA0GCSqGSIb3DQEBCwUAA4IBAQB4z6WmQmBTtbLCOF4iUzcK2DjvOEkv1ukR
# LPESBxMCET6tY6659AHKBgXP/sKMIDIVnHs8x0ib9AklSbZZcybtcI/E72iLaL76
# mtMp2pNbK3ekVFIE5CsD5IKfTkilDuPC2kyxizsWGE4r6eXEYzGPGO4LBIEDdRl6
# Jmdf3JMRUAd6bjaueA8NptF83EVAh/+TtPpyQdRLBS+63625z03hUGXKfv3m1VjI
# FnzvZ8V69v+0hvuCXjR2Y1Ms8gn1hWRNrPaGE/xahPNiBsae//15Ogmru112wRAk
# BFrj71MWTkGjYKvQZLPKUICgj/O/VxOUyEnykfJmfk4AhyRpdkMQMIIFMDCCBBig
# AwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcN
# MTMxMDIyMTIwMDAwWhcNMjgxMDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEw
# LwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENB
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJ
# Gc/Q+0WZsTrbRPV/5aid2zLXcep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55
# KDp+6dFn08b7KSfH03sjlOSRI5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF
# 1C2ho+mILCCVrhxKhwjfDPXiTWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP
# 6vIK5Fe7SrXpdOYr/mzLfnQ5Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+
# UpbB8g8S9MWOD8Gi6CxR93O8vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT
# 0QIDAQABo4IBzTCCAckwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMC
# AYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5j
# cnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgw
# RjA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2lj
# ZXJ0LmNvbS9DUFMwCgYIYIZIAYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5
# LfZldQ5YMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3
# DQEBCwUAA4IBAQA+7A1aJLPzItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Sv
# i/3vKt8gVTew4fbRknUPUbRupY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivec
# Rk5c/5CxGwcOkRX7uq+1UcKNJK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemho
# r5unXCBc2XGxDI+7qPjFEmifz0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZbo
# WR3p+nRka7LrZkPas7CM1ekN3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3
# Ym6hU/oSlBiFLpKR6mhsRDKyZqHnGKSaZFHvMIIFNDCCAxygAwIBAgIKYRyyigAA
# AAAAJjANBgkqhkiG9w0BAQUFADB/MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSkwJwYDVQQDEyBNaWNyb3NvZnQgQ29kZSBWZXJpZmljYXRpb24g
# Um9vdDAeFw0xMTA0MTUxOTQxMzdaFw0yMTA0MTUxOTUxMzdaMGUxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK0OFc7kQ4BcsYfzt2D5cRKlrtwm
# lIiq9M71IDkoWGAM+IDaqRWVMmE8tbEohIqK3J8KDIMXeo+QrIrneVNcMYQq9g+Y
# MjZ2zN7dPKii72r7IfJSYd+fINcf4rHZ/hhk0hJbX/lYGDW8R82hNvlrf9SwOD7B
# G8OMM9nYLxj+KA+zp4PWw25EwGE1lhb+WZyLdm3X8aJLDSv/C3LanmDQjpA1xnhV
# hyChz+VtCshJfDGYM2wi6YfQMlqiuhOCEe05F52ZOnKh5vqk2dUXMXWuhX0irj8B
# Rob2KHnIsdrkVxfEfhwOsLSSplazvbKX7aqn8LfFqD+VFtD/oZbrCF8Yd08CAwEA
# AaOByzCByDARBgNVHSAECjAIMAYGBFUdIAAwCwYDVR0PBAQDAgGGMA8GA1UdEwEB
# /wQFMAMBAf8wHQYDVR0OBBYEFEXroq/0ksuCMS1Ri6enIZ3zbcgPMB8GA1UdIwQY
# MBaAFGL7CiFbf0NuEdoJVFBr9dKWcfGeMFUGA1UdHwROMEwwSqBIoEaGRGh0dHA6
# Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY3Jvc29mdENv
# ZGVWZXJpZlJvb3QuY3JsMA0GCSqGSIb3DQEBBQUAA4ICAQBc9bItAs7tAbU1EtgT
# 96pAFMehXKCKVe1+VepqxFcXb9BHIkI2WO/FrGHF9ixSzmrmyA2F2rM0Qg6kAiUY
# JnK5Kk6lfksW8qDkDESc4k2a9HTw+SemaZAxwkRlQ0jHSGnQ/IQJ8oYUCsIploV/
# EeuHExdu0+xr/x1XirF7HqWgfOmiemjl+saxYdZyY/o3kWODVZn4HWFPDG+j97yx
# FSrMjYXjFBfvfklEP7AiwPCsvi/b4QyGsPRYXFoQqUvN80SKRlIIPgpiEOlFlQS3
# i41LB09QDbe75/uMonh4xsU7dmOyz+UhhFpm/OBMeYNOz6jucAWGWHzCnNc8o608
# fnZiXIfQ7XzVxVsUIfS+daJ10unhWtAgMHhBYk1rXm4bFxAkSthYh3XQFddiu/0Y
# VmWEJWGXf6rUnfTzXW2gMcLhngKsPpDDMn7oMpA0FtCLFM+VrM7ljFSiZbi/7Rhq
# Vwc+0+eaSi8IGgQcSYcaiuYbCKNl2BwxxQ2curNo3fRQdhYGdf7EA+fRPt/chi4Q
# An5mEpZTTnrzNlh5sSBC2JY/Nb4/jvKZl0P15AzhPGhyjI1J11pStXP7ejWUOmGw
# hILASIXBlzLTm3JfoNI0j37wRnzyjHKUxwew17WyMLgZZfCcgyewoKvQonJ+BQ+z
# rt25W5tCvMMmY0VrhvEdRkPtyDCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ4ghA
# GFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGln
# aUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMxMTEw
# OTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1
# c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv+aQ
# c2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/MbpDgW
# 61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlqczKU
# 0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxbGrzr
# yc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcvak17c
# jo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sEcypu
# kQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ckXEaP
# ZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA5EUl
# ibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFjGESV
# GnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+Jqy2
# QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotPwtZF
# X50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8GA1Ud
# EwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8GA1Ud
# IwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5Bggr
# BgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNv
# bTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMBEG
# A1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhfoKN0
# Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv9P+A
# ufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZy51P
# pwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTVPeix
# 3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGyWfVV
# a88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3AamfV6pe
# KOK5lDCCBq4wggSWoAMCAQICEAc2N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQEL
# BQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBS
# b290IEc0MB4XDTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UE
# BhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2Vy
# dCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMaGNQZJs8E9cklRVcclA8TykTep
# l1Gh1tKD0Z5Mom2gsMyD+Vr2EaFEFUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt
# +FeoAn39Q7SE2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r
# 07G1decfBmWNlCnT2exp39mQh0YAe9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dh
# gxndX7RUCyFobjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfA
# csW6Th+xtVhNef7Xj3OTrCw54qVI1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpH
# IEPjQ2OAe3VuJyWQmDo4EbP29p7mO1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJS
# lRErWHRAKKtzQ87fSqEcazjFKfPKqpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0
# z9JMq++bPf4OuGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y
# 99xh3pP+OcD5sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBID
# fV8ju2TjY+Cm4T72wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXT
# drnSDmuZDNIztM2xAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
# A1UdDgQWBBS6FtltTYUvcyl2mi91jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFd
# ZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUH
# AwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3Js
# MCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsF
# AAOCAgEAfVmOwJO2b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoN
# qilp/GnBzx0H6T5gyNgL5Vxb122H+oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8V
# c40BIiXOlWk/R3f7cnQU1/+rT4osequFzUNf7WC2qk+RZp4snuCKrOX9jLxkJods
# kr2dfNBwCnzvqLx1T7pa96kQsl3p/yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6sk
# HibBt94q6/aesXmZgaNWhqsKRcnfxI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82H
# hyS7T6NJuXdmkfFynOlLAlKnN36TU6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HN
# T7ZAmyEhQNC3EyTN3B14OuSereU0cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8z
# OYdBeHo46Zzh3SP9HSjTx/no8Zhf+yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIX
# mVnKcPA3v5gA3yAWTyf7YGcWoWa63VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZ
# E/6/pNHzV9m8BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSF
# D/yYlvZVVCsfgPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3WfPwwggbCMIIEqqAD
# AgECAhAFRK/zlJ0IOaa/2z9f5WEWMA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQg
# VHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMjMw
# NzE0MDAwMDAwWhcNMzQxMDEzMjM1OTU5WjBIMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xIDAeBgNVBAMTF0RpZ2lDZXJ0IFRpbWVzdGFtcCAy
# MDIzMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAo1NFhx2DjlusPlSz
# I+DPn9fl0uddoQ4J3C9Io5d6OyqcZ9xiFVjBqZMRp82qsmrdECmKHmJjadNYnDVx
# vzqX65RQjxwg6seaOy+WZuNp52n+W8PWKyAcwZeUtKVQgfLPywemMGjKg0La/H8J
# JJSkghraarrYO8pd3hkYhftF6g1hbJ3+cV7EBpo88MUueQ8bZlLjyNY+X9pD04T1
# 0Mf2SC1eRXWWdf7dEKEbg8G45lKVtUfXeCk5a+B4WZfjRCtK1ZXO7wgX6oJkTf8j
# 48qG7rSkIWRw69XloNpjsy7pBe6q9iT1HbybHLK3X9/w7nZ9MZllR1WdSiQvrCuX
# vp/k/XtzPjLuUjT71Lvr1KAsNJvj3m5kGQc3AZEPHLVRzapMZoOIaGK7vEEbeBlt
# 5NkP4FhB+9ixLOFRr7StFQYU6mIIE9NpHnxkTZ0P387RXoyqq1AVybPKvNfEO2hE
# o6U7Qv1zfe7dCv95NBB+plwKWEwAPoVpdceDZNZ1zY8SdlalJPrXxGshuugfNJgv
# OuprAbD3+yqG7HtSOKmYCaFxsmxxrz64b5bV4RAT/mFHCoz+8LbH1cfebCTwv0KC
# yqBxPZySkwS0aXAnDU+3tTbRyV8IpHCj7ArxES5k4MsiK8rxKBMhSVF+BmbTO776
# 65E42FEHypS34lCh8zrTioPLQHsCAwEAAaOCAYswggGHMA4GA1UdDwEB/wQEAwIH
# gDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMCAGA1UdIAQZ
# MBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAWgBS6FtltTYUvcyl2
# mi91jGogj57IbzAdBgNVHQ4EFgQUpbbvE+fvzdBkodVWqWUxo97V40kwWgYDVR0f
# BFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNybDCBkAYIKwYBBQUH
# AQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBY
# BggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNydDANBgkqhkiG
# 9w0BAQsFAAOCAgEAgRrW3qCptZgXvHCNT4o8aJzYJf/LLOTN6l0ikuyMIgKpuM+A
# qNnn48XtJoKKcS8Y3U623mzX4WCcK+3tPUiOuGu6fF29wmE3aEl3o+uQqhLXJ4Xz
# jh6S2sJAOJ9dyKAuJXglnSoFeoQpmLZXeY/bJlYrsPOnvTcM2Jh2T1a5UsK2nTip
# gedtQVyMadG5K8TGe8+c+njikxp2oml101DkRBK+IA2eqUTQ+OVJdwhaIcW0z5iV
# GlS6ubzBaRm6zxbygzc0brBBJt3eWpdPM43UjXd9dUWhpVgmagNF3tlQtVCMr1a9
# TMXhRsUo063nQwBw3syYnhmJA+rUkTfvTVLzyWAhxFZH7doRS4wyw4jmWOK22z75
# X7BC1o/jF5HRqsBV44a/rCcsQdCaM0qoNtS5cpZ+l3k4SF/Kwtw9Mt911jZnWon4
# 9qfH5U81PAC9vpwqbHkB3NpE5jreODsHXjlY9HxzMVWggBHLFAx+rrz+pOt5Zapo
# 1iLKO+uagjVXKBbLafIymrLS2Dq4sUaGa7oX/cR3bBVsrquvczroSUa31X/MtjjA
# 2Owc9bahuEMs305MfR5ocMB3CtQC4Fxguyj/OOVSWtasFyIjTvTs0xf7UGv/B3cf
# cZdEQcm4RtNsMnxYL2dHZeUbc7aZ+WssBkbvQR7w8F/g29mtkIBEr4AQQYoxggVE
# MIIFQAIBATCBhjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBT
# SEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBAhADJszxAnLYapFIca5xiFXd
# MAkGBSsOAwIaBQCgcDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG
# 9w0BCQQxFgQUZU1dZO/W6arWmIr1WUdAHV0jxMQwDQYJKoZIhvcNAQEBBQAEggEA
# JDyB312oAFtWp1T45Fx0m2DUSTzgRk51qZ8aTp4GolOwj1f98QD1S8snUmVny/eZ
# aBpNJJcngCssIuLDen5C7sfldRfbzzytiIE4oBsJrxO41rbZItbZd/kvh+WPS7Ke
# Bppl8DC2tALksxdc7WH1eGPDyJVHe/7rKUL+xoYAFVGtElydne294eyuXlXbUY3X
# XmbIF0sKR9YH20nfUn0dW1HHwiUG4ogTkzRNInwp3si5QPTdMk1MUsi/hxbfKV9j
# +6s7yfBf7ewuhwFsUSN8sIUnBSR5tCGZ32GdGTS3xRPWzySYJX9PJMK1NWI5UlMj
# FcZ8OSrUTYkI6r0DF6BoIqGCAyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3
# MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UE
# AxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBp
# bmcgQ0ECEAVEr/OUnQg5pr/bP1/lYRYwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG
# 9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzEwMTkxNTEzNDNa
# MC8GCSqGSIb3DQEJBDEiBCBYNC7lQo58kAIPeT9hsF7W4vkxJXRHZpnDZ7MArOAN
# kTANBgkqhkiG9w0BAQEFAASCAgCQ5Yu51/HwEagWS/xihg/9ufRV9JY9UWzOvWl0
# P0m0FJ0RFsU3jsUxEsY9L30/vS70BH/EbFx7CD4fYQgQJWgma0GJ087xSyEiBkyh
# rqIgrBR/z8DUkmjVJqz6MvQjOkY7BDK511KLHOQ5n92swKtHGt03nv0aYCeO7Rfi
# 49x7IvobYIjmjKiFX5R6aLASZWdHq8NhPlFN0fc7tfUffkykgVSCchC7XVxzznjd
# R66szAmThBotbWGaKQezMyG3+EHSXpyQDDMsu5dw+E3bQbahLr/q/K3WdMI9msBy
# ROUZ5oeNn+P/QD9kQmB0z+OQJytFNrMIGOmEaC7pltFKTLi/ftEMxeNif1rJ0qJ3
# F7v26y0yRzqVVG/7VZpLs9YwHAdUPGUqKM7PfacnSqCuo7eDGQVWGHcioB49FbYg
# NMA7rufTDSz2YvYbFwoDbvB6t/d3l6Jau+dNogxcTNEKKw98HUayDzZjaCJzDMQ3
# lEwQkWZynhnDF6CS8DzGkbgbCkWu+mFxLaMdGtie18QR6nNGZ/bqW+55rlLzrlBb
# cecMqjdCjG8TVbJ3C73rSh+Ndf4/t+J/XvC3zz8GO52ogXk/H+rq7/MRjmK/Fv1u
# 45eoC+yGo7CHY+WbrcLqRhXb8jV9c3iBJBYj4uwP1+3oFZbjmhX1wEzns91T71Tj
# 057Mig==
# SIG # End signature block
