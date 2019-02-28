$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'

$SourceAccount = New-AccountObject -Username '<AccountName>' -Password '<AccountPassword>'
$DestinationAccount = New-AccountObject -Username '<AccountName>' -Password '<AccountPassword>' -AppProfile '<AppProfileName?>'

$Source1 = New-FSPathObject -Level Folder -Path '<Path>'
$Destination1 = New-SharePointObject -Level Folder -Url '<FolderUrl>'

$Source2 = New-FSPathObject -Level Folder -Path '<Path>'
$Destination2 = New-SharePointObject -Level Library -Url '<LibraryUrl>'

$MappingContent1 = New-FSMappingContentObject -Source $Source1 -Destination $Destination1

$MappingContent2 = New-FSMappingContentObject -Source $Source2 -Destination $Destination2

$Mappings = New-FSMappingObject -Contents @($MappingContent1, $MappingContent2) -DestinationAccount $DestinationAccount -SourceAccount $SourceAccount

$Schedule = New-ScheduleObject -StartTime '<StartTime>' -IntervalType OnlyOnce

$Settings = New-FSJobExecutionSettingsObject -PolicyId '<PolicyId?>' -MigrationMode HighSpeed -Schedule $Schedule

$JobSettings = New-FSJobExecutionObject -Settings $Settings -Mappings $Mappings

Start-FSJob -APIKey $ApiKey -BaseUri $BaseUri -JobSettings $JobSettings