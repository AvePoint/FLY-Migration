
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

function Set-connection ([string]$id,[bool]$isOnlie)
{
    if($isOnlie -eq $true)
    {
       $result =  New-ExchangeOnlineConnectionOptionObject -ConnectionId $id
       return  New-ExchangeConnectionObject -OnlineConnectionOption $result
    }else
    {
        $result = New-ExchangeOnPremisesConnectionOptionObject -ConnectionId $id
        return New-ExchangeConnectionObject  -OnPremisesConnectionOption $result
    }
}

function Set-connectionType([string] $type)
{
    if($type -eq "Online"){
        return $true
    }
    return $false
}

$Path = Get-ScriptDirectory


$ApiKey = '<api key>'
$BaseUri = '<base url>'



$CSVFilePath = Join-Path -Path $Path -ChildPath 'PlanCSVs'

$CSVFiles = Get-ChildItem $CSVFilePath
$connctions  = Import-Csv -Path $CSVFilePath"\ImportPlanTemplate.csv"

# The schedule is an optional parameter
$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')

# The PlanGoups is an optional parameter
# For example: $PlanGoups=@("group1","group2")
$PlanGoups=@()

# can fill in  policy id or policy name,example: $policyId = 'policy id or name'
# if policy is not set,please do not modify the following parameters
$Policy = ''

# can fill in  Database id or Database name,example: $DatabaseId = 'DatabaseId id or name'
#if Database is not set,please do not modify the following parameters
$Database=''


foreach($connection in $connctions)
{
   $sourConnectionType = Set-connectionType -type $connection."Source Type"
   $destConnectionType = Set-connectionType -type $connection."Destination Type"

   $sourceConnection = Set-connection -id $connection."Source Connection" -isOnlie $sourConnectionType
   $destConnection = Set-connection -id $connection."Destination Connection" -isOnlie $destConnectionType
   

   $Csvs = $connection."Mapping Csv" -split ","
   
   foreach($csv in $Csvs)
   {
     $mappings = Import-Csv -Path $CSVFilePath"\$csv" -Encoding UTF8


     $PlanNames =  $csv -split "_"
     $PlanNameLabel = New-PlanNameLabelObject -BusinessUnit $PlanNames[0] -Wave $PlanNames[1] -Name $PlanNames[2].Remove($PlanNames[2].IndexOf("."))

     $mappngList = @()


    foreach($mapping in $mappings)
    {
        $Source = New-ExchangeMailboxObject -Mailbox $mapping."Source Email Address" -MailboxType $mapping."Source Type"

        $Destination = New-ExchangeMailboxObject -Mailbox  $mapping."Destination Email Address" -MailboxType $mapping."Destination Type"

        $MigrateArchive = $false

        $MigrateRecoverable = $false

        if($mapping."Migrate Archived Mailboxes" -eq "true")
        {
            $MigrateArchive = $true

        }
        if($mapping."Migrate Recoverable Item Folder" -eq "true")
        {
            $MigrateRecoverable = $true

        }
        if($mapping."Convert To Shared Mailbox" -eq "true"){
            $MigrateSharedMailbox = $true
        } 
        $MappingContent = New-ExchangeMappingContentObject -Source $Source -Destination $Destination -MigrateArchivedMailboxOrFolder:$MigrateArchive -MigrateRecoverableItemsFolder:$MigrateRecoverable -ConvertToSharedMailbox:$MigrateSharedMailbox

        $mappngList += $MappingContent
    }
    $Mappings = New-ExchangeMappingObject -Source $sourceConnection -Destination $destConnection -Contents @($mappngList)

    # If you want to check the checkbox on the fly setting page of the create plan, please add this parameter here. 
    # For example: the following SynchronizeDeletion parameter indicates that SynchronizeDeletion is checked. If you do not want to check, please do not fill in the corresponding parameters.
    # If you do not want to set the Schedule, please remove the '-Schedule $Schedule ' parameter below.

    $PlanSettings = New-ExchangePlanSettingsObject -NameLabel $PlanNameLabel -PolicyId $Policy -DatabaseId $Database  -PlanGroups $PlanGoups -Schedule $Schedule -MigrateMailboxRules -MigrateMailboxPermissions -SynchronizeDeletion -MigrateAutoCompleteList -MigrateContacts

    $Plan = New-ExchangePlanObject -Settings $PlanSettings -Mappings $Mappings

      try
    {
    
        $Response = Add-ExchangePlan -Plan $Plan -BaseUri $BaseUri -APIKey $ApiKey

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

