<#
Code generated by Microsoft (R) PSSwagger 0.3.0
Changes may cause incorrect behavior and will be lost if the code is regenerated.
#>

<#
.SYNOPSIS
    

.DESCRIPTION
    

.PARAMETER Contents
    

.PARAMETER PstFileConnection
    

.PARAMETER ExchangeConnectionOption
    

#>
function New-PSTFileMappingObject
{
    param(    
        [Parameter(Mandatory = $true)]
        [AvePoint.PowerShell.FLYMigration.Models.PSTFileMappingContentModel[]]
        $Contents,
    
        [Parameter(Mandatory = $true)]
        [AvePoint.PowerShell.FLYMigration.Models.PSTFileConnectionOption]
        $PstFileConnection,
    
        [Parameter(Mandatory = $true)]
        [AvePoint.PowerShell.FLYMigration.Models.ExchangeOnlineConnectionOption]
        $ExchangeConnectionOption
    )
    
    $Object = New-Object -TypeName AvePoint.PowerShell.FLYMigration.Models.PSTFileMappingModel

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