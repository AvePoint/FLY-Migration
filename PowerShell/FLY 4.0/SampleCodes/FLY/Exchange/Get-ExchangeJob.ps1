$ApiKey = '<api key>'
$BaseUri = '<base uri>'

$Response = Get-ExchangeJob -BaseUri $BaseUri -APIKey $ApiKey -PageNumber 1 -PageSize 50

$Response.Content.Data