<#
Code generated by Microsoft (R) PSSwagger 0.3.0
Changes may cause incorrect behavior and will be lost if the code is regenerated.
#>

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

# If the user supplied -Prefix to Import-Module, that applies to the nested module as well
# Force import the nested module again without -Prefix
if (-not (Get-Command Get-OperatingSystemInfo -Module PSSwaggerUtility -ErrorAction Ignore)) {
    Import-Module PSSwaggerUtility -Force
}

if ((Get-OperatingSystemInfo).IsCore) {
    $clr = 'coreclr'
}
else {
    $clr = 'fullclr'
}

$ClrPath = Join-Path -Path $PSScriptRoot -ChildPath 'ref' | Join-Path -ChildPath $clr
$dllFullName = Join-Path -Path $ClrPath -ChildPath 'Microsoft.PowerShell.FLYMigration.v001.dll'
if(-not (Test-Path -Path $dllFullName -PathType Leaf)) {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'AssemblyGenerationHelpers.ps1')
    New-SDKAssembly -AssemblyFileName 'Microsoft.PowerShell.FLYMigration.v001.dll' -IsAzureSDK:$False
}
$allDllsPath = Join-Path -Path $ClrPath -ChildPath '*.dll'
if (Test-Path -Path $ClrPath -PathType Container) {
    Get-ChildItem -Path $allDllsPath -File | ForEach-Object { Add-Type -Path $_.FullName -ErrorAction SilentlyContinue }
}

. (Join-Path -Path $PSScriptRoot -ChildPath 'New-ServiceClient.ps1')

$allPs1FilesPath = Join-Path -Path $PSScriptRoot -ChildPath 'Generated.PowerShell.Commands' | Join-Path -ChildPath '*.ps1'
Get-ChildItem -Path $allPs1FilesPath -Recurse -File | ForEach-Object { . $_.FullName}
