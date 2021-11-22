$invocation = (Get-Variable MyInvocation).Value
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName.trimend('\')
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$csvContent = Import-Csv "$currentPath\PublicFolderList.csv"
$reportPath = "$currentPath\CreatePublicFolder_Report_$timestamp.csv";
$ret = @()

foreach ($info in $csvContent) {
    try {
       
        Write-Host "Begin to create public folder: $($info.PublicFolderPath). PFMailbox: $($info.PFMailboxName)."

        $tempPath=$info.PublicFolderPath.Trim('\')
        $tempFolders=$tempPath.Split('\')
        $folderName=$tempFolders[$tempFolders.Length-1]
        $index=$tempPath.LastIndexOf('\')
        if($index -eq -1)
        {
           $null = New-PublicFolder -Name $folderName -Path '\' -Mailbox $info.PFMailboxName -ErrorAction Stop
        }
        else
        {
           $parentPath='\'+$tempPath.Substring(0,$index)
           $null = New-PublicFolder -Name $folderName -Path $parentPath -Mailbox $info.PFMailboxName -ErrorAction Stop
        }
        Write-Host "End to create public folder: $($info.PublicFolderPath). PFMailbox: $($info.PFMailboxName)."
        
        $mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "PublicFolderPath" -Value $info.PublicFolderPath
        $mobj | Add-Member -MemberType NoteProperty -Name "PFMailboxName" -Value $info.PFMailboxName
        $mobj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Successful"
        $mobj | Add-Member -MemberType NoteProperty -Name "Comment" -Value ""
        $ret += $mobj
    }
    catch [System.Exception] {
        Write-Warning "Failed to create public folder: $($info.PublicFolderPath). Reason:$($_.Exception.Message)"
        $mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "PublicFolderPath" -Value $info.PublicFolderPath
        $mobj | Add-Member -MemberType NoteProperty -Name "PFMailboxName" -Value $info.PFMailboxName
        $mobj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
        $mobj | Add-Member -MemberType NoteProperty -Name "Comment" -Value $_.Exception.Message
        $ret += $mobj    
    }
}
if ($ret) { 
    $ret | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Finished. Please check the report for details. Path: $($reportPath)"
}
else {
    Write-Host "Finished."
}
