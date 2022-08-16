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
 *  Copyright © 2017-2022 AvePoint® Inc. All Rights Reserved.
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$Path = Get-ScriptDirectory



 
$ApiKey = '<Api Key>'
$BaseUri = '<Base Uri>'

# For example: 
# Once : $Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')
# Daily : $Schedule = New-SimpleScheduleObject -IntervalType Daily -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o') -LastIncrementalMigrationStartTime ([Datetime]::Now).AddDays(1).ToString('o')
# For more information about the schedule setting format, please see the  New-ScheduleObject.ps1 file in '...\SampleCodes\FLY\Common\' directory
$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')


# For example: $PlanGroups=@('Group Id1 or Name1','Group Id2 or Name2')
$PlanGroups=@()

# For example: $PlanMode = 'Classic or Advanced'
$PlanMode = ''

# The Policy cannot be empty, this is a required field.
# For example: $Policy = 'Policy Id or Name'
$Policy = ''

# For example:$Database = 'Database Id' or $Database = 'Database Id or Database Name(Database Server)'
$Database=''

# For example: 
# Migrate conversations as HTML file:
#  All conversations:
#    $ConversationsAsHTMLObject = New-ConversationsMigrationSettingsObject -Style AllConversations 
#  Only conversations after:
#    $ConversationsAsHTMLObject = New-ConversationsMigrationSettingsObject -Style ConversationsAfter -MigrateConversationsTimer '2020-07-04'
# Migrate conversations as post messages:
#  All conversations:
#    $ConversationASMessageObject = New-ConversationsMigrationSettingsObject -Style AllConversations 
#  Only conversations after:
#    $ConversationASMessageObject = New-ConversationsMigrationSettingsObject -Style ConversationsAfter -MigrateConversationsTimer '2020-07-04'
$ConversationsAsHTMLObject = New-ConversationsMigrationSettingsObject -Style AllConversations 
$ConversationASMessageObject = New-ConversationsMigrationSettingsObject -Style AllConversations

# To use Microsoft 365 Multi-Geo, you need to enter the Location Code.
# If you want to set Location to 'central location', you need to set the parameter -Location' to [ -Location '' ] or to [-Location 'Central Location'].
# For related information, please refer to "https://docs.microsoft.com/en-us/microsoft-365/enterprise/multi-geo-tenant-configuration?view=o365-worldwide" 
# For example: $MultigeoTenant = New-MultigeoTenantObject -MultigeoTenant:$false -Location 'location code'
$MultigeoTenant = New-MultigeoTenantObject -MultigeoTenant:$false -Location ''

