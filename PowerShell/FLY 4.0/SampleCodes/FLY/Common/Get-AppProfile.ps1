$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-AppProfile -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content