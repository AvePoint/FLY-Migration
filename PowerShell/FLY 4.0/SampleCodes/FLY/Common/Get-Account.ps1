$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-Account -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content