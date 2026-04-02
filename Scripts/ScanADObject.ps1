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
 *  Copyright © 2017-2026 AvePoint® Inc. All Rights Reserved.
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>
<#
.SYNOPSIS
    Multi-object Active Directory scanner with modular function architecture.

.DESCRIPTION
    Scans multiple AD object types (Users, Groups, Contacts, Computers)
    Each function handles specific responsibilities following separation of concerns.

.PARAMETER
    OutputPath: The local path to store output data. Required

    ObjectTypes: The object type should be scan. Default: All
        Exmaple: -ObjectTypes User, Group

    IncludeMapping: Option to export the Import mapping file(use for import mapping in Fly). Default: $true
        Exmaple: -IncludeMapping $false

    Extention: Option to set output file extention (csv or xlsx). Default: csv
        Exmaple: -Extention xlsx

.EXAMPLE
    .\ScanADObject.ps1 -OutputPath "C:\Users\***\Output"
    Scans all AD object types and exports to separate Exel files

.NOTES
    Author: AvePoint Fly Migration - AD Assistant
    Date: 2026-02-09
    Compatible: PowerShell 5.1+ and 7.x
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('User', 'Group', 'Contact', 'Computer', 'All')]
    [string[]]$ObjectTypes = @('All'),
    
    [Parameter(Mandatory = $false)]
    [bool]$IncludeMapping = $true,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('csv', 'xlsx')]
    [string]$Extention = "csv"
)

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

#region Configuration
$script:Config = @{
    OutputPath = $OutputPath
    Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Domain = $null
    ScanResults = @{}
}

# Define common properties (shared across all AD objects)
$script:CommonProperties = @(
    'distinguishedName', 'name', 'objectGUID', 'description', 'displayName', 'instanceType', 'nTSecurityDescriptor', 
    'dSCorePropagationData', 'objectCategory', 'whenCreated', 'uSNCreated', 'whenChanged', 'uSNChanged'
)

# Define object type configurations (mimics PluginBuilder pattern)
$script:ObjectTypeConfigs = @(
    @{
        Name = 'User'
        Filter = '*'
        Properties = $script:CommonProperties + @(
            'accountExpires', 'badPasswordTime', 'badPwdCount', 'c', 'co', 'cn', 'company', 'countryCode', 'codePage', 'department', 
            'division', 'facsimileTelephoneNumber', 'givenName', 'homePhone', 'info', 'l', 'lastLogoff', 'lastLogon', 'lockoutTime', 
            'logonCount', 'mail', 'managedObjects', 'manager', 'memberOf', 'msTSProperty01', 'msTSWorkDirectory', 'objectClass', 
            'objectSid', 'otherHomePhone', 'otherMobile', 'otherFacsimileTelephoneNumber', 'otherIpPhone', 'otherPager', 'pager', 
            'physicalDeliveryOfficeName', 'postOfficeBox', 'postalCode', 'primaryGroupID', 'pwdLastSet', 'sAMAccountName', 'sAMAccountType', 
            'sn', 'st', 'street', 'streetAddress', 'telephoneNumber', 'title', 'url', 'userAccountControl', 'unixUserPassword', 
            'userPassword', 'unicodePwd', 'userPrincipalName', 'userWorkstations', 'wWWHomePage', 'initials'
        )
        Command = 'Get-ADUser'
        Converter = 'ConvertTo-UserExport'
    },
    @{
        Name = 'Group'
        Filter = '*'
        Properties = $script:CommonProperties + @(
            'cn', 'groupType', 'info', 'mail', 'managedBy', 'member', 'objectSID', 'sAMAccountName', 'sAMAccountType'
        )
        Command = 'Get-ADGroup'
        Converter = 'ConvertTo-GroupExport'
    },
    @{
        Name = 'Contact'
        Filter = "objectClass -eq 'contact'"
        Properties = $script:CommonProperties + @(
            'cn', 'c', 'co', 'company', 'countryCode', 'department', 'givenName', 'homePhone', 'l', 'mail', 
            'manager', 'memberOf', 'mobile', 'objectClass', 'physicalDeliveryOfficeName', 'postalCode', 
            'postOfficeBox', 'sn', 'st', 'street', 'streetAddress', 'telephoneNumber', 'title', 'wWWHomePage', 'initials'
        )
        Command = 'Get-ADObject'
        Converter = 'ConvertTo-ContactExport'
    },
    @{
        Name = 'Computer'
        Filter = '*'
        Properties = $script:CommonProperties + @(
            'cn', 'dNSHostName', 'objectSID', 'sAMAccountName', 'operatingSystem', 'operatingSystemVersion', 'lastLogonTimestamp', 
            'pwdLastSet', 'userAccountControl', 'servicePrincipalName', 'location', 'managedBy'
        )
        Command = 'Get-ADComputer'
        Converter = 'ConvertTo-ComputerExport'
    }
)
#endregion

#region Module Management (mimics dependency validation)
function Initialize-ADModule {
    <#
    .SYNOPSIS
        Validates and imports ActiveDirectory module (BeforeAnalyze hook pattern)
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Checking required modules..." -ForegroundColor Cyan
    
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] ActiveDirectory module not found!" -ForegroundColor Red
        Write-Host "`nInstallation Instructions:" -ForegroundColor Yellow
        Write-Host "  Windows 10/11:" -ForegroundColor White
        Write-Host "    Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0" -ForegroundColor Gray
        Write-Host "  Windows Server:" -ForegroundColor White
        Write-Host "    Install-WindowsFeature RSAT-AD-PowerShell" -ForegroundColor Gray
        return $false
    }
    
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] ActiveDirectory module loaded" -ForegroundColor Green
    
    # Check ImportExcel module
    if ($Extention -eq 'csv') {
    }
    else {
        if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] ImportExcel module not found!" -ForegroundColor Red
            Write-Host "`nInstallation Instructions:" -ForegroundColor Yellow
            Write-Host "  Install from PowerShell Gallery:" -ForegroundColor White
            Write-Host "    Install-Module -Name ImportExcel -Scope CurrentUser" -ForegroundColor Gray
            Write-Host "  Or with admin rights:" -ForegroundColor White
            Write-Host "    Install-Module -Name ImportExcel -Scope AllUsers" -ForegroundColor Gray
            return $false
        }
        
        Import-Module ImportExcel -ErrorAction Stop
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] ImportExcel module loaded" -ForegroundColor Green
    }
    return $true
}

