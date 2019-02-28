$ApiKey = '<api key>'
$BaseUri = '<base uri>'
$JobId = '<job id>'

$Settings = New-ExchangeJobExecutionObject -MigrationType Incremental -StartTime (([Datetime]::Now).AddMinutes(2).ToString())

$Response = Restart-ExchangeJob -BaseUri $BaseUri -APIKey $ApiKey -Id $JobId -Settings $Settings

$Response.Content