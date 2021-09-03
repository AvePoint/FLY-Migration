$token = "{SlackToken}"
$user = "{UserEmail}"
$channelsCsv = "{ChannelsCsvPath}"
$csvPath = "Report.csv"
$reports = @()

$channels = import-csv  $channelsCsv
function Users-LookupByEmail {
    param (
        $email,
        $token
    )
    $url = "https://slack.com/api/users.lookupByEmail?email=" + $email
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")
    $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers
    if ($response.ok) {
        return $response.user.id
    }
    else {
        Write-Host $response.error
    }
}
function Conversations-Invite {
    param (
        $channelId,
        $userId,
        $token
    )
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/x-www-form-urlencoded")
    $headers.Add("Authorization", "Bearer $token")
    $body = "channel_id=" + $channelId + "&user_ids=" + $userId
    $response = Invoke-RestMethod 'https://slack.com/api/admin.conversations.invite' -Method 'POST' -Headers $headers -Body $body
    if ($response.ok) {
        return "Success"
    }
    else {
        return $response.error
    }
}

$userId = Users-LookupByEmail -email $user -token $token
foreach ($channel in $channels) {
     $reportItem = New-Object PSObject
    $result = Conversations-Invite -channelId $channel.'Channel Id' -userId $userId -token $token
    if($result -eq "Success")
    {
        
                $reportItem | Add-Member NoteProperty -Name "ChannelName" -Value $channel.'Channel Name'
                $reportItem | Add-Member NoteProperty -Name "Success" -Value "True"
                $reportItem | Add-Member NoteProperty -Name "Comment" -Value ""
    }
    else
    {
            if($result -eq "already_in_channel")
            {
                $reportItem | Add-Member NoteProperty -Name "ChannelName" -Value $channel.'Channel Name'
                $reportItem | Add-Member NoteProperty -Name "Success" -Value "True"
                $reportItem | Add-Member NoteProperty -Name "Comment" -Value $result
            }
            else 
            {
                $reportItem | Add-Member NoteProperty -Name "ChannelName" -Value $channel.'Channel Name'
                $reportItem | Add-Member NoteProperty -Name "Success" -Value "False"
                $reportItem | Add-Member NoteProperty -Name "Comment" -Value $result
            }

               
    }
    $reports+= $reportItem
    
    Write-Host "$user, $($channel.'Channel Name'),$($channel.'Channel ID'),$result"
}
$reports | Export-Csv $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Job finished..."



