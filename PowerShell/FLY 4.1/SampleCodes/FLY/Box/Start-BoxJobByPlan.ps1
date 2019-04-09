$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PlanId = '<Plan Id>'
$Settings = New-PlanExecutionObject -MigrationType Incremental
$Response = Start-BoxJobByPlan -BaseUri $BaseUri -APIKey $ApiKey -Id $PlanId -PlanSettings $Settings
$Response.Content