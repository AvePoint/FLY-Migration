$ApiKey = '<api key>'
$BaseUri = '<base uri>'

$Response = Get-ExchangePolicy -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content