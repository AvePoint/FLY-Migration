<#
Code generated by Microsoft (R) PSSwagger 0.3.0
Changes may cause incorrect behavior and will be lost if the code is regenerated.
#>

<#
.SYNOPSIS
    

.DESCRIPTION
    

.PARAMETER MigrationType
    "Full" : Migrate Groups with all of their mailbox and SharePoint data.
"Incremental" : Migrate the changes since the last job.
"TeamsOnly" : Migrate Groups without their mailboxes and SharePoint data.

#>
function New-Office365GroupPlanExecutionObject
{
    param(    
        [Parameter(Mandatory = $true)]
        [ValidateSet('Incremental', 'Full', 'GroupsOnly')]
        [string]
        $MigrationType
    )
    
    $Object = New-Object -TypeName AvePoint.PowerShell.FLYMigration.Models.Office365GroupPlanExecutionModel

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