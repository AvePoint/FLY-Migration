$ApiKey = '<api key>'
$BaseUri = '<base uri>'

$serviceResponse = Get-SPPlan -BaseUri $BaseUri -APIKey $ApiKey

$serviceResponse.Content