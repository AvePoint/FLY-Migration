$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PlanId = '<Plan Id>'
$Settings = New-PlanExecutionObject -MigrationType Incremental
$Response = Start-IMAPPOP3JobByPlan -BaseUri $BaseUri -APIKey $ApiKey -Id $PlanId -Settings $Settings
$Response.Content