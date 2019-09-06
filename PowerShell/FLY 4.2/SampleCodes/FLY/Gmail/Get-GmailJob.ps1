$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$Response = Get-GmailJob -APIKey $ApiKey -BaseUri $BaseUri -PageNumber 1 -PageSize 50

$Response.Content.Data