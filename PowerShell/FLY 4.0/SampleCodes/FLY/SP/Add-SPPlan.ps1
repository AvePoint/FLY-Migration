$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$SourceCredential = New-SharePointCredentialObject -AccountName '<account name>' -AppProfileName '<app profile name>'

$DestinationCredential = New-SharePointCredentialObject -AccountName '<account name>' -AppProfileName '<app profile name>'

$Source = New-SharePointObject -Level SiteCollection -Url '<site collection url>'

$Destination = New-SharePointObject -Level SiteCollection -Url '<site collection url>'

$MappingContent = New-SharePointMappingContentObject -Source $Source -Destination $Destination -Method Combine

$Mappings = New-SharePointMappingObject -SourceCredential $SourceCredential -DestinationCredential $DestinationCredential -Contents @($MappingContent)

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit name>' -Wave '<wave name>' -Name '<name>'

$Schedule = New-ScheduleObject -IntervalType OnlyOnce -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')

$PlanSettings = New-SharePointPlanSettingsObject -MigrationMode HighSpeed -DatabaseId '<migration database id>' -PolicyId '<sharepoint migration policy id>' -NameLabel $PlanNameLabel -Schedule $Schedule

$Plan = New-SharePointPlanObject -Settings $PlanSettings -Mappings $Mappings

$response = Add-SPPlan -APIKey $ApiKey -BaseUri $BaseUri -PlanSettings $Plan

$response.Content