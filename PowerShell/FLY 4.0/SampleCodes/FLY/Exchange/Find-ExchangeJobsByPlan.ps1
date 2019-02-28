$ApiKey = '<api key>'
$BaseUri = '<base uri>'
$PlanId = '<plan id>'

$Response = Find-ExchangeJobsByPlan -BaseUri $BaseUri -APIKey $ApiKey -Id $PlanId -PageNumber 1 -PageSize 50

$Response.Content.Data