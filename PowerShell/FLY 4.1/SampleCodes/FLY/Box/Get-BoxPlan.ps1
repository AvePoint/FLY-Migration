$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-BoxPlan -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content