function Test-ADConnectivity {
    <#
    .SYNOPSIS
        Validates AD connectivity and stores domain context (authentication pattern)
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Validating AD connectivity..." -ForegroundColor Cyan
    
    try {
        $domain = Get-ADDomain -ErrorAction Stop
        $dc = Get-ADDomainController -Discover -ErrorAction Stop
        
        $script:Config.Domain = @{
            DNSRoot = $domain.DNSRoot
            DomainController = $dc.HostName
            Forest = $domain.Forest
            DomainMode = $domain.DomainMode
        }
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Connected to: $($domain.DNSRoot)" -ForegroundColor Green
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] DC: $($dc.HostName)" -ForegroundColor White
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] User: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -ForegroundColor White
        
        return $true
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to connect: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}
#endregion

#region Data Collection (mimics AbstractAnalyzeService pattern)
function Invoke-ADObjectScan {
    <#
    .SYNOPSIS
        Executes AD query for specific object type (AfterAnalyze hook pattern)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ObjectConfig
    )
    
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] [INFO] Scanning $($ObjectConfig.Name) objects..." -ForegroundColor Cyan
    $startTime = Get-Date
    
    try {
        # Build query parameters
        $params = @{
            Properties = $ObjectConfig.Properties
            ErrorAction = 'Stop'
        }
        
        # Execute appropriate command based on object type
        $objects = switch ($ObjectConfig.Command) {
            'Get-ADUser' {
                $params['Filter'] = $ObjectConfig.Filter
                Get-ADUser @params | Select-Object $ObjectConfig.Properties
            }
            'Get-ADGroup' {
                $params['Filter'] = $ObjectConfig.Filter
                Get-ADGroup @params | Select-Object $ObjectConfig.Properties
            }
            'Get-ADComputer' {
                $params['Filter'] = $ObjectConfig.Filter
                Get-ADComputer @params | Select-Object $ObjectConfig.Properties
            }
            'Get-ADObject' {
                $params['Filter'] = $ObjectConfig.Filter
                Get-ADObject @params | Select-Object $ObjectConfig.Properties
            }
        }
        
        $duration = (Get-Date) - $startTime
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Retrieved $($objects.Count) objects in $($duration.TotalSeconds)s" -ForegroundColor Green
        
        return $objects
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Scan failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}
#endregion

#region Data Transformation (mimics DataPlugin conversion pattern)
function ConvertTo-ExportObject {
    <#
    .SYNOPSIS
        Generic converter that dynamically handles all AD properties (BeforeRead hook)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $ADObject,
        
        [Parameter(Mandatory = $true)]
        [string]$ObjectType
    )
    
    process {
        $hash = [ordered]@{}

        # Dynamically add all properties from AD object
        foreach ($prop in $ADObject.PSObject.Properties) {
            $propName = $prop.Name
            $propValue = $prop.Value
            
            # Handle special property types
            $hash[$propName] = switch ($propName) {
                'ObjectGUID' {
                    if ($propValue) { $propValue.ToString() } else { $null }
                }
                'ObjectSID' {
                    if ($propValue) { $propValue.Value } else { $null }
                }
                'NtSecurityDescriptor' {
                    if ($propValue) { $propValue.Sddl } else { $null }
                }
                'MemberOf' {
                    # Add both count and list for group memberships
                    $hash['MemberOfCount'] = if ($propValue) { $propValue.Count } else { 0 }
                    if ($propValue) { ($propValue -join '; ') } else { '' }
                }
                'Members' {
                    # Handle group members
                    $hash['MembersCount'] = if ($propValue) { $propValue.Count } else { 0 }
                    if ($propValue) { ($propValue -join '; ') } else { '' }
                }
                'ManagedObjects' {
                    if ($propValue) { ($propValue -join '; ') } else { '' }
                }
                'ServicePrincipalNames' {
                    if ($propValue) { ($propValue -join '; ') } else { '' }
                }
                default {
                    # Handle arrays and collections
                    if ($propValue -is [System.Array] -or 
                        $propValue -is [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]) {
                        ($propValue -join '; ')
                    }
                    elseif ($propValue -is [DateTime]) {
                        $propValue.ToString('yyyy-MM-dd HH:mm:ss')
                    }
                    else {
                        $propValue
                    }
                }
            }
        }
        
        # Add metadata (mimics DataPluginContext pattern)
        $hash['ScanTimestamp'] = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $hash['ObjectType'] = $ObjectType
        $hash['SourceDomain'] = $script:Config.Domain.DNSRoot
        
        [PSCustomObject]$hash
    }
}

function ConvertTo-UserExport {
    <#
    .SYNOPSIS
        User-specific converter with additional business logic
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $User
    )
    
    process {
        ConvertTo-ExportObject -ADObject $User -ObjectType 'User'
    }
}

function ConvertTo-GroupExport {
    <#
    .SYNOPSIS
        Group-specific converter
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Group
    )
    
    process {
        ConvertTo-ExportObject -ADObject $Group -ObjectType 'Group'
    }
}

