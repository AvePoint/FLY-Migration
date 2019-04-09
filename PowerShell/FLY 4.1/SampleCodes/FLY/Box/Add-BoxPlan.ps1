$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PolicyId = '<policy id>'
$DatabseId = '<migration database id>'
$BoxConnectionId = '<box connection id>'
$SharePointAccountName = '<sharepoint account name>'

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit>' -Wave '<wave>' -Name '<name>'

$Schedule = New-ScheduleObject -IntervalType OnlyOnce -StartTime ([System.DateTime]::Now).AddMinutes(2).ToString("o")

$PlanSettings = New-BoxPlanSettingsObject -NameLabel $PlanNameLabel -Schedule $Schedule -PolicyId $PolicyId -DatabaseId $DatabseId -MigrateVersions

$Source1 = New-BoxObject -Path '<Box User>' -Level Folder

$Source2 = New-BoxObject -Path '<Box User\Folder>' -Level Folder

$Destination1 = New-BoxMigrationSharePointObject -Url '<sharepoint library url>' -Level Library

$Destination2 = New-BoxMigrationSharePointObject -Url '<sharepoint folder url>' -Level Folder

$MappingContent1 = New-BoxMappingContentObject -Source $Source1 -Destination Destination1 -Method Combine

$MappingContent2 = New-BoxMappingContentObject -Source $Source2 -Destination Destination2 -Method AttachAsChild

$Credential = New-SharePointCredentialObject -AccountName $SharePointAccountName

$Mappings = New-BoxPlanMappingObject -SourceConnectionId $BoxConnectionId -DestinationCredential $Credential -Contents @($MappingContent1, $MappingContent2)

$Plan = New-BoxPlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-BoxPlan -APIKey $ApiKey -BaseUri $BaseUri -PlanSettings $Plan

$Response.Content