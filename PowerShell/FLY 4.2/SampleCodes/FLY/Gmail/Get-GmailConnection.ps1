$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-GmailConnection -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content