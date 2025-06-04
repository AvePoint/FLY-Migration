<# /********************************************************************
 *
 *  PROPRIETARY and CONFIDENTIAL
 *
 *  This file is licensed from, and is a trade secret of:
 *
 *                   AvePoint, Inc.
 *                   525 Washington Blvd, Suite 1400
 *                   Jersey City, NJ 07311
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
 *  Copyright © 2017-2024 AvePoint® Inc. All Rights Reserved.
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>

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
$dllFullName = Join-Path -Path $ClrPath -ChildPath 'AvePoint.PowerShell.FLYMigration.dll'
if(-not (Test-Path -Path $dllFullName -PathType Leaf)) {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'AssemblyGenerationHelpers.ps1')
    New-SDKAssembly -AssemblyFileName 'AvePoint.PowerShell.FLYMigration.dll' -IsAzureSDK:$False
}
$allDllsPath = Join-Path -Path $ClrPath -ChildPath '*.dll'
if (Test-Path -Path $ClrPath -PathType Container) {
    Get-ChildItem -Path $allDllsPath -File | ForEach-Object { Add-Type -Path $_.FullName -ErrorAction SilentlyContinue }
}

. (Join-Path -Path $PSScriptRoot -ChildPath 'New-ServiceClient.ps1')

$allPs1FilesPath = Join-Path -Path $PSScriptRoot -ChildPath 'Generated.PowerShell.Commands' | Join-Path -ChildPath '*.ps1'
Get-ChildItem -Path $allPs1FilesPath -Recurse -File | ForEach-Object { . $_.FullName}
