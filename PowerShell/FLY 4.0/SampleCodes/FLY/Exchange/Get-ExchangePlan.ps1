$ApiKey = '<api key>'
$BaseUri = '<base uri>'

$Response = Get-ExchangePlan -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content