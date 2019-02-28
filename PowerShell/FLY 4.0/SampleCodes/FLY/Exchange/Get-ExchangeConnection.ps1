$ApiKey = '<api key>'
$BaseUri = '<base uri>'

$Response = Get-ExchangeConnection -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content