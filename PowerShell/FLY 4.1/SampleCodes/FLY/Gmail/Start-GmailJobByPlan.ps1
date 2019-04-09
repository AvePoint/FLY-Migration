$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PlanId = '<Plan Id>'
$Settings = New-PlanExecutionObject -MigrationType Incremental
$Response = Start-GmailJobByPlan -BaseUri $BaseUri -APIKey $ApiKey -Id $PlanId -Settings $Settings
$Response.Content