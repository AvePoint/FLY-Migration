$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PlanId = '<Plan Id>'
$Response = Find-GmailJobsByPlan -APIKey $ApiKey -BaseUri $BaseUri -Id $PlanId -PageNumber 1 -PageSize 50

$Response.Content.Data