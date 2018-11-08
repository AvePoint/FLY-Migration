$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-FSPolicy -APIKey $ApiKey -BaseUri $BaseUri

$Response.Content