$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-FSPlan -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content