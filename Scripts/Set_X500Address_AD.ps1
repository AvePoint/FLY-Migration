$invocation = (Get-Variable MyInvocation).Value
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$csvContent = Import-Csv "$currentPath\Identity_LegacyMapping.csv"
$reportPath="$currentPath\Set_X500Address_AD_Report_$timestamp.csv";
$ret = @()
foreach($info in $csvContent){
    try
    {
        Write-Host "Start to Set User: $($info.Identity)"
        Set-ADUser -Identity $info.Identity -add @{proxyAddresses="X500:$($info.LegacyExchangeDN)"} -ErrorAction Stop
        Write-Host "Successful to Set User: $($info.Identity)"	
		$mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "Identity" -Value $info.Identity
        $mobj | Add-Member -MemberType NoteProperty -Name "LegacyExchangeDN" -Value $info.LegacyExchangeDN
        $mobj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Successfull"
        $mobj | Add-Member -MemberType NoteProperty -Name "Comment" -Value ""
        $ret += $mobj
    }
    catch [System.Exception] 
    {
        Write-Warning "Failed to Get User: $($info.Identity). Reason:$($_.Exception.Message)"    
		$mobj = New-Object -TypeName PSCustomObject
        $mobj | Add-Member -MemberType NoteProperty -Name "Identity" -Value $info.Identity
        $mobj | Add-Member -MemberType NoteProperty -Name "LegacyExchangeDN" -Value $info.LegacyExchangeDN
        $mobj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
        $mobj | Add-Member -MemberType NoteProperty -Name "Comment" -Value $_.Exception.Message
        $ret += $mobj
    }
}
 Write-Host "Finished. Please check the report for details. Path: $($reportPath)"
$ret | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8