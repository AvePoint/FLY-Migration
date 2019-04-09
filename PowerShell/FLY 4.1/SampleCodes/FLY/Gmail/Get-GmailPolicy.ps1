$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-GmailPolicy -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content