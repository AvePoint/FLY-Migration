
$invocation = (Get-Variable MyInvocation).Value
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$csvContent = Import-Csv "$currentPath\MailAddressList.csv"
$reportPath="$currentPath\SetMaxReceiveSize_Report_$timestamp.csv";
$ret = @()

  foreach($info in $csvContent){
    try
    {
        $maxReceiveSize=$info.MaxReceiveSizeMB+'MB'
        Write-Host "Set Mailbox: $($info.MailAddress)"
        Set-Mailbox -Identity $info.MailAddress -MaxReceiveSize $maxReceiveSize -ErrorAction Stop
        Write-Host "Successful to Set Mailbox: $($info.MailAddress)"
        $mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "MailAddress" -Value $info.MailAddress
        $mobj | Add-Member -MemberType NoteProperty -Name "MaxReceiveSizeMB" -Value $info.MaxReceiveSizeMB
        $mobj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Successful"
        $mobj | Add-Member -MemberType NoteProperty -Name "Comment" -Value ""
        $ret += $mobj

    }
    catch [System.Exception] 
    {
        Write-Warning "Failed to set mailbox: $($info.MailAddress). Reason:$($_.Exception.Message)"
        $mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "MailAddress" -Value $info.MailAddress
        $mobj | Add-Member -MemberType NoteProperty -Name "MaxReceiveSizeMB" -Value $info.MaxReceiveSizeMB
        $mobj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
        $mobj | Add-Member -MemberType NoteProperty -Name "Comment" -Value $_.Exception.Message
        $ret += $mobj
    
    }
}
 Write-Host "Finished. Please check the report for details. Path: $($reportPath)"
$ret | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