function ConvertTo-ContactExport {
    <#
    .SYNOPSIS
        Contact-specific converter
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Contact
    )
    
    process {
        ConvertTo-ExportObject -ADObject $Contact -ObjectType 'Contact'
    }
}

function ConvertTo-ComputerExport {
    <#
    .SYNOPSIS
        Computer-specific converter
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Computer
    )
    
    process {
        ConvertTo-ExportObject -ADObject $Computer -ObjectType 'Computer'
    }
}
#endregion

#region Data Processing (mimics batch processing pattern)
function Invoke-DataProcessing {
    <#
    .SYNOPSIS
        Processes AD objects and converts to export format (AfterRead hook pattern)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Objects,
        
        [Parameter(Mandatory = $true)]
        [string]$ConverterName,
        
        [Parameter(Mandatory = $true)]
        [string]$ObjectType
    )
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Processing $($Objects.Count) $ObjectType objects..." -ForegroundColor White
    
    try {
        # Use the specified converter function
        $exportData = $Objects | & $ConverterName
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Processed $($exportData.Count) records" -ForegroundColor Green
        
        return $exportData
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Processing failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}
#endregion

#region Data Export (XLSX format using ImportExcel module)
function Export-ToCSV {
    <#
    .SYNOPSIS
        Exports data to CSV file (BeforeWrite/AfterWrite hook pattern)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,
        
        [Parameter(Mandatory = $true)]
        [string]$ObjectType,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$Timestamp
    )
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Exporting to CSV..." -ForegroundColor Cyan
    
    try {
        # Ensure output directory exists
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Created directory: $OutputPath" -ForegroundColor Gray
        }
        
        # Generate filename following convention
        $fileName = "${ObjectType}_Export_${Timestamp}.csv"
        $filePath = Join-Path $OutputPath $fileName
        
        # Export with UTF-8 encoding (matching data engine pattern)
        $Data | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        
        # Calculate file size
        $fileInfo = Get-Item $filePath
        $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Exported: $fileName" -ForegroundColor Green
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Size: $fileSizeKB KB ($fileSizeMB MB)" -ForegroundColor Gray
        
        return @{
            FilePath = $filePath
            FileName = $fileName
            FileSize = $fileSizeKB
            RecordCount = $Data.Count
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Export failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Export-ToExcel {
    <#
    .SYNOPSIS
        Exports data to Excel XLSX file with professional formatting
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,
        
        [Parameter(Mandatory = $true)]
        [string]$ObjectType,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$Timestamp
    )
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Exporting to Excel XLSX..." -ForegroundColor Cyan
    
    try {
        # Ensure output directory exists
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Created directory: $OutputPath" -ForegroundColor Gray
        }
        
        # Generate filename following convention: {ObjectType}_Export_yyyyMMdd_HHmmss.xlsx
        $fileName = "${ObjectType}_Export_${Timestamp}.xlsx"
        $filePath = Join-Path $OutputPath $fileName
        
        # Remove existing file if present
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force
        }
        
        # Export to Excel with professional formatting
        $excelParams = @{
            Path = $filePath
            WorksheetName = $ObjectType
            AutoSize = $true
            TableName = "${ObjectType}Table"
        }
        
        $Data | Export-Excel -Path $filePath -WorksheetName $ObjectType -AutoSize
        
        # Calculate file size
        $fileInfo = Get-Item $filePath
        $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Exported: $fileName" -ForegroundColor Green
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Size: $fileSizeKB KB ($fileSizeMB MB)" -ForegroundColor Gray
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Path: $filePath" -ForegroundColor Gray
        
        return @{
            FilePath = $filePath
            FileName = $fileName
            FileSize = $fileSizeKB
            FileSizeMB = $fileSizeMB
            RecordCount = $Data.Count
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Export failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Export-ConsolidatedExcel {
    <#
    .SYNOPSIS
        Exports all object types to single Excel workbook with multiple worksheets
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AllData,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$Timestamp
    )
    
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] [INFO] Creating consolidated workbook..." -ForegroundColor Cyan
    
    try {
        $fileName = "AD_AllObjects_Export_${Timestamp}.xlsx"
        $filePath = Join-Path $OutputPath $fileName
        
        # Remove existing file
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force
        }
        
        $totalRecords = 0
        
        # Export each object type to separate worksheet in same workbook
        foreach ($objectType in $AllData.Keys | Sort-Object) {
            $data = $AllData[$objectType]
            
            if ($data.Count -gt 0) {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Adding worksheet: $objectType ($($data.Count) records)" -ForegroundColor Gray
                
                $excelParams = @{
                    Path = $filePath
                    WorksheetName = $objectType
                    AutoSize = $true
                    TableName = "${objectType}Table"
                }
                
                $data | Export-Excel -Path $filePath -WorksheetName $ObjectType -AutoSize
                $totalRecords += $data.Count
            }
        }
        
        # Add summary worksheet
        $summaryData = foreach ($key in $AllData.Keys | Sort-Object) {
            [PSCustomObject]@{
                ObjectType = $key
                RecordCount = $AllData[$key].Count
                Worksheet = $key
                ExportedBy = $script:Config.Domain.CurrentUser
                ExportTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
        
        $summaryData | Export-Excel -Path $filePath -WorksheetName "Summary" -AutoSize -TableName "SummaryTable" -TableStyle "Medium9" -FreezeTopRow -BoldTopRow -AutoFilter
        
        # Get file info
        $fileInfo = Get-Item $filePath
        $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Consolidated export: $fileName" -ForegroundColor Green
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Total records: $totalRecords across $($AllData.Keys.Count) worksheets" -ForegroundColor Gray
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Size: $fileSizeKB KB ($fileSizeMB MB)" -ForegroundColor Gray
        
        return @{
            FilePath = $filePath
            FileName = $fileName
            FileSizeKB = $fileSizeKB
            FileSizeMB = $fileSizeMB
            RecordCount = $totalRecords
            WorksheetCount = $AllData.Keys.Count + 1  # +1 for summary sheet
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Consolidated export failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}
#endregion
#region Migration Mapping Export
function ConvertTo-MigrationMapping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $ADObject,
        
        [Parameter(Mandatory = $true)]
        [string]$ObjectType
    )
    
    process {
        # Helper to extract OU from DN
        $sourceOU = ''
        if ($ADObject.distinguishedName) {
            $sourceOUs = (
                        ($ADObject.distinguishedName -split ",") |
                        Where-Object { $_ -like "OU=*" } |
                        ForEach-Object { $_.Substring(3) }
                    )
            if($sourceOUs) {
                [array]::Reverse($sourceOUs)
                $sourceOU = $sourceOUs -join "/"
            }
        }


        $sourceDN = if ($ADObject.displayName) { $ADObject.displayName }
                                   else { '' }

        $sourceOb = if ($ADObject.cn) { $ADObject.cn }
                             else { '' }
        if (($ObjectType -eq 'User') -or ($ObjectType -eq 'Group')) {
            $sourceOb = if ($ADObject.sAMAccountName) { $ADObject.sAMAccountName }
                             else { '' }
        }
        
        # Create mapping object
        [PSCustomObject]@{
            'Source object' = $sourceOb
            'Source display name' = $sourceDN
            'Source OU' = $sourceOU
            'Distinguished name (optional)' = if ($ADObject.distinguishedName) { $ADObject.distinguishedName } else { '' }
            'Destination object (optional)' = $sourceOb
            'Destination display name (optional)' = $sourceDN
            'Destination OU' = $sourceOU
            'Object type' = $ObjectType
        }
    }
}

