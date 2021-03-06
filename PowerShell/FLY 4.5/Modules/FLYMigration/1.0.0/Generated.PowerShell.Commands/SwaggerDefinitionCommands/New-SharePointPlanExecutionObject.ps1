<#
Code generated by Microsoft (R) PSSwagger 0.3.0
Changes may cause incorrect behavior and will be lost if the code is regenerated.
#>

<#
.SYNOPSIS
    

.DESCRIPTION
    

.PARAMETER MigrationType
    

#>
function New-SharePointPlanExecutionObject
{
    param(    
        [Parameter(Mandatory = $true)]
        [ValidateSet('Incremental', 'Full', 'FailedObjectsOnly', 'PermissionOnly')]
        [string]
        $MigrationType
    )
    
    $Object = New-Object -TypeName AvePoint.PowerShell.FLYMigration.Models.SharePointPlanExecutionModel

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
