$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-IMAPPOP3Plan -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content