function Export-MigrationMapping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AllScannedObjects,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$Timestamp
    )
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║           CREATING MIGRATION MAPPING FILE                      ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta
    
    try {
        # Collect all mappings into single list
        $allMappings = [System.Collections.Generic.List[PSCustomObject]]::new()
        
        foreach ($objectType in $AllScannedObjects.Keys | Sort-Object) {
            $objects = $AllScannedObjects[$objectType]
            
            if ($objects.Count -gt 0) {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Processing $($objects.Count) $objectType objects..." -ForegroundColor Cyan
                
                foreach ($obj in $objects) {
                    $mapping = ConvertTo-MigrationMapping -ADObject $obj -ObjectType $objectType
                    $allMappings.Add($mapping)
                }
                
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Converted $($objects.Count) $objectType entries" -ForegroundColor Green
            }
        }
        
        if ($allMappings.Count -eq 0) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [WARNING] No objects to export" -ForegroundColor Yellow
            return $null
        }
        
        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] [INFO] Total mapping entries: $($allMappings.Count)" -ForegroundColor White
        
        # Generate filename
        $fileName = "Migration_Mapping_${Timestamp}.${Extention}"
        $filePath = Join-Path $OutputPath $fileName
        
        # Remove existing file
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force
        }
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Exporting to: $fileName" -ForegroundColor Cyan
        if ($Extention -eq 'csv') {
            # Export all mappings to single Csv file
            $allMappings | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        } else {
            # Export all mappings to single Excel file
            $allMappings | Export-Excel -Path $filePath `
                -WorksheetName "Migration Mapping" `
                -TableName "MappingTable" `
                -AutoSize `
        }
        
        # Get file info
        $fileInfo = Get-Item $filePath
        $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Migration mapping exported: $fileName" -ForegroundColor Green
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Records: $($allMappings.Count)" -ForegroundColor Gray
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Size: $fileSizeKB KB ($fileSizeMB MB)" -ForegroundColor Gray
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Path: $filePath" -ForegroundColor Gray
        
        # Show breakdown by object type
        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] [INFO] Breakdown by object type:" -ForegroundColor Cyan
        $groups = $allMappings | Group-Object 'Object type'
        foreach ($group in $groups | Sort-Object Name) {
            Write-Host "  - $($group.Name): $($group.Count)" -ForegroundColor White
        }
        
        return @{
            FilePath = $filePath
            FileName = $fileName
            FileSizeKB = $fileSizeKB
            FileSizeMB = $fileSizeMB
            RecordCount = $allMappings.Count
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to export mapping: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}
#endregion

