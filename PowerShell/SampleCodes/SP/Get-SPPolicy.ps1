$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-SPPolicy -APIKey $ApiKey -BaseUri $BaseUri

$Response.Content