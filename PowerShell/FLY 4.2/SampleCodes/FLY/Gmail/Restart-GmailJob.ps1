$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$JobId = '<Job Id>'
$Settings = New-GmailJobExecutionObject -MigrationType Incremental -StartTime ([System.DateTime]::Now).AddMinutes(2).ToString("o")
$Response = Restart-GmailJob -BaseUri $BaseUri -APIKey $ApiKey -Id $JobId -Setting $Settings
$Response.Content