#region Reporting (mimics AbstractReportBuilder output)
function Show-ScanReport {
    <#
    .SYNOPSIS
        Displays comprehensive scan report (Completed hook pattern)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ScanResults,
        
        [Parameter(Mandatory = $true)]
        [timespan]$Duration
    )
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           ACTIVE DIRECTORY SCAN REPORT                         ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    # Domain Information
    Write-Host "`n┌─ DOMAIN INFORMATION ───────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│ Domain:          $($script:Config.Domain.DNSRoot)" -ForegroundColor White
    Write-Host "│ Controller:      $($script:Config.Domain.DomainController)" -ForegroundColor White
    Write-Host "│ Forest:          $($script:Config.Domain.Forest)" -ForegroundColor White
    Write-Host "│ Scan Time:       $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    Write-Host "│ Duration:        $($Duration.ToString('mm\:ss\.fff'))" -ForegroundColor White
    Write-Host "└────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    
    # Object Type Results
    Write-Host "`n┌─ SCAN RESULTS ─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    
    $totalObjects = 0
    $totalSize = 0
    
    foreach ($objectType in ($ScanResults.Keys | Sort-Object)) {
        $result = $ScanResults[$objectType]
        
        if ($result.Error) {
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "│ [$objectType] - FAILED" -ForegroundColor Red
            Write-Host "│   Error: $($result.Error)" -ForegroundColor Red
        }
        else {
            $totalObjects += $result.RecordCount
            $totalSize += $result.FileSize
            
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "│ [$objectType]" -ForegroundColor Green
            Write-Host "│   Count:     $($result.RecordCount) objects" -ForegroundColor White
            Write-Host "│   File:      $($result.FileName)" -ForegroundColor Gray
            Write-Host "│   Size:      $($result.FileSize) KB" -ForegroundColor Gray
        }
    }
    
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "└────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    
    # Totals
    Write-Host "`n┌─ SUMMARY ──────────────────────────────────────────────────────┐" -ForegroundColor Green
    Write-Host "│ Total Objects:       $totalObjects" -ForegroundColor White
    Write-Host "│ Total Size:          $([math]::Round($totalSize, 2)) KB ($([math]::Round($totalSize/1024, 2)) MB)" -ForegroundColor White
    Write-Host "│ Processing Rate:     $([math]::Round($totalObjects / $Duration.TotalSeconds, 2)) objects/sec" -ForegroundColor White
    Write-Host "│ Output Directory:    $($script:Config.OutputPath)" -ForegroundColor White
    Write-Host "└────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                 SCAN COMPLETED SUCCESSFULLY                    ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
}
#endregion

#region Main Execution Pipeline
function Invoke-ADScanPipeline {
    <#
    .SYNOPSIS
        Main orchestration function (mimics processor pipeline pattern)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ObjectTypesToScan
    )
    
    $overallStartTime = Get-Date
    
    try {
        # Initialize
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║        AvePoint Fly Migration - AD Object Scanner              ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        
        if (-not (Initialize-ADModule)){
            throw "Failed to import required module"
        }
        
        if (-not (Test-ADConnectivity)) {
            throw "Failed to establish AD connectivity"
        }
        
        # Determine which object types to scan
        $configsToProcess = if ('All' -in $ObjectTypesToScan) {
            $script:ObjectTypeConfigs
        }
        else {
            $script:ObjectTypeConfigs | Where-Object { $_.Name -in $ObjectTypesToScan }
        }
        
        # Store raw AD objects for mapping
        $allRawObjects = @{}

        # Process each object type
        foreach ($config in $configsToProcess) {
            $objectStartTime = Get-Date
            
            try {
                # Scan
                $objects = Invoke-ADObjectScan -ObjectConfig $config
                
                if ($objects.Count -eq 0) {
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [WARNING] No $($config.Name) objects found" -ForegroundColor Yellow
                    continue
                }

                # Store raw objects for migration mapping
                if($IncludeMapping) {
                    if ($config.Name -eq 'Computer') {
                        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [WARNING] Not export mapping for $($config.Name)" -ForegroundColor Yellow
                    } else {
                        $allRawObjects[$config.Name] = $objects
                    }
                }
                
                # Process
                $exportData = Invoke-DataProcessing `
                    -Objects $objects `
                    -ConverterName $config.Converter `
                    -ObjectType $config.Name
                
                #Export
                if ($Extention -eq "csv"){
                    $exportResult = Export-ToCSV `
                        -Data $exportData `
                        -ObjectType $config.Name `
                        -OutputPath $script:Config.OutputPath `
                        -Timestamp $script:Config.Timestamp
                    }
                else{
                    $exportResult = Export-ToExcel `
                        -Data $exportData `
                        -ObjectType $config.Name `
                        -OutputPath $script:Config.OutputPath `
                        -Timestamp $script:Config.Timestamp
                }
                
                # Store results
                $script:Config.ScanResults[$config.Name] = @{
                    RecordCount = $exportResult.RecordCount
                    FileName = $exportResult.FileName
                    FilePath = $exportResult.FilePath
                    FileSize = $exportResult.FileSize
                    Duration = (Get-Date) - $objectStartTime
                }
            }
            catch {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to process $($config.Name): $($_.Exception.Message)" -ForegroundColor Red
                
                $script:Config.ScanResults[$config.Name] = @{
                    RecordCount = 0
                    Error = $_.Exception.Message
                }
            }
        }

        # After all objects are scanned, create migration mapping file
        if ($IncludeMapping -and $allRawObjects.Count -gt 0) {
            try {
                $mappingResult = Export-MigrationMapping `
                    -AllScannedObjects $allRawObjects `
                    -OutputPath $script:Config.OutputPath `
                    -Timestamp $script:Config.Timestamp
                
                #if ($mappingResult) {
                #    $script:Config.ScanResults['_MigrationMapping'] = $mappingResult
                #}
            }
            catch {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to create migration mapping: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Report
        $totalDuration = (Get-Date) - $overallStartTime
        Show-ScanReport -ScanResults $script:Config.ScanResults -Duration $totalDuration
        
        return 0
    }
    catch {
        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] [FATAL] Pipeline execution failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
        return 1
    }
}
#endregion

