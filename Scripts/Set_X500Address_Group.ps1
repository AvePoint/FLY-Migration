$invocation = (Get-Variable MyInvocation).Value
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$csvContent = Import-Csv "$currentPath\MailAddress_LegacyMapping_Group.csv"
$reportPath="$currentPath\Set_X500Address_Group_Report_$timestamp.csv";
$ret = @()
foreach($info in $csvContent){
    try
    {
        Write-Host "Start to Set Mailbox: $($info.MailAddress)"
        Set-UnifiedGroup -Identity $info.MailAddress -EmailAddresses @{Add ='X500:'+$info.LegacyExchangeDN} -ErrorAction Stop
        Write-Host "Successful to Set Mailbox: $($info.MailAddress)"
        $mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "MailAddress" -Value $info.MailAddress
        $mobj | Add-Member -MemberType NoteProperty -Name "LegacyExchangeDN" -Value $info.LegacyExchangeDN
        $mobj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Successful"
        $mobj | Add-Member -MemberType NoteProperty -Name "Comment" -Value ""
        $ret += $mobj

    }
    catch [System.Exception] 
    {
        Write-Warning "Failed to set mailbox: $($info.MailAddress). Reason:$($_.Exception.Message)"
        $mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "MailAddress" -Value $info.MailAddress
        $mobj | Add-Member -MemberType NoteProperty -Name "LegacyExchangeDN" -Value $info.LegacyExchangeDN
        $mobj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
        $mobj | Add-Member -MemberType NoteProperty -Name "Comment" -Value $_.Exception.Message
        $ret += $mobj
    
    }
}
 Write-Host "Finished. Please check the report for details. Path: $($reportPath)"
$ret | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
