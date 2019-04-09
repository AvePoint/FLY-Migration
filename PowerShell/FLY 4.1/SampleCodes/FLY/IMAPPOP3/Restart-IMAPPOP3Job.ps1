$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$JobId = '<Job Id>'
$Settings = New-IMAPPOP3JobExecutionObject -MigrationType Incremental -StartTime ([System.DateTime]::Now).AddMinutes(2).ToString("o")
$Response = Restart-IMAPPOP3Job -BaseUri $BaseUri -APIKey $ApiKey -Id $JobId -Setting $Settings
$Response.Content