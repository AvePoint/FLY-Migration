$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-BoxConnection -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content