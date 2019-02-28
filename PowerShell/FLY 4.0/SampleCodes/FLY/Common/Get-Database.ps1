$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-Database -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content