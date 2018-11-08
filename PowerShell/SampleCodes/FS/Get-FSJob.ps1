$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-FSJob -APIKey $ApiKey -BaseUri $BaseUri

$Response.Content.Data