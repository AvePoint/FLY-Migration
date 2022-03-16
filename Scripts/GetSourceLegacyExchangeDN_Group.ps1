$invocation = (Get-Variable MyInvocation).Value
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$reportPath="$currentPath\SourceLegacyExchangeDN_Group_$timestamp.csv";
try
{
   Get-UnifiedGroup -resultsize unlimited|select-object primarysmtpaddress,legacyexchangedn|Export-csv $reportPath -NoTypeInformation -ErrorAction Stop
   Write-Host "Finished.  File Path: $($reportPath)"
}
catch [System.Exception] 
{
   Write-Warning "Failed to get SourceLegacyExchangeDN. Reason:$($_.Exception.Message)"
}
