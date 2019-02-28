$ApiKey = '<api key>'
$BaseUri = '<base uri>'
$PlanId = '<plan id>'

$Settings = New-PlanExecutionObject -MigrationType Incremental

$serviceResponse = Start-SPJobByPlan -BaseUri $BaseUri -APIKey $ApiKey -Id $PlanId -PlanSettings $Settings

$serviceResponse.Content