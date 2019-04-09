$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-GmailPlan -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content