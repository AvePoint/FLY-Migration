function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$Path = Get-ScriptDirectory

$PSSwaggerUtilityModule = Get-Module -ListAvailable -Name PSSwaggerUtility
IF(-not $PSSwaggerUtilityModule){
    $PSGetModule = Get-Module -ListAvailable -Name PowershellGet
    IF($PSGetModule){
        Install-Module -Name PSSwaggerUtility
    }
}

Import-Module -Name (Join-Path -Path $Path -ChildPath 'Modules\FLYMigration')