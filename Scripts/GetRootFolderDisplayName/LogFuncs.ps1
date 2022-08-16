<# /********************************************************************
 *
 *  PROPRIETARY and CONFIDENTIAL
 *
 *  This file is licensed from, and is a trade secret of:
 *
 *                   AvePoint, Inc.
 *                   525 Washington Blvd, Suite 1400
 *                   Jersey City, NJ 07310
 *                   United States of America
 *                   Telephone: +1-201-793-1111
 *                   WWW: www.avepoint.com
 *
 *  Refer to your License Agreement for restrictions on use,
 *  duplication, or disclosure.
 *
 *  RESTRICTED RIGHTS LEGEND
 *
 *  Use, duplication, or disclosure by the Government is
 *  subject to restrictions as set forth in subdivision
 *  (c)(1)(ii) of the Rights in Technical Data and Computer
 *  Software clause at DFARS 252.227-7013 (Oct. 1988) and
 *  FAR 52.227-19 (C) (June 1987).
 *
 *  Copyright © 2017-2022 AvePoint® Inc. All Rights Reserved.
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>
#-------------Log Functions--------------#
#-------------Log Functions--------------#
$Global:LogPath = [String]::Empty
$Global:LogName = [String]::Empty

Function Log-Initialize
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$path,

        [Parameter(Mandatory=$true)]
        [string]$name
    )
    
    $Global:LogPath = $path
    $Global:LogName = $name

    if(!(Test-Path -Path $path)){
        New-Item $path -ItemType Directory
    }
}

Function Log-Message
{
    Param
    (
        [Parameter(Mandatory=$false)]
        [string]$path,

        [Parameter(Mandatory=$false)]
        [string]$name,

        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    $LogFile = $path + "\" + $name

    Add-Content -Path $LogFile -Value "[$([DateTime]::Now)] $Message" -Encoding UTF8
}

Function Log-Info
{
    Param
    (

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$ScriptName,

        [Parameter(Mandatory=$false)]
        [object]$BackgroundColor,

        [Parameter(Mandatory=$false)]
        [object]$ForegroundColor,

        [Parameter(Mandatory=$false)]
        [boolean]$ConsoleInfo = $true
    )

    if($ScriptName){
        if(![system.diagnostics.eventlog]::SourceExists($ScriptName)){
            New-EventLog -LogName AvePoint -Source $ScriptName
        }
        Write-EventLog -LogName AvePoint -Source $ScriptName -EntryType Information -EventId 5000 -Message "[$Global:LogName]$Message"
    }
    if($ConsoleInfo){
        Write-Host "Info: $Message" -BackgroundColor Black -ForegroundColor White
    }
    
    if(![string]::IsNullOrEmpty($Global:LogPath) -and ![string]::IsNullOrEmpty($Global:LogName)){
        Log-Message $Global:LogPath $Global:LogName "Info: $Message"
    }
}

Function Log-Debug
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$ScriptName,

        [Parameter(Mandatory=$false)]
        [boolean]$ConsoleInfo = $true
    )

    if($ScriptName){
        if(![system.diagnostics.eventlog]::SourceExists($ScriptName)){
            New-EventLog -LogName AvePoint -Source $ScriptName
        }
        Write-EventLog -LogName AvePoint -Source $ScriptName -EntryType Information -EventId 5000 -Message "[$Global:LogName]$Message"
    }
    if($ConsoleInfo){
        Write-Host "Debug: $Message" -BackgroundColor Gray -ForegroundColor Black
    }
    
    if(![string]::IsNullOrEmpty($Global:LogPath) -and ![string]::IsNullOrEmpty($Global:LogName)){
        Log-Message $Global:LogPath $Global:LogName "Debug: $Message"
    }
}

Function Log-Error
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$ScriptName,

        [Parameter(Mandatory=$false)]
        [boolean]$ConsoleInfo = $true
    )

    if($ScriptName){
        if(![system.diagnostics.eventlog]::SourceExists($ScriptName)){
            New-EventLog -LogName AvePoint -Source $ScriptName
        }
        Write-EventLog -LogName AvePoint -Source $ScriptName -EntryType Error -EventId 5000 -Message "[$Global:LogName]$Message"
    }
    if($ConsoleInfo){
        Write-Host "Error: $Message" -BackgroundColor Red -ForegroundColor White
    }
    if(![string]::IsNullOrEmpty($Global:LogPath) -and ![string]::IsNullOrEmpty($Global:LogName)){
        Log-Message $Global:LogPath $Global:LogName "Error: $Message"
    }
}

Function Log-Warning
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$ScriptName,

        [Parameter(Mandatory=$false)]
        [boolean]$ConsoleInfo = $true
    )

    if($ScriptName){
        if(![system.diagnostics.eventlog]::SourceExists($ScriptName)){
            New-EventLog -LogName AvePoint -Source $ScriptName
        }
        Write-EventLog -LogName AvePoint -Source $ScriptName -EntryType Warning -EventId 5000 -Message "[$Global:LogName]$Message"
    }
    if($ConsoleInfo){
        Write-Host "Warning: $Message" -BackgroundColor Yellow -ForegroundColor Magenta
    }
    if(![string]::IsNullOrEmpty($Global:LogPath) -and ![string]::IsNullOrEmpty($Global:LogName)){
        Log-Message $Global:LogPath $Global:LogName "Warning: $Message"
    }
}

#-------------Log Functions--------------#