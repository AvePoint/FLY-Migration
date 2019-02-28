function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$Path = Get-ScriptDirectory

Import-Module -Name (Join-Path -Path $Path -ChildPath 'Modules\FLYMigration')