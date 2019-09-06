$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PolicyId = '<policy id>'
$DatabseId = '<migration database id>'
$GmailConnectionId = '<gmail connection id>'
$ExchangeConnectionId = '<exchange connection id>'

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit>' -Wave '<wave>' -Name '<name>'

$Schedule = New-ScheduleObject -IntervalType OnlyOnce -StartTime ([System.DateTime]::Now).AddMinutes(2).ToString("o")

$PlanSettings = New-GmailPlanSettingsObject -NameLabel $PlanNameLabel -Schedule $Schedule -PolicyId $PolicyId -DatabaseId $DatabseId -SynchronizeDeletion

$Destination1 = New-GmailMigrationExchangeMailboxObject -Mailbox '<exchange mailbox>' -MailboxType UserMailbox

$Destination2 = New-GmailMigrationExchangeMailboxObject -Mailbox '<exchange mailbox>' -MailboxType ArchivedMailbox

$MappingContent1 = New-GmailMappingContentObject -Mailbox '<gmail mailbox>' -Destination $Destination1 -MigrateArchivedMailboxOrFolder

$MappingContent2 = New-GmailMappingContentObject -Mailbox '<gmail mailbox>' -Destination $Destination2 -MigrateArchivedMailboxOrFolder

$Mappings = New-GmailMappingObject -SourceConnectionId $GmailConnectionId -DestinationConnectionId $ExchangeConnectionId -Contents @($MappingContent1, $MappingContent2)

$Plan = New-GmailPlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-GmailPlan -APIKey $ApiKey -BaseUri $BaseUri -Plan $Plan

$Response.Content