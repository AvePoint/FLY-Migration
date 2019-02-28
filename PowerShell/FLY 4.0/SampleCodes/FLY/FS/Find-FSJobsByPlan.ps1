$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PlanId = '<plan id>'

$Response = Find-FSJobsByPlan -BaseUri $BaseUri -APIKey $ApiKey -Id $PlanId -PageNumber 1 -PageSize 50

$Response.Content.Data

