$ApiKey = '<api key>'
$BaseUri = '<base uri>'

$SourceConnectionId = '<exchange migration connection id>'

$DestinationConnectionId  = '<exchange migration connection id>'

$Source = New-ExchangeMailboxObject -Mailbox '<mailbox address>' -MailboxType UserMailbox

$Destination = New-ExchangeMailboxObject -Mailbox '<mailbox address>' -MailboxType UserMailbox

$MappingContent = New-ExchangeMappingContentObject -Source $Source -Destination $Destination -MigrateArchivedMailboxOrFolder -MigrateRecoverableItemsFolder

$Mappings = New-ExchangeMappingObject -SourceConnectionId $SourceConnectionId -DestinationConnectionId $DestinationConnectionId -Contents @($MappingContent)

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit name>' -Wave '<wave name>' -Name '<name>'

$Schedule = New-ScheduleObject -IntervalType OnlyOnce -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')

$PlanSettings = New-ExchangePlanSettingsObject -NameLabel $PlanNameLabel -PolicyId '<migration policy id>' -DatabaseId '<migration database id>' -Schedule $Schedule -MigrateMailboxRules -SynchronizeDeletion -MigrateDistributionGroups -MigratePublicFolders -MigrateMailboxPermissions -MigrateContacts

$Plan = New-ExchangePlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-ExchangePlan -Plan $Plan -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content