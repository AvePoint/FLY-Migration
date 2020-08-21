
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$Path = Get-ScriptDirectory

$ApiKey = '<api key>'
$BaseUri = '<base url>'

# can fill in  policy id or policy name,example: $policyId = 'policy id or name'
# if policy is not set,please do not modify the following parameters
$Policy = ''

# can fill in  Database id or Database name,example: $DatabaseId = 'DatabaseId id or name'
#if Database is not set,please do not modify the following parameters
$Database=''

# The schedule is an optional parameter
$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')

# The PlanGoups is an optional parameter
# For example: $PlanGoups=@("group1","group2")
$PlanGoups=@()


$CSVFilePath = Join-Path -Path $Path -ChildPath 'PlanCSVs'

$connctions  = Import-Csv -Path $CSVFilePath"\ImportPlanTemplate.csv"

foreach($connection in $connctions)
{
    $Csvs = $connection."Mapping Csv" -split ","

    foreach($csv in $Csvs)
    {
        $mappings = Import-Csv -Path $CSVFilePath"\$csv" -Encoding UTF8

        $PlanNames =  $csv -split "_"


        $PlanNameLabel = New-PlanNameLabelObject -BusinessUnit $PlanNames[0] -Wave $PlanNames[1] -Name $PlanNames[2].Remove($PlanNames[2].IndexOf("."))
        Write-Host($csv)

        $mappngList = @()

        foreach($mapping in $mappings)
        {
            
            $Source = New-MSTeamsObject -Mailbox $mapping."Source Mailbox" -Name "a"
            $Destination = New-MSTeamsObject -Mailbox  $mapping."Destination Mailbox" -Name $mapping."Destination Name"

            $MappingContent = New-MSTeamsMappingContentObject -Source $Source -Destination $Destination

            $mappngList += $MappingContent
        }
       
        $mappings = $MappingContent = New-MSTeamsMappingObject -SourceConnectionId $connection."Source Connection" -DestinationConnectionId $connection."Destination Connection" -Contents $mappngList

        $ConversationSetting = New-ConversationsMigrationSettingsObject -Scope Customization -Duration 12 -DurationUnit Month -Style HTMLFileAndMessages
        
        # If you want to check the checkbox on the fly setting page of the create plan, please add this parameter here. 
        # For example: the following MigrateAsHTML parameter indicates that 'Migrate conversations as HTML' is checked. If you do not want to check, please do not fill in the corresponding parameters.
        # If you do not want to set the Schedule, please remove the '-Schedule $Schedule ' parameter below.
        
        $PlanSettings = New-MSTeamsPlanSettingsObject -NameLabel $PlanNameLabel -PolicyId $Policy -DatabaseId $DatabaseId -Schedule $Schedule -PlanGroups $PlanGoups   -ConversationsMigrationSettings $ConversationSetting -OnlyMigrateDocumentsLibrary  -MigrateMembers -MigrateGroupPlanner  

        $Plan = New-MSTeamsPlanObject -Settings $PlanSettings -Mappings $Mappings

         Try{
            $Response = Add-MicrosoftTeamsPlan -Plan $Plan -BaseUri $BaseUri -APIKey $ApiKey

            $Response.Content
           }
        Catch
           {
            $ErrorMessage = $Error[0].Exception
            Write-Host -ForegroundColor Red $ErrorMessage.Message
            Write-Host -ForegroundColor Red $ErrorMessage.Response.Content
           }
    }

}
