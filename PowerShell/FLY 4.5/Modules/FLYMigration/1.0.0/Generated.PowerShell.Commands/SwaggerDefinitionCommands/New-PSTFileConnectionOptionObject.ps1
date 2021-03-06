<#
Code generated by Microsoft (R) PSSwagger 0.3.0
Changes may cause incorrect behavior and will be lost if the code is regenerated.
#>

<#
.SYNOPSIS
    

.DESCRIPTION
    

.PARAMETER Path
    UNC Path

.PARAMETER AdvancedSettings
    

.PARAMETER BasicCredential
    

#>
function New-PSTFileConnectionOptionObject
{
    param(    
        [Parameter(Mandatory = $true)]
        [string]
        $Path,
    
        [Parameter(Mandatory = $false)]
        [AvePoint.PowerShell.FLYMigration.Models.PSTFileConnectionAdvancedSettingsOption]
        $AdvancedSettings,
    
        [Parameter(Mandatory = $false)]
        [AvePoint.PowerShell.FLYMigration.Models.BasicCredential]
        $BasicCredential
    )
    
    $Object = New-Object -TypeName AvePoint.PowerShell.FLYMigration.Models.PSTFileConnectionOption

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
