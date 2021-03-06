<#
Code generated by Microsoft (R) PSSwagger 0.3.0
Changes may cause incorrect behavior and will be lost if the code is regenerated.
#>

<#
.SYNOPSIS
    

.DESCRIPTION
    

.PARAMETER MigrationMode
    

.PARAMETER DatabaseId
    the id of migration database

.PARAMETER Schedule
    the schedule for the migration

.PARAMETER PolicyId
    the id of migration policy

.PARAMETER NameLabel
    Large migration projects are often phased over several waves, each containing multiple plans. 
To easily generate migration reports for each project or wave, we recommend the Example name format Business Unit_Wave_Plan

#>
function New-FSPlanSettingsObject
{
    param(    
        [Parameter(Mandatory = $false)]
        [ValidateSet('HighSpeed', 'CSOM')]
        [string]
        $MigrationMode,
    
        [Parameter(Mandatory = $false)]
        [string]
        $DatabaseId,
    
        [Parameter(Mandatory = $false)]
        [AvePoint.PowerShell.FLYMigration.Models.ScheduleModel]
        $Schedule,
    
        [Parameter(Mandatory = $false)]
        [string]
        $PolicyId,
    
        [Parameter(Mandatory = $true)]
        [AvePoint.PowerShell.FLYMigration.Models.PlanNameLabel]
        $NameLabel
    )
    
    $Object = New-Object -TypeName AvePoint.PowerShell.FLYMigration.Models.FSPlanSettingsModel

    $PSBoundParameters.GetEnumerator() | ForEach-Object { 
        if(Get-Member -InputObject $Object -Name $_.Key -MemberType Property)
        {
            $Object.$($_.Key) = $_.Value
        }
    }

    if(Get-Member -InputObject $Object -Name Validate -MemberType Method)
    {
        $Object.Validate()
    }

    return $Object
}
