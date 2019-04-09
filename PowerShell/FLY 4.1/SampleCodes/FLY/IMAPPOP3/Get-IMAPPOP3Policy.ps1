$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-IMAPPOP3Policy -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content