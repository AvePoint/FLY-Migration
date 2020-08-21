
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

function CheckData($data)
{
    if($data.length -eq 0)
    {
        return ""
    }
    return $data
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

    $sourceAccount = CheckData -data $connection."Source Account Name"
    $sourceProfile = CheckData -data $connection."Source Profile Name"
    
    $destAccount =  CheckData -data $connection."Dest Account Name"
    $destProfile =  CheckData -data $connection."Dest Profile Name"

    $SourceCredential = New-SharePointCredentialObject -AccountName $sourceAccount -AppProfileName $sourceProfile

    $DestinationCredential = New-SharePointCredentialObject -AccountName $destAccount -AppProfileName $destProfile

    foreach($csv in $Csvs)
    {
        $mappings = Import-Csv -Path $CSVFilePath"\$csv" -Encoding UTF8

        $PlanNames =  $csv -split "_"

        $PlanNameLabel = New-PlanNameLabelObject -BusinessUnit $PlanNames[0] -Wave $PlanNames[1] -Name $PlanNames[2].Remove($PlanNames[2].IndexOf("."))

        $mappngList = @()

        foreach($mapping in $mappings)
        {
            $Source = New-SharePointObject -Level $mapping."Source Level" -Url $mapping."Source Url"

            $Destination = New-SharePointObject -Level $mapping."Dest Level" -Url $mapping."Dest Url"

            $MappingContent = New-SharePointMappingContentObject -Source $Source -Destination $Destination -Method $mapping."Mapping Method"

            $mappngList += $MappingContent
        }
       
        $Mappings = New-SharePointMappingObject -SourceCredential $SourceCredential -DestinationCredential $DestinationCredential -Contents $mappngList
        
        # If you want to check the checkbox on the fly setting page of the create plan, please add this parameter here. 
        # For example: the following MigrateAsHTML parameter indicates that 'Migrate conversations as HTML' is checked. If you do not want to check, please do not fill in the corresponding parameters.
        # If you do not want to set the Schedule, please remove the '-Schedule $Schedule ' parameter below.
        
        $PlanSettings = New-SharePointPlanSettingsObject -MigrationMode HighSpeed -DatabaseId $Database -PolicyId $Policy -NameLabel $PlanNameLabel -Schedule $Schedule -PlanGroups $PlanGoups

        $Plan = New-SharePointPlanObject -Settings $PlanSettings -Mappings $Mappings

         Try{
            $Response = Add-SPPlan -APIKey $ApiKey -BaseUri $BaseUri -PlanSettings $Plan

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
