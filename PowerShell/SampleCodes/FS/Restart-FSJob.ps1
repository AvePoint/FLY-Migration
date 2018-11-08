$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$JobId = '<JobId>'

$Settings = New-JobExecutionObject -MigrationType Incremental -IncrementalMigrationScope FailedAndIncremental

$Response = Restart-FSJob -APIKey $ApiKey -BaseUri $BaseUri -Setting $Settings -Id $JobId

$Response.Content.Status