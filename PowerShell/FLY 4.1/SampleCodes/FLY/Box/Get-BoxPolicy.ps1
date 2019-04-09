$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-BoxPolicy -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content