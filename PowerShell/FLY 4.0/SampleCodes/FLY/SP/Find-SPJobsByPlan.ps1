$ApiKey = '<api key>'
$BaseUri = '<base uri>'
$planId = '<plan id>'

$serviceResponse = Find-SPJobsByPlan -APIKey $ApiKey -BaseUri $BaseUri -Id $planId -PageNumber 1 -PageSize 50

$serviceResponse.Content.Data