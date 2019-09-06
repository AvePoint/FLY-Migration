$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$JobId = '<Job Id>'
$Settings = New-BoxJobExecutionObject -MigrationType Incremental -StartTime ([System.DateTime]::Now).AddMinutes(2).ToString("o")
$Response = Restart-BoxJob -BaseUri $BaseUri -APIKey $ApiKey -Id $JobId -Setting $Settings
$Response.Content