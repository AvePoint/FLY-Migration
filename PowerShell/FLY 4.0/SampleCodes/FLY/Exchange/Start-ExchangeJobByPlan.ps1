$ApiKey = '<api key>'
$BaseUri = '<base uri>'
$PlanId = '<plan id>'

$Settings = New-ExchangePlanExecutionObject -MigrationType Incremental

$Response = Start-ExchangeJobByPlan -BaseUri $BaseUri -APIKey $ApiKey -PlanId $PlanId -Settings $Settings

$Response.Content