$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-FSConnection -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content