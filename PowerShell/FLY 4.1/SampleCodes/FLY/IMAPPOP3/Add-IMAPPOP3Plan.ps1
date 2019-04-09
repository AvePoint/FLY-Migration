$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PolicyId = '<policy id>'
$DatabseId = '<migration database id>'
$ExchangeConnectionId = '<exchange connection id>'

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit>' -Wave '<wave>' -Name '<name>'

$Schedule = New-ScheduleObject -IntervalType OnlyOnce -StartTime ([System.DateTime]::Now).AddMinutes(2).ToString("o")

$PlanSettings = New-IMAPPOP3PlanSettingsObject -NameLabel $PlanNameLabel -Schedule $Schedule -PolicyId $PolicyId -DatabaseId $DatabseId -SynchronizeDeletion

$SourceConnection = New-IMAPPOP3ConnectionObject -Type Outlook -ServerName 'imap-mail.outlook.com' -Port 993 -EnableSSL

$Source1 = New-IMAPPOP3MailBoxObject -Mailbox '<outlook mailbox>' -Password '<password>'
$Source2 = New-IMAPPOP3MailBoxObject -Mailbox '<outlook mailbox>' -Password '<password>'

$MappingContent1 = New-IMAPPOP3MappingContentObject -Source $Source1 -DestinationMailbox '<exchange mailbox>' -MigrateArchivedMailboxOrFolder
$MappingContent2 = New-IMAPPOP3MappingContentObject -Source $Source2 -DestinationMailbox '<exchange mailbox>' -MigrateArchivedMailboxOrFolder

$Mappings = New-IMAPPOP3MappingObject -Source $SourceConnection -DestinationConnectionId $ExchangeConnectionId -Contents @($MappingContent1, $MappingContent2)

$Plan = New-IMAPPOP3PlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-IMAPPOP3Plan -APIKey $ApiKey -BaseUri $BaseUri -Plan $Plan

$Response.Content