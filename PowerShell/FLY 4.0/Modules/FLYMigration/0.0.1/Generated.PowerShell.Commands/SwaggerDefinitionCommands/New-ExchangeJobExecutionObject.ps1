<#
Code generated by Microsoft (R) PSSwagger 0.3.0
Changes may cause incorrect behavior and will be lost if the code is regenerated.
#>

<#
.SYNOPSIS
    

.DESCRIPTION
    

.PARAMETER StartTime
    

.PARAMETER MigrationType
    

#>
function New-ExchangeJobExecutionObject
{
    param(    
        [Parameter(Mandatory = $false)]
        [string]
        $StartTime,
    
        [Parameter(Mandatory = $true)]
        [ValidateSet('Incremental', 'Full')]
        [string]
        $MigrationType
    )
    
    $Object = New-Object -TypeName AvePoint.PowerShell.FLYMigration.Models.ExchangeJobExecutionModel

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
