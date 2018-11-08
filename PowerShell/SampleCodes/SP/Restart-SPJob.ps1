$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$JobId = '<JobId>'

$Settings = New-JobExecutionObject -MigrationType Incremental -IncrementalMigrationScope FailedAndIncremental

$Response = Restart-SPJob -APIKey $ApiKey -BaseUri $BaseUri -Id $JobId -Settings $Settings

$Response.Content.Status