#region Entry Point
# Execute main pipeline
$exitCode = Invoke-ADScanPipeline -ObjectTypesToScan $ObjectTypes
exit $exitCode
#endregion
# SIG # Begin signature block
# MIIoZQYJKoZIhvcNAQcCoIIoVjCCKFICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB/PgX7RslahnJ5
# FyuRDlL7C94YHm9tmkUOrSNobw0Zk6CCDZowggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggbiMIIEyqADAgECAhAPc9sqd/BkUUsWn0FQMB0UMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjMxMTAzMDAwMDAwWhcNMjYxMTE0
# MjM1OTU5WjBqMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIG
# A1UEBxMLSmVyc2V5IENpdHkxFzAVBgNVBAoTDkF2ZVBvaW50LCBJbmMuMRcwFQYD
# VQQDEw5BdmVQb2ludCwgSW5jLjCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoC
# ggGBAOEW7Ii2pvR9/732eojqygVHkWY2HMdaefS7g4Z4EOt6ABrXYcTFvIMax1DN
# 7ZCbfarSe6B0jsXnrNbhTZKJiphzbLAIs4NOi4EMxdWzDbc8oZqByMX77NxSiaR3
# PhqFGI99Utr9NUIBsruS6AccQ6CkP2nNejixv6BrsGJbUDrgz6A66x7V4WhYa6df
# qmMU8EucSyjcZB2A4h21H+jURe95N1SZThOw6vfFKn5JPnKvGTCuH0u19xi8d90j
# ZItOntrR92wzFG2jSd4Z3DeKyvIDWxGGqaDqloA7thXNGN/URNqTZfeXdsF6uUU2
# IojpWh8gYBTnu9i8cM9PVDOB420h5JaV+1XLO8m10LtnYBSWZWgUHpcTq7Suwbah
# 0/yiur0ltzR13dQ0wk2Xe1i/G8PlKw4IlyqESqizT3YxUGlqwcojIAYwaGBtATTf
# kCKq32rornXSmCqfrQICoA8dR7pry8hl/JloSD/+riT62F8r8mQTlLUw5xNiqBqE
# kIQvuQIDAQABo4ICAzCCAf8wHwYDVR0jBBgwFoAUaDfg67Y7+F8Rhvv+YXsIiGX0
# TkIwHQYDVR0OBBYEFJxiV1oIFotUW4UTNkwFNyJScORPMD4GA1UdIAQ3MDUwMwYG
# Z4EMAQQBMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQ
# UzAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwgbUGA1UdHwSB
# rTCBqjBToFGgT4ZNaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcmwwU6BRoE+G
# TWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVT
# aWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMIGUBggrBgEFBQcBAQSBhzCB
# hDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFwGCCsGAQUF
# BzAChlBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVk
# RzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNydDAJBgNVHRMEAjAA
# MA0GCSqGSIb3DQEBCwUAA4ICAQDE9SZRwvtvpHrw4OjJ1AKL0aabKlOUkxidOjEC
# wrWr4yFKJdHWHpouUFTye7M8gQS4FQDQqD4ys7a1joCQVd+WEiQIyy0TzJXxT7US
# tkhg8lD41cT7i857dgnSrX7Prp0Es/xFBhEKR0fMs3Sj20+qcnJNTB4TA9CPnUd4
# UL1Ve/bqsr5lVZgoPp6wbs0lXjsTEfzrio++T4ssc42eTxfv6YZgTmdrPEQNqLUa
# hQuQ0x5j8lVBBtt5PrC7TikkVB/GBZ+01EJrUQvcX3arZky1tviINBQ3EXRhyGkx
# zSz6Vk9NxwJVkdavIUkdDuUuqNVqp2a3Zsv2L3mwlr0UnKMgpBiPnxgC9u6e5tjR
# +plDe3fmD20XQTt/p61FueC7w92HC6YizDrynRX58h6KuRv2j/u2yZU3nipaiGlz
# 8jURf2ySxZXI2QG228Nfsg4y1Z61tPfYb4kcqTfVcaxh7azpP6BU33dkIyC7dmv4
# q3PueRcSyweKjqlQqeswnTeBS3+met1BbjkMdJJzqbIu5WONTBIHHH1RGsQYPn8i
# ms3pE0GhGl9c1r1BpufehQwSjCZRc/vHrHUOQyNimVKoOtls5UAxU5FXO3PKaHPO
# M6dFS1b+EF6drXV0M9/KdJVyyP4EK6CJQVt7RrQBRSSdQCKCYJ63VUF5amRuzY0s
# EqLoRTGCGiEwghodAgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2ln
# bmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQD3PbKnfwZFFLFp9BUDAdFDAN
# BglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCCgrB+WnW2KcNQFnGst/anDmvTQtunaTtsz45DDHGVmiTANBgkq
# hkiG9w0BAQEFAASCAYCyrieE+qjgWvJRMrksfPU6RixTENErgliD6oLsW3j/pB9v
# dpByM9mzKC1JwvvHNvIVPZUCsPi48gOXaqJssJUK5ilbZyX1EPrcQn4b+iQ1JhZA
# PUR8KspOf/Pj1ThWv+pJ66so2bkLGNXTn6hxXQkNZokarK/m35kOLlMnpBedzRZB
# T70+mCJzX0D3P57zMm1RDy+YJlfN0VQWCeL62peMZI4WqNMv/Qn5SEsv1OXEvNtd
# uo/swLJOQBl1nMSSq0DFTyhDjksCZPKstAl0XYZTfe9l51v7+TTPuF56OIZn2+0Y
# Dwtrms02+JvPFz5JWSULPlYRSuoWLpkaQ9pCVeZp0LY3IUiljXRNQCaWRttXrRwh
# ePsKmUivFG9z4B2xZdvhGxcNbvm1h17zSs8vT1DfkUfrOcxXijZEaEqhRR0GJeNm
# 3t4pENCDbv//mfTTQ1Q3h9TLwkJ53c6RMjjcOHgpYtASAjhpWoz47o/NB5IFx70h
# U4KBuRnzXKSQ9uuM5Yyhghd3MIIXcwYKKwYBBAGCNwMDATGCF2MwghdfBgkqhkiG
# 9w0BBwKgghdQMIIXTAIBAzEPMA0GCWCGSAFlAwQCAQUAMHgGCyqGSIb3DQEJEAEE
# oGkEZzBlAgEBBglghkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQgKBYKmSkN3Vht
# A+i76G4X2bg+p3hFq1Rzer6YKtLOIEICEQC2qmlCpJPfzmG7DFZ4QNp9GA8yMDI2
# MDMyNjEwMDcwMFqgghM6MIIG7TCCBNWgAwIBAgIQCoDvGEuN8QWC0cR2p5V0aDAN
# BgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5n
# IFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI1MDYwNDAwMDAwMFoXDTM2MDkw
# MzIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNBNDA5NiBUaW1lc3RhbXAgUmVz
# cG9uZGVyIDIwMjUgMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANBG
# rC0Sxp7Q6q5gVrMrV7pvUf+GcAoB38o3zBlCMGMyqJnfFNZx+wvA69HFTBdwbHwB
# SOeLpvPnZ8ZN+vo8dE2/pPvOx/Vj8TchTySA2R4QKpVD7dvNZh6wW2R6kSu9RJt/
# 4QhguSssp3qome7MrxVyfQO9sMx6ZAWjFDYOzDi8SOhPUWlLnh00Cll8pjrUcCV3
# K3E0zz09ldQ//nBZZREr4h/GI6Dxb2UoyrN0ijtUDVHRXdmncOOMA3CoB/iUSROU
# INDT98oksouTMYFOnHoRh6+86Ltc5zjPKHW5KqCvpSduSwhwUmotuQhcg9tw2YD3
# w6ySSSu+3qU8DD+nigNJFmt6LAHvH3KSuNLoZLc1Hf2JNMVL4Q1OpbybpMe46Yce
# NA0LfNsnqcnpJeItK/DhKbPxTTuGoX7wJNdoRORVbPR1VVnDuSeHVZlc4seAO+6d
# 2sC26/PQPdP51ho1zBp+xUIZkpSFA8vWdoUoHLWnqWU3dCCyFG1roSrgHjSHlq8x
# ymLnjCbSLZ49kPmk8iyyizNDIXj//cOgrY7rlRyTlaCCfw7aSUROwnu7zER6EaJ+
# AliL7ojTdS5PWPsWeupWs7NpChUk555K096V1hE0yZIXe+giAwW00aHzrDchIc2b
# Qhpp0IoKRR7YufAkprxMiXAJQ1XCmnCfgPf8+3mnAgMBAAGjggGVMIIBkTAMBgNV
# HRMBAf8EAjAAMB0GA1UdDgQWBBTkO/zyMe39/dfzkXFjGVBDz2GM6DAfBgNVHSME
# GDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGlu
# Z1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBp
# bmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIw
# CwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQBlKq3xHCcEua5gQezRCESe
# Y0ByIfjk9iJP2zWLpQq1b4URGnwWBdEZD9gBq9fNaNmFj6Eh8/YmRDfxT7C0k8FU
# FqNh+tshgb4O6Lgjg8K8elC4+oWCqnU/ML9lFfim8/9yJmZSe2F8AQ/UdKFOtj7Y
# MTmqPO9mzskgiC3QYIUP2S3HQvHG1FDu+WUqW4daIqToXFE/JQ/EABgfZXLWU0zi
# TN6R3ygQBHMUBaB5bdrPbF6MRYs03h4obEMnxYOX8VBRKe1uNnzQVTeLni2nHkX/
# QqvXnNb+YkDFkxUGtMTaiLR9wjxUxu2hECZpqyU1d0IbX6Wq8/gVutDojBIFeRlq
# AcuEVT0cKsb+zJNEsuEB7O7/cuvTQasnM9AWcIQfVjnzrvwiCZ85EE8LUkqRhoS3
# Y50OHgaY7T/lwd6UArb+BOVAkg2oOvol/DJgddJ35XTxfUlQ+8Hggt8l2Yv7roan
# cJIFcbojBcxlRcGG0LIhp6GvReQGgMgYxQbV1S3CrWqZzBt1R9xJgKf47CdxVRd/
# ndUlQ05oxYy2zRWVFjF7mcr4C34Mj3ocCVccAvlKV9jEnstrniLvUxxVZE/rptb7
# IRE2lskKPIJgbaP5t2nGj/ULLi49xTcBZU8atufk+EMF/cWuiC7POGT75qaL6vdC
# vHlshtjdNXOCIUjsarfNZzCCBrQwggScoAMCAQICEA3HrFcF/yGZLkBDIgw6SYYw
# DQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNl
# cnQgVHJ1c3RlZCBSb290IEc0MB4XDTI1MDUwNzAwMDAwMFoXDTM4MDExNDIzNTk1
# OVowaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYD
# VQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNI
# QTI1NiAyMDI1IENBMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALR4
# MdMKmEFyvjxGwBysddujRmh0tFEXnU2tjQ2UtZmWgyxU7UNqEY81FzJsQqr5G7A6
# c+Gh/qm8Xi4aPCOo2N8S9SLrC6Kbltqn7SWCWgzbNfiR+2fkHUiljNOqnIVD/gG3
# SYDEAd4dg2dDGpeZGKe+42DFUF0mR/vtLa4+gKPsYfwEu7EEbkC9+0F2w4QJLVST
# EG8yAR2CQWIM1iI5PHg62IVwxKSpO0XaF9DPfNBKS7Zazch8NF5vp7eaZ2CVNxpq
# umzTCNSOxm+SAWSuIr21Qomb+zzQWKhxKTVVgtmUPAW35xUUFREmDrMxSNlr/NsJ
# yUXzdtFUUt4aS4CEeIY8y9IaaGBpPNXKFifinT7zL2gdFpBP9qh8SdLnEut/Gcal
# NeJQ55IuwnKCgs+nrpuQNfVmUB5KlCX3ZA4x5HHKS+rqBvKWxdCyQEEGcbLe1b8A
# w4wJkhU1JrPsFfxW1gaou30yZ46t4Y9F20HHfIY4/6vHespYMQmUiote8ladjS/n
# J0+k6MvqzfpzPDOy5y6gqztiT96Fv/9bH7mQyogxG9QEPHrPV6/7umw052AkyiLA
# 6tQbZl1KhBtTasySkuJDpsZGKdlsjg4u70EwgWbVRSX1Wd4+zoFpp4Ra+MlKM2ba
# oD6x0VR4RjSpWM8o5a6D8bpfm4CLKczsG7ZrIGNTAgMBAAGjggFdMIIBWTASBgNV
# HRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBTvb1NK6eQGfHrK4pBW9i/USezLTjAf
# BgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYw
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMG
# A1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG
# /WwHATANBgkqhkiG9w0BAQsFAAOCAgEAF877FoAc/gc9EXZxML2+C8i1NKZ/zdCH
# xYgaMH9Pw5tcBnPw6O6FTGNpoV2V4wzSUGvI9NAzaoQk97frPBtIj+ZLzdp+yXdh
# OP4hCFATuNT+ReOPK0mCefSG+tXqGpYZ3essBS3q8nL2UwM+NMvEuBd/2vmdYxDC
# vwzJv2sRUoKEfJ+nN57mQfQXwcAEGCvRR2qKtntujB71WPYAgwPyWLKu6RnaID/B
# 0ba2H3LUiwDRAXx1Neq9ydOal95CHfmTnM4I+ZI2rVQfjXQA1WSjjf4J2a7jLzWG
# NqNX+DF0SQzHU0pTi4dBwp9nEC8EAqoxW6q17r0z0noDjs6+BFo+z7bKSBwZXTRN
# ivYuve3L2oiKNqetRHdqfMTCW/NmKLJ9M+MtucVGyOxiDf06VXxyKkOirv6o02Oo
# XN4bFzK0vlNMsvhlqgF2puE6FndlENSmE+9JGYxOGLS/D284NHNboDGcmWXfwXRy
# 4kbu4QFhOm0xJuF2EZAOk5eCkhSxZON3rGlHqhpB/8MluDezooIs8CVnrpHMiD2w
# L40mm53+/j7tFaxYKIqL0Q4ssd8xHZnIn/7GELH3IdvG2XlM9q7WP/UwgOkw/HQt
# yRN62JK4S1C8uw3PdBunvAZapsiI5YKdvlarEvf8EA+8hcpSM9LHJmyrxaFtoza2
# zNaQ9k+5t1wwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3
# DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3Vy
# ZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIw
# aTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLK
# EdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4Tm
# dDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembu
# d8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnD
# eMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1
# XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVld
# QnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTS
# YW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSm
# M9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzT
# QRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kx
# fgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/
# MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv
# 9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBr
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUH
# MAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYG
# BFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72a
# rKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFID
# yE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/o
# Wajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv
# 76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30
# fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQxggN8MIID
# eAIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5
# NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIB
# BQCggdEwGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMjYxMDA3MDBaMCsGCyqGSIb3DQEJEAIMMRwwGjAYMBYEFN1iMKyGCi0w
# a9o4sWh5UjAH+0F+MC8GCSqGSIb3DQEJBDEiBCCxJcM+BEV5YqYkc9u0gR/sGzY5
# 1c/wcXKxQb45ASZEmzA3BgsqhkiG9w0BCRACLzEoMCYwJDAiBCBKoD+iLNdchMVc
# k4+CjmdrnK7Ksz/jbSaaozTxRhEKMzANBgkqhkiG9w0BAQEFAASCAgCu3BHNomv6
# LgEwZpEgLVIRNNxVA3a9iMjDqjeCRKH7kVdBwvw2rVmoUJxPWpp72z6A/B4bgOGN
# ITYmaeoa3M+yTiNOAvbHR6so0O6l/oPdtBT5/Jcf0A0/bf5K8i+nj4ZQ2Ih0+eio
# izCYFjpM2V8NFxEJ4atWyG4901JRBeK1Af9QBhw9Myu7SdSecIAxpfC8HBTeFVki
# 7mwa4EypGBAoImU47T3/JRTpqQlCUwk0kEpkVfRC2Iq0grGsRvOF/82yrkgoOsxq
# BEdYS+eACRMlBPKYIbhI6ISwYCx709RuwH6J73MkYDI8dCPtXKXI7GSCRqMzED46
# 2hkqChOYZD5yjvonMndiqbLzCxxOI9gLCDOTx8eoC//Iobl2McWi399gsknFMoRg
# KKvedHikbIQ+Z2pgg9JfSf2aqa8FTQNYC/DTLRasHv1+e+3Cryx4OimZiPx4znB0
# Wh0jSWBa8rriaonllTkCe9FnTh0RaAdWKrGasObU5CIEaNqQnVXzxezbnibXrgS+
# 7Q9fewOFGFuvfrdaWv/hE7BmoX+IfbAdgfWd/U0ksJVBLnFZ+1KQ/QTKR9yFFszR
# 20xzZDhkOL8cHVxMPLBQCKmoYLO4jSjMvv2vlzNmMFmf8140I3Awo5JaMt7bChNs
# kGXguwWPdEai2HkTIw4ob+FnLU4g4dS+nQ==
# SIG # End signature block
