$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PlanId = '<plan id>'

$PlanSettings = New-PlanExecutionObject -MigrationType Incremental

$Response = Start-FSJobByPlan -BaseUri $BaseUri -APIKey $ApiKey -Id $PlanId -PlanSettings $PlanSettings

$Response.Content