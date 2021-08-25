$invocation = (Get-Variable MyInvocation).Value
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName.trimend('\')
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$csvContent = Import-Csv "$currentPath\HiddenUserList.csv"
$reportPath = "$currentPath\HiddenUser_Report_$timestamp.csv";
$ret = @()
Write-Host "How do you want to handle the user from the GAL? [H] Hidden user [S] Show user"
$choose = Read-Host
$HiddenUser = $choose -eq "H"
foreach ($info in $csvContent) {
    try {
        if ($HiddenUser) {
            Write-Host "Hidden user: $($info.MailAddress)"
            Set-Mailbox -Identity $info.MailAddress -HiddenFromAddressListsEnabled $true -ErrorAction Stop
            Write-Host "Successful to hidden user: $($info.MailAddress)"
        }
        else {
            Write-Host "Show user: $($info.MailAddress)"
            Set-Mailbox -Identity $info.MailAddress -HiddenFromAddressListsEnabled $false -ErrorAction Stop
            Write-Host "Successful to show user: $($info.MailAddress)"
        }
        
        $mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "MailAddress" -Value $info.MailAddress
        $mobj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Successful"
        $mobj | Add-Member -MemberType NoteProperty -Name "Comment" -Value ""
        $ret += $mobj
    }
    catch [System.Exception] {
        Write-Warning "Failed to handle user: $($info.MailAddress). Reason:$($_.Exception.Message)"
        $mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "MailAddress" -Value $info.MailAddress
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
