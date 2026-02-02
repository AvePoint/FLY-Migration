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
 *  Copyright © 2017-2026 AvePoint® Inc. All Rights Reserved.
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>
#Install-Module Microsoft.Graph -Scope CurrentUser
<# function area #>
$debug = 'debug'
$warning = 'warning'
$info = 'info'
$green = "Green"
$red = "Red"
$definition = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogFile = -join ($definition, "\log\shell.log")
$date = Get-Date -Format "yy_MM_dd_HH_mm"
$ReportFile = -join ($definition,"\Report$date.csv")
$setLevel = $info;
function OutputMessage {
    param (
        [string]$level,
        [string]$colour
    )
    switch -wildcard ($colour)
    {
        'Green'{Write-Host $Message -ForegroundColor Green}
        default {
            switch -wildcard ($level)
            {
                'warning'{Write-Host $Message -ForegroundColor Yellow}
                'error' {Write-Host $Message -ForegroundColor Red}
                default {Write-Host $Message}
            }
        }
    }
    Write-Output "[$level] : $(Get-Date) ---- $Message" | Out-File -FilePath $LogFile -Append
}

function RecordReport{
    param (
        $reportChatId, 
        $reportChatTopic,
        $reportResult,
        $reportComment
    )
    if (-not (Test-Path $ReportFile)) {
        $ReportFile = New-Item $ReportFile -ItemType File
        Set-Content $ReportFile 'Chat ID,Chat Topic,Result,Comment'
    }
    Add-Content $ReportFile "$reportChatId,$reportChatTopic,$reportResult,$reportComment"
}

