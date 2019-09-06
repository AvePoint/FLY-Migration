$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-IMAPPOP3Jobs -APIKey $ApiKey -BaseUri $BaseUri -PageNumber 1 -PageSize 50

$Response.Content.Data