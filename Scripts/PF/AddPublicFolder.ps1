$invocation = (Get-Variable MyInvocation).Value
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName.trimend('\')
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$csvContent = Import-Csv "$currentPath\PublicFolderList.csv"
$reportPath = "$currentPath\AddPublicFolder_Report_$timestamp.csv";
$ret = @()
foreach ($info in $csvContent) {
    try {
        Write-Host "Add public folder: $($info.PublicFolder). Mailbox name: $($info.PublicFolderMailboxName)."
        if ($info.PublicFolderMailboxName) {
            $null = New-PublicFolder -Name $info.PublicFolder -Mailbox $info.PublicFolderMailboxName -ErrorAction Stop
        }
        else {
            $null = New-PublicFolder -Name $info.PublicFolder -ErrorAction Stop
        }        
        Write-Host "Successful to add public folder: $($info.PublicFolder). Mailbox name: $($info.PublicFolderMailboxName)."
        
        $mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "PublicFolder" -Value $info.PublicFolder
        $mobj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Successful"
        $mobj | Add-Member -MemberType NoteProperty -Name "Comment" -Value ""
        $ret += $mobj
    }
    catch [System.Exception] {
        Write-Warning "Failed to add public folder: $($info.PublicFolder). Reason:$($_.Exception.Message)"
        $mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "PublicFolder" -Value $info.PublicFolder
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