Function Write-Log {
    [cmdletbinding()]

    Param(
        [Parameter(Position = 0)]
        [string]$Message,
        [string]$colour,
        [string]$level = "info"
    )

    if (-not (Test-Path $LogFile)) {
        $null = New-Item $LogFile -Force
    }
 
    switch -wildcard ($setLevel) {
        'info' {
            switch -wildcard ($level) {
                'info' { OutputMessage $level -colour $colour }
                'warning' { OutputMessage $level }
                'error' { OutputMessage $level }
                'debug' { Write-Output "[$level] : $(Get-Date) ---- $Message" | Out-File -FilePath $LogFile -Append}
                default {}
            }
        }

        'debug' {
            switch -wildcard ($level) {
                'info' { OutputMessage $level -colour $colour }
                'warning' { OutputMessage $level }
                'error' { OutputMessage $level }
                'debug' { OutputMessage $level }
                default {}
            }
        }
 
        'warning' {
            switch -wildcard ($level) {
                'info' {Write-Output "[$level] : $(Get-Date) ---- $Message" | Out-File -FilePath $LogFile -Append}
                'warning' { OutputMessage $level }
                'error' { OutputMessage $level }
                'debug' {Write-Output "[$level] : $(Get-Date) ---- $Message" | Out-File -FilePath $LogFile -Append}
                default {}
            }
        }

        'error' {
            switch ($level) {
                'info' {Write-Output "[$level] : $(Get-Date) ---- $Message" | Out-File -FilePath $LogFile -Append}
                'warning' {Write-Output "[$level] : $(Get-Date) ---- $Message" | Out-File -FilePath $LogFile -Append}
                'error' { OutputMessage $level }
                'debug' {Write-Output "[$level] : $(Get-Date) ---- $Message" | Out-File -FilePath $LogFile -Append}
                default {}
            }
        }
    }
} 
Function GetChats($nextLink, $allData)
{
   $nextChats=(Invoke-MgGraphRequest -uri $nextLink -Method Get) 
   $value = ConvertTo-Json $nextChats."value"
   $conf = ConvertFrom-Json $value
   $count = ConvertTo-Json $nextChats."@odata.count"
   Write-Output "[info] : $(Get-Date) ---- getchats--otherLink" | Out-File -FilePath $LogFile -Append
   if($count -gt 0)
   {
      $allData = ConvertFrom-Json $allData
      Write-Output "[info] : $(Get-Date) ---- getchats-nextchats-convert alldata" | Out-File -FilePath $LogFile -Append
      foreach($json in $conf)
      {
        $allData += $json
      }
      $allData = ConvertTo-Json $allData
   }
   if([String]::IsNullOrEmpty($nextChats))
   {
     Write-Output "[info] : $(Get-Date) ---- getchats-nextchats-return data" | Out-File -FilePath $LogFile -Append
     return $allData
   }
   else
   {  
      $linkData = ConvertTo-Json $nextChats."@odata.nextLink"
      if([String]::IsNullOrEmpty($linkData))
      {
         Write-Output "[info] : $(Get-Date) ---- getchats--return data" | Out-File -FilePath $LogFile -Append
         return $allData
      }
      else
      {  
         $linkItem = $linkData -replace '"',''
         $nextToken = $linkItem.split(@("skiptoken"),[System.StringSplitOptions]::RemoveEmptyEntries) | select -Last 1
         $linkData = "https://graph.microsoft.com/v1.0/chats?&skiptoken$nextToken"
         Write-Output "[info] : $(Get-Date) ---- getchats--nextLink data" | Out-File -FilePath $LogFile -Append
         GetChats $linkData $allData
      }

   }
}
<# function area #>
# Connect graph api
Write-Log -message "###### Start to connect graph  ######" -colour $green
Connect-MgGraph -Scopes "User.Read", "Chat.ReadWrite" 
$myProfile = Invoke-MgGraphRequest -Method get -Uri "https://graph.microsoft.com/v1.0/me"
$userId = $myProfile.id
$user = Get-MgContext
$UserEmail = $myProfile.mail
$tenantId= $user.TenantId
$allChats=(Invoke-MgGraphRequest -uri "https://graph.microsoft.com/v1.0/chats" -Method Get) 
Write-Output "[info] : $(Get-Date) ---- selete chats and nextlink" | Out-File -FilePath $LogFile -Append
$data = ConvertTo-Json $allChats."value"
$otherLink = ConvertTo-Json $allChats."@odata.nextLink"
Write-Log -message "###### Mark as read - start ######" -colour $green
if($otherLink)
{
  $link = $otherLink -split "skiptoken"
  $otherLink = $link[1]
  $link = $link -replace '"',''
  $links = $link[1]
  Write-Output "[info] : $(Get-Date) ---- nextlink data" | Out-File -FilePath $LogFile -Append
  $linkq = "https://graph.microsoft.com/v1.0/chats?&skiptoken$links"
  $chats = GetChats $linkq $data
  if($chats)
  {
   $item = ConvertFrom-Json $chats
   $chatsCount = $item.count
   Write-Log -message "###### all of chat count: $chatsCount ######"-colour $green
   foreach($data in $item)
   {
     $hasMessage = ""
     $id = $data.id
     $chatType = $data.chatType
     $topic = $data.topic
     Write-Log -message "###### Start to process chat: $id ######"-colour $green
     $params = @{
	  user = @{
		   id = $userId
	           tenantId = $tenantId
	          }
                }
     $jsondata = ConvertTo-Json $params
     $nextDataUri = "https://graph.microsoft.com/v1.0/chats/$id/markChatReadForUser"
     try
     {
         Invoke-MgGraphRequest -Uri $nextDataUri -Body $jsondata -ContentType 'application/json' -Method Post
     }
     catch

     {
          $message = $_.Exception.Message 
          Write-Log -message "###### Message: $message ######" -level "error"
          $hasMessage = $message
     }
     if($topic)
     {
       if($hasMessage)
       {
            $hasMessage = -join('"',"$hasMessage",'"')
		    $topic = $topic -replace '"','""'
            $topic = -join('"',"$topic",'"')
            RecordReport -reportChatId $id -reportChatTopic $topic -reportResult "Failed" -reportComment $hasMessage
	   }
       else
       {
            $topic = $topic -replace '"','""'
            $topic = -join('"',"$topic",'"')
            RecordReport -reportChatId $id -reportChatTopic $topic -reportResult "Successful" -reportComment "" 
       }
     }
     else
     {
        if($chatType -eq "oneOnOne")
        {
           Write-Output "[info] : $(Get-Date) ---- Mark As Read chat Type oneOnOne" | Out-File -FilePath $LogFile -Append
           $memberUri = "https://graph.microsoft.com/beta/chats/$id/members"
           $memberList = Invoke-MgGraphRequest -Uri $memberUri -Method Get
           $memberListValue = ConvertTo-Json $memberList."value"
           $memberData  = ConvertFrom-Json $memberListValue 
           $oneOnOneTopic = ""
           foreach($member in $memberData)
           {
	      $memberEmail = $member.email
              if($memberEmail -ne $UserEmail)
              {
		$oneOnOneTopic = $member.displayName
              }
              
           }
		   $oneOnOneTopic = $oneOnOneTopic -replace '"','""'
           $oneOnOneTopic = -join('"',"$oneOnOneTopic",'"')
           if($hasMessage)
           {
                $hasMessage = -join('"',"$hasMessage",'"')
                RecordReport -reportChatId $id -reportChatTopic $oneOnOneTopic -reportResult "Failed" -reportComment $hasMessage
	   }
           else
           {
                RecordReport -reportChatId $id -reportChatTopic $oneOnOneTopic -reportResult "Successful" -reportComment ""
	   }
        }
        else
        {
           Write-Output "[info] : $(Get-Date) ---- Mark As Read chat Type other" | Out-File -FilePath $LogFile -Append
           $memberUri = "https://graph.microsoft.com/beta/chats/$id/members"
           $memberList = Invoke-MgGraphRequest -Uri $memberUri -Method Get
           $memberListValue = ConvertTo-Json $memberList."value"
           $memberData  = ConvertFrom-Json $memberListValue
           $otherTypeTopic = @()
           foreach($member in $memberData)
           {
	      $memberEmail = $member.email
              if($memberEmail -ne $UserEmail)
              {
                $displayName = $member.displayName
		      $otherTypeTopic += $displayName
              }
           }
           $otherTypeTopic = $otherTypeTopic | sort
           $otherTypeTopic = $otherTypeTopic -join ","  
		   $otherTypeTopic = $otherTypeTopic -replace '"','""'		   
           $reportTopic = -join('"',"$otherTypeTopic",'"')
           if($hasMessage)
           {
            $hasMessage = -join('"',"$hasMessage",'"')
		RecordReport -reportChatId $id -reportChatTopic $reportTopic -reportResult "Failed" -reportComment $hasMessage
	   }
           else
           {
                RecordReport -reportChatId $id -reportChatTopic $reportTopic -reportResult "Successful" -reportComment ""
	   }
	}
     }
   }
   Write-Log -message "###### Mark as read - end ######" -colour $green
  }
}
else
{
   Write-Log -message "###### else data ######" -colour $green
   $data  = ConvertFrom-Json $data
   $count = $data.count
   Write-Log -message "###### all of chat count: $count ######"-colour $green
   foreach($notNextData in $data)
   {
     $hasMessage = ""
     $notNextId = $notNextData.id
     $topic = $notNextData.topic
     $chatType = $notNextData.chatType
     Write-Log -message "###### Start to process chat: $notNextId ######"-colour $green
     $params = @{
	  user = @{
		   id = $userId
	           tenantId = $tenantId
	          }
                }
     $json = ConvertTo-Json $params
     $nextDataUri = "https://graph.microsoft.com/v1.0/chats/$notNextId/markChatReadForUser"
     try
     {
         Invoke-MgGraphRequest -Uri $nextDataUri -Body $json -ContentType 'application/json' -Method Post
     }
     catch
     {
          $message = $_.Exception.Message 
          Write-Log -message "###### Message: $message ######" -level "error"
	  $hasMessage = $message
     }
      if($topic)
     {
           if($hasMessage)
           {
                $hasMessage = -join('"',"$hasMessage",'"')
				$topic = $topic -replace '"','""'
                $topic = -join('"',"$topic",'"')
                RecordReport -reportChatId $notNextId -reportChatTopic $topic -reportResult "Failed" -reportComment $hasMessage
	   }
           else
           {
                $topic = $topic -replace '"','""'
                $topic = -join('"',"$topic",'"')
                RecordReport -reportChatId $notNextId -reportChatTopic $topic -reportResult "Successful" -reportComment ""
	   }
     }
     else
     {
        if($chatType -eq "oneOnOne")
        {
           Write-Output "[info] : $(Get-Date) ---- Mark As Read chat Type oneOnOne" | Out-File -FilePath $LogFile -Append
           $memberUri = "https://graph.microsoft.com/beta/chats/$notNextId/members"
           $memberList = Invoke-MgGraphRequest -Uri $memberUri -Method Get
           $memberListValue = ConvertTo-Json $memberList."value"
           $memberData  = ConvertFrom-Json $memberListValue
           $oneOnOneTopic = ""
           foreach($member in $memberData)
           {
	      $memberEmail = $member.email
              if($memberEmail -ne $UserEmail)
              {
		$oneOnOneTopic = $member.displayName
              }
              
           }
		   $oneOnOneTopic = $oneOnOneTopic -replace '"','""'
           $oneOnOneTopic = -join('"',"$oneOnOneTopic",'"')
           if($hasMessage)
           {
            $hasMessage = -join('"',"$hasMessage",'"')
		RecordReport -reportChatId $notNextId -reportChatTopic $oneOnOneTopic -reportResult "Failed" -reportComment $hasMessage
	   }
           else
           {
                RecordReport -reportChatId $notNextId -reportChatTopic $oneOnOneTopic -reportResult "Successful" -reportComment "" 
	   }
        }
        else
        {
           Write-Output "[info] : $(Get-Date) ---- Mark As Read chat Type other" | Out-File -FilePath $LogFile -Append
           $memberUri = "https://graph.microsoft.com/beta/chats/$notNextId/members"
           $memberList = Invoke-MgGraphRequest -Uri $memberUri -Method Get
           $memberListValue = ConvertTo-Json $memberList."value"
           $memberData  = ConvertFrom-Json $memberListValue
           $otherTypeTopic = @()
           foreach($member in $memberData)
           {
	      $memberEmail = $member.email
              if($memberEmail -ne $UserEmail)
              {
                $displayName = $member.displayName
		$otherTypeTopic += $displayName
              }
           }
           $otherTypeTopic = $otherTypeTopic | sort
           $otherTypeTopic = $otherTypeTopic -join ","   
		   $otherTypeTopic = $otherTypeTopic -replace '"','""'		   
           $reportTopic = -join('"',"$otherTypeTopic",'"')
           if($hasMessage)
           {
                $hasMessage = -join('"',"$hasMessage",'"')
		        RecordReport -reportChatId $notNextId -reportChatTopic $reportTopic -reportResult "Failed" -reportComment $hasMessage
	       }
           else
           {
                RecordReport -reportChatId $notNextId -reportChatTopic $reportTopic -reportResult "Successful" -reportComment "" 
	       }
	}
     }
   }
   Write-Log -message "###### Mark as read - end ######" -colour $green
}
Disconnect-MgGraph
Write-Log -message "Success!" -colour $green
Write-Log -message "###### end to disconnect graph  ######" -colour $green
Write-Log -message "Log file path: $LogFile" -colour $green
Write-Log -message "Report file path: $ReportFile" -colour $green
Read-Host "Enter to Exit"


