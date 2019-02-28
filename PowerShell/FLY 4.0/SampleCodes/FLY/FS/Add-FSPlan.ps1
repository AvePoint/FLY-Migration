$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$SourceConnectionId = '<file system connection id>'

$DestinationCredential = New-SharePointCredentialObject -AccountName '<account name>' -AppProfileName '<app profile name>'

$Source = New-FSPathObject -Level Folder -Path '<folder path>'

$Destination = New-FSMigrationSharePointObject -Level Library -Url '<library url>'

$MappingContent = New-FSMappingContentObject -Source  $Source -Destination $Destination -Method AttachAsChild

$Mappings = New-FSMappingObject -SourceConnectionId $SourceConnectionId -DestinationCredential $DestinationCredential -Contents @($MappingContent)

$Schedule = New-ScheduleObject -IntervalType OnlyOnce -StartTime ([Datetime]::Now.AddMinutes(2).ToString('o'))

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit name>' -Wave '<wave name>' -Name '<name>'

$PlanSettings = New-FSPlanSettingsObject -MigrationMode HighSpeed -DatabaseId '<migration database id>' -PolicyId '<migration policy id>' -Schedule $Schedule -NameLabel $PlanNameLabel

$Plan = New-FSPlanObject -Settings $PlanSettings -Mappings $Mappings

$ServiceResponse = Add-FSPlan -BaseUri $BaseUri -APIKey $ApiKey -PlanSettings $Plan

$ServiceResponse.Content