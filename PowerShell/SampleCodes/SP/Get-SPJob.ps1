$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-SPJob -APIKey $ApiKey -BaseUri $BaseUri

$Response.Content.Data