# SIG # Begin signature block
# MIIoZAYJKoZIhvcNAQcCoIIoVTCCKFECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCSAVjlLO+f6sMP
# sKxX2e1HsWCDLxso0YLx7IsTCHbW4aCCDZowggawMIIEmKADAgECAhAIrUCyYNKc
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
# EqLoRTGCGiAwghocAgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2ln
# bmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQD3PbKnfwZFFLFp9BUDAdFDAN
# BglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCB4A/w//fIga1NZsQahh+97mvUp5yFK7bYuOHxy/QwHWDANBgkq
# hkiG9w0BAQEFAASCAYC38Hgu5cdEZugacNMHhhui8/uwOUWzKeWIIaBr7lhTSBRb
# hkFTZVfIsPtHq3JI8gdOr4EdUOTAy+EPu1LSQySH3XBHkdktnB31Wi2rySlLEA0D
# eUMC4UkFR4rGZ8WqtXyhyfMKLgk22YwCrp1niEiXrYZlsD00mpZPiXzV3P1GP7fU
# KwUy36caZ+KuuvO/sLIxZKJMAugvtCccDtoHnGGV1A4adS2yBGAATS7UA5H0ix88
# /oDd+oUumBEbY7MN0h5jjtLy6XRKPtz0cVHmplTEcLhUx8QPqrFka3MgIMoRUsVW
# og+OtEFq0Bn1FkpHmf1J7kJyM5i5ZR0svMj4DDIBr/JyatVh/dPVIFds59bBgSXH
# 7pQnQjovJakFzhKGOT+Qdh+tNZMgtBQPbNhlkBCPI+GrBAu36qJS+PeQTBqcVenm
# cbzeLqfw/SwEiiWCIU9zbPsYcklZ78x/tSZ2EryP5boCPbrgAK+MII6P/pWc/432
# r06NlhRXxUCKBpLEhLWhghd2MIIXcgYKKwYBBAGCNwMDATGCF2IwghdeBgkqhkiG
# 9w0BBwKgghdPMIIXSwIBAzEPMA0GCWCGSAFlAwQCAQUAMHcGCyqGSIb3DQEJEAEE
# oGgEZjBkAgEBBglghkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQgy6Uy4+NSqg8d
# 21K3Jn3mRFGmON6GdJY9hhQujaYvUOECEBwtKsfqLXw8a7J/BhJbMlQYDzIwMjYw
# MTA1MDUzNzQxWqCCEzowggbtMIIE1aADAgECAhAKgO8YS43xBYLRxHanlXRoMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcg
# UlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwHhcNMjUwNjA0MDAwMDAwWhcNMzYwOTAz
# MjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4x
# OzA5BgNVBAMTMkRpZ2lDZXJ0IFNIQTI1NiBSU0E0MDk2IFRpbWVzdGFtcCBSZXNw
# b25kZXIgMjAyNSAxMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0Eas
# LRLGntDqrmBWsytXum9R/4ZwCgHfyjfMGUIwYzKomd8U1nH7C8Dr0cVMF3BsfAFI
# 54um8+dnxk36+jx0Tb+k+87H9WPxNyFPJIDZHhAqlUPt281mHrBbZHqRK71Em3/h
# CGC5KyyneqiZ7syvFXJ9A72wzHpkBaMUNg7MOLxI6E9RaUueHTQKWXymOtRwJXcr
# cTTPPT2V1D/+cFllESviH8YjoPFvZSjKs3SKO1QNUdFd2adw44wDcKgH+JRJE5Qg
# 0NP3yiSyi5MxgU6cehGHr7zou1znOM8odbkqoK+lJ25LCHBSai25CFyD23DZgPfD
# rJJJK77epTwMP6eKA0kWa3osAe8fcpK40uhktzUd/Yk0xUvhDU6lvJukx7jphx40
# DQt82yepyekl4i0r8OEps/FNO4ahfvAk12hE5FVs9HVVWcO5J4dVmVzix4A77p3a
# wLbr89A90/nWGjXMGn7FQhmSlIUDy9Z2hSgctaepZTd0ILIUbWuhKuAeNIeWrzHK
# YueMJtItnj2Q+aTyLLKLM0MheP/9w6CtjuuVHJOVoIJ/DtpJRE7Ce7vMRHoRon4C
# WIvuiNN1Lk9Y+xZ66lazs2kKFSTnnkrT3pXWETTJkhd76CIDBbTRofOsNyEhzZtC
# GmnQigpFHti58CSmvEyJcAlDVcKacJ+A9/z7eacCAwEAAaOCAZUwggGRMAwGA1Ud
# EwEB/wQCMAAwHQYDVR0OBBYEFOQ7/PIx7f391/ORcWMZUEPPYYzoMB8GA1UdIwQY
# MBaAFO9vU0rp5AZ8esrikFb2L9RJ7MtOMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDCBlQYIKwYBBQUHAQEEgYgwgYUwJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBdBggrBgEFBQcwAoZRaHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0YW1waW5n
# UlNBNDA5NlNIQTI1NjIwMjVDQTEuY3J0MF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGlu
# Z1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjAL
# BglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAGUqrfEcJwS5rmBB7NEIRJ5j
# QHIh+OT2Ik/bNYulCrVvhREafBYF0RkP2AGr181o2YWPoSHz9iZEN/FPsLSTwVQW
# o2H62yGBvg7ouCODwrx6ULj6hYKqdT8wv2UV+Kbz/3ImZlJ7YXwBD9R0oU62Ptgx
# Oao872bOySCILdBghQ/ZLcdC8cbUUO75ZSpbh1oipOhcUT8lD8QAGB9lctZTTOJM
# 3pHfKBAEcxQFoHlt2s9sXoxFizTeHihsQyfFg5fxUFEp7W42fNBVN4ueLaceRf9C
# q9ec1v5iQMWTFQa0xNqItH3CPFTG7aEQJmmrJTV3Qhtfparz+BW60OiMEgV5GWoB
# y4RVPRwqxv7Mk0Sy4QHs7v9y69NBqycz0BZwhB9WOfOu/CIJnzkQTwtSSpGGhLdj
# nQ4eBpjtP+XB3pQCtv4E5UCSDag6+iX8MmB10nfldPF9SVD7weCC3yXZi/uuhqdw
# kgVxuiMFzGVFwYbQsiGnoa9F5AaAyBjFBtXVLcKtapnMG3VH3EmAp/jsJ3FVF3+d
# 1SVDTmjFjLbNFZUWMXuZyvgLfgyPehwJVxwC+UpX2MSey2ueIu9THFVkT+um1vsh
# ETaWyQo8gmBto/m3acaP9QsuLj3FNwFlTxq25+T4QwX9xa6ILs84ZPvmpovq90K8
# eWyG2N01c4IhSOxqt81nMIIGtDCCBJygAwIBAgIQDcesVwX/IZkuQEMiDDpJhjAN
# BgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQg
# SW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2Vy
# dCBUcnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3MDAwMDAwWhcNMzgwMTE0MjM1OTU5
# WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNV
# BAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hB
# MjU2IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtHgx
# 0wqYQXK+PEbAHKx126NGaHS0URedTa2NDZS1mZaDLFTtQ2oRjzUXMmxCqvkbsDpz
# 4aH+qbxeLho8I6jY3xL1IusLopuW2qftJYJaDNs1+JH7Z+QdSKWM06qchUP+AbdJ
# gMQB3h2DZ0Mal5kYp77jYMVQXSZH++0trj6Ao+xh/AS7sQRuQL37QXbDhAktVJMQ
# bzIBHYJBYgzWIjk8eDrYhXDEpKk7RdoX0M980EpLtlrNyHw0Xm+nt5pnYJU3Gmq6
# bNMI1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC2ZQ8BbfnFRQVESYOszFI2Wv82wnJ
# RfN20VRS3hpLgIR4hjzL0hpoYGk81coWJ+KdPvMvaB0WkE/2qHxJ0ucS638ZxqU1
# 4lDnki7CcoKCz6eum5A19WZQHkqUJfdkDjHkccpL6uoG8pbF0LJAQQZxst7VvwDD
# jAmSFTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8hjj/q8d6ylgxCZSKi17yVp2NL+cn
# T6Toy+rN+nM8M7LnLqCrO2JP3oW//1sfuZDKiDEb1AQ8es9Xr/u6bDTnYCTKIsDq
# 1BtmXUqEG1NqzJKS4kOmxkYp2WyODi7vQTCBZtVFJfVZ3j7OgWmnhFr4yUozZtqg
# PrHRVHhGNKlYzyjlroPxul+bgIspzOwbtmsgY1MCAwEAAaOCAV0wggFZMBIGA1Ud
# EwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9vU0rp5AZ8esrikFb2L9RJ7MtOMB8G
# A1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjAT
# BgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYD
# VR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9
# bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsWgBz+Bz0RdnEwvb4LyLU0pn/N0IfF
# iBowf0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j00DNqhCT3t+s8G0iP5kvN2n7Jd2E4
# /iEIUBO41P5F448rSYJ59Ib61eoalhnd6ywFLerycvZTAz40y8S4F3/a+Z1jEMK/
# DMm/axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2e26MHvVY9gCDA/JYsq7pGdogP8HR
# trYfctSLANEBfHU16r3J05qX3kId+ZOczgj5kjatVB+NdADVZKON/gnZruMvNYY2
# o1f4MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXuvTPSegOOzr4EWj7PtspIHBldNE2K
# 9i697cvaiIo2p61Ed2p8xMJb82Yosn0z4y25xUbI7GIN/TpVfHIqQ6Ku/qjTY6hc
# 3hsXMrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZjE4YtL8Pbzg0c1ugMZyZZd/BdHLi
# Ru7hAWE6bTEm4XYRkA6Tl4KSFLFk43esaUeqGkH/wyW4N7OigizwJWeukcyIPbAv
# jSabnf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQsfch28bZeUz2rtY/9TCA6TD8dC3J
# E3rYkrhLULy7Dc90G6e8BlqmyIjlgp2+VqsS9/wQD7yFylIz0scmbKvFoW2jNrbM
# 1pD2T7m3XDCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ4ghAGFowDQYJKoZIhvcN
# AQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcG
# A1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJl
# ZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMxMTEwOTIzNTk1OVowYjEL
# MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3
# LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv+aQc2jeu+RdSjwwIjBp
# M+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/MbpDgW61bGl20dq7J58soR
# 0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlqczKU0RBEEC7fgvMHhOZ0
# O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxbGrzryc/NrDRAX7F6Zu53
# yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcvak17cjo+A2raRmECQecN4
# x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sEcypukQF8IUzUvK4bA3Vd
# eGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ckXEaPZPfBaYh2mHY9WV1C
# doeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA5EUlibaaRBkrfsCUtNJh
# besz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFjGESVGnZifvaAsPvoZKYz
# 0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+Jqy2QXXeeqxfjT/JvNNB
# ERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotPwtZFX50g/KEexcCPorF+
# CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8GA1UdEwEB/wQFMAMBAf8w
# HQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8GA1UdIwQYMBaAFEXroq/0
# ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5BggrBgEFBQcBAQRtMGsw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcw
# AoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElE
# Um9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMBEGA1UdIAQKMAgwBgYE
# VR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhfoKN0Gz22Ftf3v1cHvZqs
# oYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv9P+Aufih9/Jy3iS8UgPI
# TtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZy51PpwYDE3cnRNTnf+hZ
# qPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTVPeix3P0c2PR3WlxUjG/v
# oVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGyWfVVa88nq2x2zm8jLfR+
# cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3AamfV6peKOK5lDGCA3wwggN4
# AgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEw
# PwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2
# IFNIQTI1NiAyMDI1IENBMQIQCoDvGEuN8QWC0cR2p5V0aDANBglghkgBZQMEAgEF
# AKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8X
# DTI2MDEwNTA1Mzc0MVowKwYLKoZIhvcNAQkQAgwxHDAaMBgwFgQU3WIwrIYKLTBr
# 2jixaHlSMAf7QX4wLwYJKoZIhvcNAQkEMSIEIC95ihXmoqjP/vbL4aL9Bw5ld3w4
# wyqPfa2N9e9+DYrNMDcGCyqGSIb3DQEJEAIvMSgwJjAkMCIEIEqgP6Is11yExVyT
# j4KOZ2ucrsqzP+NtJpqjNPFGEQozMA0GCSqGSIb3DQEBAQUABIICAC4cBT6UwrFr
# OhcmrttH5QlP6z970plasAiyWmV01Xt0qnZVidEHMGc1dNv7+t5dLkNsT8L9OnM1
# SM3z+//zQVUB/a6HjkhwEoPtaC5wXe77hu3nq8qAw8mbkzJpVZ1pVptPUNuf90Na
# GY9jyHMkA30bP91RxFbMsOaZljAMcIkWPZhsGZ3rkaQ0Fz7bQGxtSUZ+ZUgjN9//
# B5hIiS89PXNIoZAfZr4LzbkQoDy3kh2NiXy4GWxSPMPE1KkmW9I2047WdRgw/YEb
# br33wYA/skMvVSM/bK6oum3ysV4dCM/zzUeAw+Ih3jGQdzcm9E3s+6Ojt8VRHJ6d
# 6nN4qWf3itGlFXaW/f1IW/sWa3xLMibpCk0bgdwJwh/9eK0LXTqwerJEe6J5Arht
# KkLU9mHDnM8/8ekFYPG6UtB0EnpRZPm+Bwwc4mV2PzrcXOi0OswzxMOnpv92Cj5A
# r1R61T/RQmmw0eockvjs58K6qt5cpco3wI5IB412bxYsqrIvl5EqRQG8R8rmsDdl
# 5vanYNyo7Lc8CvuoNFmb6OdrBcUnLAtpeBLEYERFHwVQpyNonXS5YEqJ3b/dSGIM
# 681xhI8lWGZHEA1xX9FDTAKnPougM//0u5v/A0hAnXgNV2iYl8zwFN5tCKCwce/p
# ema8Fp+vR532Vwpd+DP8MDRFCqpvKenG
# SIG # End signature block