try{
	$CSVFilePath = Join-Path -Path $Path -ChildPath 'PlanCSVs'

	$NewFilePath = $CSVFilePath+"\"+"ImportPlanTemplate-result.csv"
	$ImportCsv = Import-Csv -Path $CSVFilePath"\ImportPlanTemplate.csv"
	$ImportCsv | Select-Object *,"Status","Comment" | Export-Csv -Path $NewFilePath -NoTypeInformation
	$connections  = Import-Csv -Path $NewFilePath
	
	foreach($connection in $connections)
	{
	try{
	   $Csvs = $connection."Mapping Csv"

	   foreach($csv in $Csvs)
	   {
		 $mappings = Import-Csv -Path $CSVFilePath"\$csv" -Encoding UTF8

		 $PlanNameLabel = $csv.Remove($csv.IndexOf("."))

		 $mappingList = @()


		foreach($mapping in $mappings)
		{
			$Destination = New-SlackMigrationMSTeamsObject -Mailbox $mapping.'Destination Team Email Address' -Name $mapping.'Destination Team Name' -Channel $mapping.'Destination Channel' -DestinationChannelType $mapping.'Destination Channel Type'
			$MappingContent = New-SlackMappingContentObject -SourceChannelName $mapping.'Source Slack Channel Name' -Destination $Destination
			$mappingList += $MappingContent
		}
		$Mappings = New-SlackMappingObject -SourceConnectionId $connection."Source Connection" -DestinationConnectionId $connection."Destination Connection" -Contents @($mappingList) -VerifyMapping:$false

		# If you want to check the checkbox on the fly setting page of the create plan, please add this parameter here. 
		# For example: the following SynchronizeDeletion parameter indicates that SynchronizeDeletion is checked. If you do not want to check, please do not fill in the corresponding parameters.
		# If you do not want to set the Schedule, please remove the '-Schedule $Schedule ' parameter below.

		$PlanSettings = New-SlackPlanSettingsObject  -DisplayName $PlanNameLabel -PolicyId $Policy -DatabaseId $Database  -PlanGroups $PlanGroups -ConversationsMigrationAsHTML $ConversationsAsHTMLObject -MigrateAsHTML -MigrateAsMessage  -ConversationsMigrationAsMessages $ConversationASMessageObject -Schedule $Schedule -PlanMode $PlanMode -MultigeoTenant $MultigeoTenant
		$Plan = New-SlackPlanObject -Settings $PlanSettings -Mappings $Mappings

		$Response = Add-SlackPlan -Plan $Plan -BaseUri $BaseUri -APIKey $ApiKey

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
            $connection.Comment = $ErrorMessage.Message + $FromJson.error + $FromJson.errors.description + $FromJson.description
        }
        else{
            $connection.Comment = $ErrorMessage.Message + $ErrorMessage.Response.Content
        }
        
	}
	$connections|Export-Csv -Path $NewFilePath -NoTypeInformation
}
}
Catch
{
	$ErrorMessage = $Error[0].Exception
	Write-Host -ForegroundColor Red $ErrorMessage.Message
	Write-Host -ForegroundColor Red $ErrorMessage.Response.Content
}
# SIG # Begin signature block
# MIIoqAYJKoZIhvcNAQcCoIIomTCCKJUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUt75HwBO/yeUkrHM7YP7jNw1z
# GeeggiLOMIIFLTCCBBWgAwIBAgIQAybM8QJy2GqRSHGucYhV3TANBgkqhkiG9w0B
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
# rt25W5tCvMMmY0VrhvEdRkPtyDCCBbEwggSZoAMCAQICEAEkCvseOAuKFvFLcZ30
# 08AwDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGln
# aUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDYwOTAwMDAwMFoXDTMxMTEw
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
# X50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCAV4wggFaMA8GA1Ud
# EwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8GA1Ud
# IwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjATBgNV
# HSUEDDAKBggrBgEFBQcDCDB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNV
# HR8EPjA8MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURSb290Q0EuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG
# /WwHATANBgkqhkiG9w0BAQwFAAOCAQEAmhYCpQHvgfsNtFiyeK2oIxnZczfaYJ5R
# 18v4L0C5ox98QE4zPpA854kBdYXoYnsdVuBxut5exje8eVxiAE34SXpRTQYy88XS
# AConIOqJLhU54Cw++HV8LIJBYTUPI9DtNZXSiJUpQ8vgplgQfFOOn0XJIDcUwO0Z
# un53OdJUlsemEd80M/Z1UkJLHJ2NltWVbEcSFCRfJkH6Gka93rDlkUcDrBgIy8vb
# Zol/K5xlv743Tr4t851Kw8zMR17IlZWt0cu7KgYg+T9y6jbrRXKSeil7FAM8+03W
# SHF6EBGKCHTNbBsEXNKKlQN2UVBT1i73SkbDrhAscUywh7YnN0RgRDCCBq4wggSW
# oAMCAQICEAc2N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQELBQAwYjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MB4XDTIy
# MDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0
# IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAMaGNQZJs8E9cklRVcclA8TykTepl1Gh1tKD0Z5Mom2g
# sMyD+Vr2EaFEFUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt+FeoAn39Q7SE2hHx
# c7Gz7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r07G1decfBmWNlCnT
# 2exp39mQh0YAe9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dhgxndX7RUCyFobjch
# u0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfAcsW6Th+xtVhNef7X
# j3OTrCw54qVI1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpHIEPjQ2OAe3VuJyWQ
# mDo4EbP29p7mO1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJSlRErWHRAKKtzQ87f
# SqEcazjFKfPKqpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0z9JMq++bPf4OuGQq
# +nUoJEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y99xh3pP+OcD5sjCl
# TNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBIDfV8ju2TjY+Cm4T72
# wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXTdrnSDmuZDNIztM2x
# AgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBS6Ftlt
# TYUvcyl2mi91jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUH
# AQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYI
# KwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcw
# CAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAfVmOwJO2
# b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoNqilp/GnBzx0H6T5g
# yNgL5Vxb122H+oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8Vc40BIiXOlWk/R3f7
# cnQU1/+rT4osequFzUNf7WC2qk+RZp4snuCKrOX9jLxkJodskr2dfNBwCnzvqLx1
# T7pa96kQsl3p/yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6skHibBt94q6/aesXmZ
# gaNWhqsKRcnfxI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82HhyS7T6NJuXdmkfFy
# nOlLAlKnN36TU6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HNT7ZAmyEhQNC3EyTN
# 3B14OuSereU0cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8zOYdBeHo46Zzh3SP9
# HSjTx/no8Zhf+yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIXmVnKcPA3v5gA3yAW
# Tyf7YGcWoWa63VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZE/6/pNHzV9m8BPqC
# 3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSFD/yYlvZVVCsfgPrA
# 8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3WfPwwggbGMIIErqADAgECAhAKekqInsmZ
# QpAGYzhNhpedMA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBS
# U0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMjIwMzI5MDAwMDAwWhcN
# MzMwMzE0MjM1OTU5WjBMMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xJDAiBgNVBAMTG0RpZ2lDZXJ0IFRpbWVzdGFtcCAyMDIyIC0gMjCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALkqliOmXLxf1knwFYIY9DPuzFxs
# 4+AlLtIx5DxArvurxON4XX5cNur1JY1Do4HrOGP5PIhp3jzSMFENMQe6Rm7po0tI
# 6IlBfw2y1vmE8Zg+C78KhBJxbKFiJgHTzsNs/aw7ftwqHKm9MMYW2Nq867Lxg9Gf
# zQnFuUFqRUIjQVr4YNNlLD5+Xr2Wp/D8sfT0KM9CeR87x5MHaGjlRDRSXw9Q3tRZ
# LER0wDJHGVvimC6P0Mo//8ZnzzyTlU6E6XYYmJkRFMUrDKAz200kheiClOEvA+5/
# hQLJhuHVGBS3BEXz4Di9or16cZjsFef9LuzSmwCKrB2NO4Bo/tBZmCbO4O2ufygu
# wp7gC0vICNEyu4P6IzzZ/9KMu/dDI9/nw1oFYn5wLOUrsj1j6siugSBrQ4nIfl+w
# Gt0ZvZ90QQqvuY4J03ShL7BUdsGQT5TshmH/2xEvkgMwzjC3iw9dRLNDHSNQzZHX
# L537/M2xwafEDsTvQD4ZOgLUMalpoEn5deGb6GjkagyP6+SxIXuGZ1h+fx/oK+QU
# shbWgaHK2jCQa+5vdcCwNiayCDv/vb5/bBMY38ZtpHlJrYt/YYcFaPfUcONCleie
# u5tLsuK2QT3nr6caKMmtYbCgQRgZTu1Hm2GV7T4LYVrqPnqYklHNP8lE54CLKUJy
# 93my3YTqJ+7+fXprAgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0T
# AQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeB
# DAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+e
# yG8wHQYDVR0OBBYEFI1kt4kh/lZYRIRhp+pvHDaP3a8NMFoGA1UdHwRTMFEwT6BN
# oEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJT
# QTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGA
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUH
# MAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRH
# NFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQAD
# ggIBAA0tI3Sm0fX46kuZPwHk9gzkrxad2bOMl4IpnENvAS2rOLVwEb+EGYs/XeWG
# T76TOt4qOVo5TtiEWaW8G5iq6Gzv0UhpGThbz4k5HXBw2U7fIyJs1d/2WcuhwupM
# dsqh3KErlribVakaa33R9QIJT4LWpXOIxJiA3+5JlbezzMWn7g7h7x44ip/vEckx
# Sli23zh8y/pc9+RTv24KfH7X3pjVKWWJD6KcwGX0ASJlx+pedKZbNZJQfPQXpodk
# Tz5GiRZjIGvL8nvQNeNKcEiptucdYL0EIhUlcAZyqUQ7aUcR0+7px6A+TxC5MDbk
# 86ppCaiLfmSiZZQR+24y8fW7OK3NwJMR1TJ4Sks3KkzzXNy2hcC7cDBVeNaY/lRt
# f3GpSBp43UZ3Lht6wDOK+EoojBKoc88t+dMj8p4Z4A2UKKDr2xpRoJWCjihrpM6d
# dt6pc6pIallDrl/q+A8GQp3fBmiW/iqgdFtjZt5rLLh4qk1wbfAs8QcVfjW05rUM
# opml1xVrNQ6F1uAszOAMJLh8UgsemXzvyMjFjFhpr6s94c/MfRWuFL+Kcd/Kl7HY
# R+ocheBFThIcFClYzG/Tf8u+wQ5KbyCcrtlzMlkI5y2SoRoR/jKYpl0rl+CL05zM
# bbUNrkdjOEcXW28T2moQbh9Jt0RbtAgKh1pZBHYRoad3AhMcMYIFRDCCBUACAQEw
# gYYwcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1
# cmVkIElEIENvZGUgU2lnbmluZyBDQQIQAybM8QJy2GqRSHGucYhV3TAJBgUrDgMC
# GgUAoHAwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FNgc0QSc8NrZaV7kUPb+R62XR3wdMA0GCSqGSIb3DQEBAQUABIIBAEZWEtk/QcMC
# GtjLMmDANh3E8LM0kqIsd6wUWPod6GRVjwbNEL1oThnhqeHtyQDJ2eRk8rsOV5u7
# nhB09IJO3VGQ31halKd6/vlCJe7pGCDLga5R6vtYvZlhv/mYLip3arLaA+wt1aYu
# FbznRmNMd2GdgiNFQQvZaieAD75cigobtf+m9r8CmrBOeQKBXSKhhpIzuFZcOfRZ
# REJ7hWU0TKO7tLwGzRveQVhXFOww264uQiWqEwBJ8feivEyUF3f1THg4zrPdGsLQ
# SCjLfCBZFtzYoXU7AV/Sv1R+gYr8Y5sUpItGLS65Q3/5e2I54MFO2Nw6sqnc0RUI
# nVvtjCeFuFShggMgMIIDHAYJKoZIhvcNAQkGMYIDDTCCAwkCAQEwdzBjMQswCQYD
# VQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lD
# ZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhAK
# ekqInsmZQpAGYzhNhpedMA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsG
# CSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjIwNzE5MDgxMTAwWjAvBgkqhkiG
# 9w0BCQQxIgQgPPyXid5PE/Rq57NQCsSZx22XqJyHpTg2gDIv/ZAGlm0wDQYJKoZI
# hvcNAQEBBQAEggIADjxiPk0ZKB35FMP8vdo8i65wGZMbDe/C4iGcaG4gdK4ecuVb
# 40050A7NkblLL6lmoEcBYSxCjXl5LZgoDzrgVYeNJzh3gQ8NkcWXBhLZMpskDk/a
# wXkKFLjesXZJS1ic0ELpOWCXU+QrvBfWDgEu8FE8ucvTBw4MIeiObK5aZ/pDTfrP
# ZMO8L/gBhK4n3jyo8MryKNOvHw6Oy6If1B6p3Y5QG50v2Efxz7gF/QT98YKHx4Wf
# TlTTi6GHYERd+k1kQiDtN4huPv6GS7fiSn/uQg2DbqRlPJqoUPmjX5j4YujuDU3j
# nRoTJj9H8xPfWV/2DdDPEw4ks2u2PDZCnsCjS11XYq/yYGMImL70NBTmzAEzeehp
# tyvDfC0uiLsJskg5B10YyBX/qMAP4RJosFywueMo4UaNu4QUbWwYSBgHApAxj+vA
# 6nXlqpa+vyFconAd0Mk0vPuyeZoFHBeBJxVLfN6AhkYOxg2tq8Cj5fvVCYWk3vwv
# Voi2/XpDeipWTmN1oYQHynpGIOYyD6AviNOAhos488z0WAnGtYqr47no98WRewGf
# sV0vry0HtV/ZYdneipe0TlkWDnI/XaXxLB8oH5pIPpsqrFYaJPVBGfUssNJmDPNw
# GWQ2n0dNdUXAvinbSVjWIE4bBj4t0J0gbsE5hGGfJsFzjjGVJQOP1MPtxMA=
# SIG # End signature block
