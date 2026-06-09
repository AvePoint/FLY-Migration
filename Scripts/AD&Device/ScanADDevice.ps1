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
    [string[]]$ObjectTypes = @('Computer'),

    [Parameter(Mandatory = $false)]
    [bool]$IsCombined = $false,
    
    [Parameter(Mandatory = $false)]
    [bool]$IncludeMapping = $true,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('csv', 'xlsx')]
    [string]$Extension = "csv"
)

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

#region Configuration
$script:Config = @{
    OutputPath                 = $OutputPath
    Timestamp                  = Get-Date -Format 'yyyyMMdd_HHmmss'
    Domain                     = $null
    ScanResults                = @{}
    CurrentRequestedProperties = @()  # Track properties requested for current scan
}

# Well-known SID prefixes to skip (built-in local groups and services)
$script:BuiltinSidPrefixes = @(
    'S-1-5-32-',  # Built-in groups (Administrators, Users, Guests, etc.)
    'S-1-5-18',   # Local System
    'S-1-5-19',   # Local Service
    'S-1-5-20'    # Network Service
)

# Well-known domain-relative RID suffixes to skip
$script:BuiltinRidSuffixes = @(
    '-500',   # Administrator
    '-501',   # Guest
    '-502',   # KRBTGT
    '-503',   # DefaultAccount
    '-504',   # WellKnown Users
    '-512',   # Domain Admins
    '-513',   # Domain Users
    '-514',   # Domain Guests
    '-515',   # Domain Computers
    '-516',   # Domain Controllers
    '-517',   # Cert Publishers
    '-518',   # Schema Admins
    '-519',   # Enterprise Admins
    '-520',   # Group Policy Creator Owners
    '-521',   # Read-only Domain Controllers
    '-522',   # Cloneable Domain Controllers
    '-525',   # Protected Users
    '-526',   # Key Admins
    '-527',   # Enterprise Key Admins
    '-553',   # RAS and IAS Servers
    '-571',   # Allowed RODC Password Replication Group
    '-572',   # Denied RODC Password Replication Group
    '-498',   # Enterprise Read-only Domain Controllers
    '-529',   # RODC Denied Replication Group
    '-530',   # RODC Allowed Replication Group
    '-1000',  # DNS Admins Group
    '-1001',  # DNS Update Proxy Group
    '-1101',  # DnsAdmins
    '-1102',  # DnsUpdateProxy
    '-1103',  # DHCP Administrators
    '-1104'   # DHCP Users
)

# Define common properties (shared across all AD objects)
$script:CommonProperties = @(
    'distinguishedName',
    'name',
    'objectGUID',
    'description',
    'displayName',
    'instanceType',
    'nTSecurityDescriptor',
    'dSCorePropagationData',
    'objectCategory',
    'whenCreated',
    'uSNCreated',
    'whenChanged',
    'uSNChanged',
    'proxyAddresses'
)

# Define object type configurations (mimics PluginBuilder pattern)
$script:ObjectTypeConfigs = @(
    @{
        Name       = 'User'
        Filter     = '*'
        Properties = $script:CommonProperties + @(
            'accountExpires',
            'accountNameHistory',
            'aCSPolicyName',
            'adminCount',
            'adminDescription',
            'adminDisplayName',
            'altSecurityIdentities',
            'badPasswordTime',
            'badPwdCount',
            'c',
            'co',
            'cn',
            'company',
            'countryCode',
            'codePage',
            'department',
            'division',
            'facsimileTelephoneNumber',
            'givenName',
            'homePhone',
            'info',
            'l',
            'lastLogoff',
            'lastLogon',
            'lockoutTime',
            'logonCount',
            'mail',
            'managedObjects',
            'manager',
            'memberOf',
            'msTSProperty01',
            'msTSWorkDirectory',
            'objectClass',
            'objectSid',
            'otherHomePhone',
            'otherMobile',
            'otherFacsimileTelephoneNumber',
            'otherIpPhone',
            'otherPager',
            'pager',
            'physicalDeliveryOfficeName',
            'postOfficeBox',
            'postalCode',
            'primaryGroupID',
            'pwdLastSet',
            'sAMAccountName',
            'sAMAccountType',
            'sn',
            'st',
            'street',
            'streetAddress',
            'telephoneNumber',
            'title',
            'url',
            'userAccountControl',
            'unixUserPassword',
            'userPassword',
            'unicodePwd',
            'userPrincipalName',
            'userWorkstations',
            'wWWHomePage',
            'initials',
            'ipPhone',
            'mobile'
        )
        Command    = 'Get-ADUser'
        Converter  = 'ConvertTo-UserExport'
    },
    @{
        Name       = 'Group'
        Filter     = '*'
        Properties = $script:CommonProperties + @(
            'accountNameHistory',
            'adminCount',
            'adminDescription',
            'adminDisplayName',
            'altSecurityIdentities',
            'cn',
            'groupType',
            'info',
            'mail',
            'managedBy',
            'member',
            'objectSID',
            'sAMAccountName',
            'sAMAccountType'
        )
        Command    = 'Get-ADGroup'
        Converter  = 'ConvertTo-GroupExport'
    },
    @{
        Name       = 'Contact'
        Filter     = "objectClass -eq 'contact'"
        Properties = $script:CommonProperties + @(
            'cn',
            'c',
            'co',
            'company',
            'countryCode',
            'department',
            'givenName',
            'homePhone',
            'l',
            'mail',
            'manager',
            'memberOf',
            'mobile',
            'objectClass',
            'otherTelephone',
            'url',
            'otherHomePhone',
            'pager',
            'facsimileTelephoneNumber',
            'otherMobile',
            'otherPager',
            'otherFacsimileTelephoneNumber',
            'otherIpPhone',
            'info',
            'physicalDeliveryOfficeName',
            'postalCode',
            'postOfficeBox',
            'sn',
            'st',
            'street',
            'streetAddress',
            'telephoneNumber',
            'title',
            'wWWHomePage',
            'initials',
            'ipPhone'
        )
        Command    = 'Get-ADObject'
        Converter  = 'ConvertTo-ContactExport'
    },
    @{
        Name       = 'Computer'
        Filter     = '*'
        Properties = $script:CommonProperties + @(
            'cn', 'dNSHostName', 'sAMAccountName', 'operatingSystem', 'operatingSystemVersion', 'lastLogonTimestamp', 
            'pwdLastSet', 'userAccountControl', 'servicePrincipalName', 'location', 'managedBy'
        )
        Command    = 'Get-ADComputer'
        Converter  = 'ConvertTo-ComputerExport'
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
    if ($Extension -eq 'csv') {
    }
    else {
        if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
            Write-Host "Trying to install ImportExcel module from PowerShell Gallery..." -ForegroundColor Yellow
            
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                
                Install-Module -Name ImportExcel -Scope CurrentUser -Force -ErrorAction Stop
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] ImportExcel module installed via Install-Module" -ForegroundColor Green
            }
            catch {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [WARNING] Standard installation failed. Trying alternative method..." -ForegroundColor Yellow
                
                try {
                    $modulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ImportExcel"
                    
                    if (-not (Test-Path $modulePath)) {
                        New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
                    }
                    
                    Write-Host "  Downloading ImportExcel module package..." -ForegroundColor Cyan
                    $webClient = New-Object System.Net.WebClient
                    $moduleUrl = "https://www.powershellgallery.com/api/v2/package/ImportExcel"
                    $nupkgFile = Join-Path $env:TEMP "ImportExcel.nupkg"
                    $zipFile = Join-Path $env:TEMP "ImportExcel.zip"
                    
                    $webClient.DownloadFile($moduleUrl, $nupkgFile)
                    Copy-Item $nupkgFile $zipFile -Force
                    
                    if (Test-Path $modulePath) {
                        Remove-Item $modulePath -Recurse -Force
                    }
                    
                    Write-Host "  Extracting module files..." -ForegroundColor Cyan
                    Expand-Archive -Path $zipFile -DestinationPath $modulePath -Force
                    
                    Remove-Item $nupkgFile -Force -ErrorAction SilentlyContinue
                    Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
                    
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] ImportExcel module installed via direct download" -ForegroundColor Green
                }
                catch {
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to install ImportExcel module!" -ForegroundColor Red
                    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "`nManual Installation Instructions:" -ForegroundColor Yellow
                    Write-Host "  Option 1 - PowerShell Gallery:" -ForegroundColor White
                    Write-Host "    Install-Module -Name ImportExcel -Scope CurrentUser" -ForegroundColor Gray
                    Write-Host "  Option 2 - Direct Download:" -ForegroundColor White
                    Write-Host "    Visit: https://www.powershellgallery.com/packages/ImportExcel" -ForegroundColor Gray
                    return $false
                }
            }
            
            # Verify module is now available
            if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] ImportExcel module installation verification failed!" -ForegroundColor Red
                return $false
            }
        }
        
        # Import the module
        Import-Module ImportExcel -ErrorAction Stop
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] ImportExcel module loaded (Version: $((Get-Module ImportExcel).Version))" -ForegroundColor Green
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
            DNSRoot          = $domain.DNSRoot
            DomainController = $dc.HostName
            Forest           = $domain.Forest
            DomainMode       = $domain.DomainMode
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

#region Built-in Object Detection
function Test-BuiltinObject {
    <#
    .SYNOPSIS
        Returns $true if the AD object is a built-in/system object that should be skipped.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $ADObject
    )

    if ($ADObject.isCriticalSystemObject -eq $true) {
        return $true
    }

    if ($ADObject.systemFlags -and $ADObject.systemFlags -ne 0) {
        return $true
    }

    if ($ADObject.distinguishedName -and $ADObject.distinguishedName -match 'MSOL_') {
        return $true
    }

    $sidString = $null
    if ($ADObject.objectSid) {
        $sid = $ADObject.objectSid
        if ($sid -is [System.Security.Principal.SecurityIdentifier]) {
            $sidString = $sid.Value
        }
        elseif ($sid.Value) {
            $sidString = $sid.Value
        }
        else {
            $sidString = $sid.ToString()
        }
    }
    elseif ($ADObject.objectSID) {
        $sid = $ADObject.objectSID
        if ($sid -is [System.Security.Principal.SecurityIdentifier]) {
            $sidString = $sid.Value
        }
        elseif ($sid.Value) {
            $sidString = $sid.Value
        }
        else {
            $sidString = $sid.ToString()
        }
    }

    if ($sidString) {
        foreach ($prefix in $script:BuiltinSidPrefixes) {
            if ($sidString.StartsWith($prefix)) {
                return $true
            }
        }

        foreach ($suffix in $script:BuiltinRidSuffixes) {
            if ($sidString.EndsWith($suffix)) {
                return $true
            }
        }

        try {
            $sidObj = if ($ADObject.objectSid -is [System.Security.Principal.SecurityIdentifier]) {
                $ADObject.objectSid
            }
            elseif ($ADObject.objectSID -is [System.Security.Principal.SecurityIdentifier]) {
                $ADObject.objectSID
            }
            else {
                [System.Security.Principal.SecurityIdentifier]::new($sidString)
            }
            if ($sidObj.IsWellKnown([System.Security.Principal.WellKnownSidType]::BuiltinDomainSid) -or
                $sidObj.IsWellKnown([System.Security.Principal.WellKnownSidType]::WorldSid) -or
                $sidObj.IsWellKnown([System.Security.Principal.WellKnownSidType]::LocalSystemSid) -or
                $sidObj.IsWellKnown([System.Security.Principal.WellKnownSidType]::LocalServiceSid) -or
                $sidObj.IsWellKnown([System.Security.Principal.WellKnownSidType]::NetworkServiceSid) -or
                $sidObj.IsWellKnown([System.Security.Principal.WellKnownSidType]::AnonymousSid) -or
                $sidObj.IsWellKnown([System.Security.Principal.WellKnownSidType]::AuthenticatedUserSid) -or
                $sidObj.IsWellKnown([System.Security.Principal.WellKnownSidType]::LocalSid)) {
                return $true
            }
        }
        catch {
            # If SID parsing fails, skip this check
        }
    }

    return $false
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
        # Build query parameters - retrieve ALL properties to capture additional data
        $params = @{
            Properties  = '*'
            ErrorAction = 'Stop'
        }

        # Show indeterminate progress while querying AD
        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 10 -Activity "Querying Active Directory" -Status "Retrieving $($ObjectConfig.Name) objects..." -PercentComplete -1
        $ProgressPreference = $localProgressPref

        # Execute appropriate command based on object type
        $objects = switch ($ObjectConfig.Command) {
            'Get-ADUser' {
                $params['Filter'] = $ObjectConfig.Filter
                Get-ADUser @params
            }
            'Get-ADGroup' {
                $params['Filter'] = $ObjectConfig.Filter
                Get-ADGroup @params
            }
            'Get-ADComputer' {
                $params['Filter'] = $ObjectConfig.Filter
                Get-ADComputer @params
            }
            'Get-ADObject' {
                $params['Filter'] = $ObjectConfig.Filter
                Get-ADObject @params
            }
        }

        # Dismiss the query progress bar
        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 10 -Activity "Querying Active Directory" -Completed
        $ProgressPreference = $localProgressPref
        
        # Filter out built-in/system objects
        $objects = @($objects)
        $beforeCount = $objects.Count
        $objects = @($objects | Where-Object { -not (Test-BuiltinObject -ADObject $_) })
        $skippedCount = $beforeCount - $objects.Count
        
        $duration = (Get-Date) - $startTime
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Retrieved $($objects.Count) objects in $($duration.TotalSeconds)s (skipped $skippedCount built-in)" -ForegroundColor Green
        
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
        $additionalProperties = @{}
        
        $excludeFromAdditional = @(
            'PropertyNames',
            'AddedProperties',
            'RemovedProperties',
            'ModifiedProperties',
            'PropertyCount',
            'Modified',
            'Created',
            'CanonicalName',
            'ProtectedFromAccidentalDeletion'
        )

        # Extract OU from DN (similar to migration mapping)
        $sourceOU = ""
        if ($ADObject.distinguishedName) {
            $sourceOUs = (
                ($ADObject.distinguishedName -split ",") |
                Where-Object { $_ -like "OU=*" } |
                ForEach-Object { $_.Substring(3) }
            )
        
            if ($sourceOUs) {
                [array]::Reverse($sourceOUs)
                $sourceOU = $sourceOUs -join "/"
            }
            else {
                if ($ADObject.distinguishedName -match "CN=([^,]+),CN=([^,]+),DC=") {
                    $sourceOU = $matches[2]
                }
                elseif ($ADObject.distinguishedName -match "CN=([^,]+),DC=") {
                    $sourceOU = $matches[1]
                }
            }
        }

        $sourceObject = ''
        if (($ObjectType -eq 'User') -or ($ObjectType -eq 'Group')) {
            $sourceObject = if ($ADObject.sAMAccountName) { $ADObject.sAMAccountName } else { '' }
        }
        elseif ($ObjectType -eq 'Computer') {
            # Remove trailing $ from computer names
            $sourceObject = if ($ADObject.sAMAccountName) { $ADObject.sAMAccountName -replace '\$$', '' } else { '' }
        }
        else {
            $sourceObject = if ($ADObject.cn) { $ADObject.cn } 
            elseif ($ADObject.Name) { $ADObject.Name } 
            else { '' }
        }

        $sourceDisplayName = if ($ADObject.displayName) { $ADObject.displayName } else { '' }

        if ($ObjectType -eq 'Computer') {
            $hash['Source device'] = $sourceObject
            $hash['Source OU'] = $sourceOU
        }
        else {
            $hash['Source object'] = $sourceObject
            $hash['Source display name'] = $sourceDisplayName
            $hash['Source OU'] = $sourceOU
        }

        if ($script:Config.CurrentRequestedProperties.Count -gt 0) {
            foreach ($requestedProp in $script:Config.CurrentRequestedProperties) {
                $hash[$requestedProp] = $null
            }
        }

        foreach ($prop in $ADObject.PSObject.Properties) {
            $propName = $prop.Name
            $propValue = $prop.Value
            
            $isRequested = ($script:Config.CurrentRequestedProperties.Count -eq 0) -or 
            ($propName -in $script:Config.CurrentRequestedProperties)
            
            if ($isRequested) {
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
                        
                        if ($propValue) {
                            $maxLength = 30000  
                            $joined = $propValue -join '; '
                            
                            if ($joined.Length -gt $maxLength) {
                                # Truncate and add indicator
                                $truncated = $joined.Substring(0, $maxLength)
                                # Find last complete group DN (avoid cutting mid-DN)
                                $lastSemicolon = $truncated.LastIndexOf(';')
                                if ($lastSemicolon -gt 0) {
                                    $truncated = $truncated.Substring(0, $lastSemicolon)
                                }
                                "$truncated; [TRUNCATED - Total groups: $($propValue.Count)]"
                            }
                            else {
                                $joined
                            }
                        } 
                        else { 
                            '' 
                        }
                    }
                    'Members' {
                        # Handle group members
                        $hash['MembersCount'] = if ($propValue) { $propValue.Count } else { 0 }
                        
                        # Excel has a 32,767 character limit per cell. Truncate if needed.
                        if ($propValue) {
                            $maxLength = 30000  # Safe limit below Excel's 32,767
                            $joined = $propValue -join '; '
                            
                            if ($joined.Length -gt $maxLength) {
                                # Truncate and add indicator
                                $truncated = $joined.Substring(0, $maxLength)
                                # Find last complete member DN (avoid cutting mid-DN)
                                $lastSemicolon = $truncated.LastIndexOf(';')
                                if ($lastSemicolon -gt 0) {
                                    $truncated = $truncated.Substring(0, $lastSemicolon)
                                }
                                "$truncated; [TRUNCATED - Total members: $($propValue.Count)]"
                            }
                            else {
                                $joined
                            }
                        } 
                        else { 
                            '' 
                        }
                    }
                    'ManagedObjects' {
                        # Excel character limit handling
                        if ($propValue) {
                            $maxLength = 30000
                            $joined = $propValue -join '; '
                            
                            if ($joined.Length -gt $maxLength) {
                                $truncated = $joined.Substring(0, $maxLength)
                                $lastSemicolon = $truncated.LastIndexOf(';')
                                if ($lastSemicolon -gt 0) {
                                    $truncated = $truncated.Substring(0, $lastSemicolon)
                                }
                                "$truncated; [TRUNCATED - Total: $($propValue.Count)]"
                            }
                            else {
                                $joined
                            }
                        } 
                        else { 
                            '' 
                        }
                    }
                    'ServicePrincipalNames' {
                        # Excel character limit handling
                        if ($propValue) {
                            $maxLength = 30000
                            $joined = $propValue -join '; '
                            
                            if ($joined.Length -gt $maxLength) {
                                $truncated = $joined.Substring(0, $maxLength)
                                $lastSemicolon = $truncated.LastIndexOf(';')
                                if ($lastSemicolon -gt 0) {
                                    $truncated = $truncated.Substring(0, $lastSemicolon)
                                }
                                "$truncated; [TRUNCATED - Total: $($propValue.Count)]"
                            }
                            else {
                                $joined
                            }
                        } 
                        else { 
                            '' 
                        }
                    }
                    default {
                        # Handle arrays and collections
                        if ($propValue -is [System.Array] -or 
                            $propValue -is [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]) {
                            
                            # Excel has a 32,767 character limit per cell
                            $maxLength = 30000
                            $joined = $propValue -join '; '
                            
                            if ($joined.Length -gt $maxLength) {
                                # Truncate and add indicator
                                $truncated = $joined.Substring(0, $maxLength)
                                # Find last complete value (avoid cutting mid-value)
                                $lastSemicolon = $truncated.LastIndexOf(';')
                                if ($lastSemicolon -gt 0) {
                                    $truncated = $truncated.Substring(0, $lastSemicolon)
                                }
                                "$truncated; [TRUNCATED - Total count: $($propValue.Count)]"
                            }
                            else {
                                $joined
                            }
                        }
                        elseif ($propValue -is [DateTime]) {
                            $propValue.ToString("yyyyMMddHHmmss.0Z")
                        }
                        else {
                            $propValue
                        }
                    }
                }
            }
            else {
                if ($null -ne $propValue -and $propName -notin $excludeFromAdditional) {
                    # Handle arrays and AD collections
                    if ($propValue -is [System.Array] -or $propValue -is [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]) {
                        $additionalProperties[$propName] = @($propValue)
                    }
                    elseif ($propValue -is [DateTime]) {
                        $additionalProperties[$propName] = $propValue.ToString("yyyyMMddHHmmss.0Z")
                    }
                    elseif ($propValue -is [System.Security.Principal.SecurityIdentifier]) {
                        $additionalProperties[$propName] = $propValue.Value
                    }
                    elseif ($propValue -is [bool]) {
                        $additionalProperties[$propName] = $propValue.ToString()
                    }
                    elseif ($propValue.GetType().Name -match '^HashSet|^SortedSet|^List') {
                        $additionalProperties[$propName] = @($propValue)
                    }
                    elseif ($propValue.GetType().Name -match 'KeyCollection|ValueCollection') {
                        $additionalProperties[$propName] = @($propValue)
                    }
                    elseif ($propValue -is [System.Collections.IEnumerable] -and $propValue -isnot [string]) {
                        try {
                            $additionalProperties[$propName] = @($propValue)
                        }
                        catch {
                            $additionalProperties[$propName] = $propValue.ToString()
                        }
                    }
                    else {
                        try {
                            $strValue = $propValue.ToString()
                            if ($strValue -notmatch '^System\.' -or $strValue.Length -lt 50) {
                                $additionalProperties[$propName] = $strValue
                            }
                            else {
                                $additionalProperties[$propName] = "$propValue"
                            }
                        }
                        catch {
                            $additionalProperties[$propName] = "$propValue"
                        }
                    }
                }
            }
        }
        
        $hash['ScanTimestamp'] = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $hash['ObjectType'] = $ObjectType
        $hash['SourceDomain'] = $script:Config.Domain.DNSRoot
        
        if ($additionalProperties.Count -gt 0) {
            $hash['AdditionalData'] = ($additionalProperties | ConvertTo-Json -Compress -Depth 3)
        }
        else {
            $hash['AdditionalData'] = ''
        }
        
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
        [string]$ObjectType,
        
        [Parameter(Mandatory = $false)]
        [array]$RequestedProperties = @()
    )
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Processing $($Objects.Count) $ObjectType objects..." -ForegroundColor White
    
    try {
        # Set requested properties for tracking additional data
        $script:Config.CurrentRequestedProperties = $RequestedProperties
        
        # Process with progress bar
        $total = $Objects.Count
        $exportData = [System.Collections.Generic.List[PSCustomObject]]::new()
        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        for ($i = 0; $i -lt $total; $i++) {
            $pct = [math]::Round((($i + 1) / $total) * 100)
            Write-Progress -Id 20 -Activity "Processing $ObjectType" -Status "Object $($i + 1) of $total" -PercentComplete $pct
            $result = $Objects[$i] | & $ConverterName
            $exportData.Add($result)
        }
        Write-Progress -Id 20 -Activity "Processing $ObjectType" -Completed
        $ProgressPreference = $localProgressPref
        
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
        
        # Show progress while writing
        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 50 -Activity "Exporting $ObjectType" -Status "Writing $fileName ($($Data.Count) records)..." -PercentComplete 0
        $ProgressPreference = $localProgressPref

        # Export with UTF-8 encoding (matching data engine pattern)
        $Data | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop

        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 50 -Activity "Exporting $ObjectType" -Completed
        $ProgressPreference = $localProgressPref
        
        # Calculate file size
        $fileInfo = Get-Item $filePath
        $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Exported: $fileName" -ForegroundColor Green
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Size: $fileSizeKB KB ($fileSizeMB MB)" -ForegroundColor Gray
        
        return @{
            FilePath    = $filePath
            FileName    = $fileName
            FileSize    = $fileSizeKB
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
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Exporting $ObjectType to Excel XLSX..." -ForegroundColor Cyan
    
    try {
        # Validate and normalize output path
        $OutputPath = $OutputPath.TrimEnd('\', '/')
        
        # Ensure output directory exists and is writable
        if (-not (Test-Path $OutputPath)) {
            try {
                New-Item -ItemType Directory -Path $OutputPath -Force -ErrorAction Stop | Out-Null
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Created directory: $OutputPath" -ForegroundColor Gray
            }
            catch {
                throw "Failed to create output directory '$OutputPath': $($_.Exception.Message)"
            }
        }
        
        # Test write permissions by creating a temp file
        $testFile = Join-Path $OutputPath ".test_write_$(Get-Random).tmp"
        try {
            "test" | Out-File -FilePath $testFile -Force -ErrorAction Stop
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
        catch {
            throw "No write permission for directory '$OutputPath': $($_.Exception.Message)"
        }
        
        # Generate filename following convention: {ObjectType}_Export_yyyyMMdd_HHmmss.xlsx
        $fileName = "${ObjectType}_Export_${Timestamp}.xlsx"
        $filePath = Join-Path $OutputPath $fileName
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Target file: $filePath" -ForegroundColor Gray
        
        # Check if file is locked (already open in Excel)
        if (Test-Path $filePath) {
            try {
                $fileStream = [System.IO.File]::Open($filePath, 'Open', 'ReadWrite', 'None')
                $fileStream.Close()
                $fileStream.Dispose()
                Remove-Item $filePath -Force
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Removed existing file" -ForegroundColor Gray
            }
            catch {
                throw "File '$fileName' is locked (may be open in Excel). Please close it and try again."
            }
        }

        # Show progress while writing
        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 50 -Activity "Exporting $ObjectType" -Status "Writing $fileName ($($Data.Count) records)..." -PercentComplete 0
        $ProgressPreference = $localProgressPref
        
        # Export to Excel with professional formatting
        try {
            $Data | Export-Excel -Path $filePath `
                -WorksheetName $ObjectType `
                -AutoSize `
                -TableName "${ObjectType}Table" `
                -TableStyle Medium6 `
                -FreezeTopRow `
                -BoldTopRow `
                -ErrorAction Stop
        }
        catch {
            # Provide detailed error information
            $errorMsg = $_.Exception.Message
            if ($errorMsg -like "*Save*") {
                throw "Failed to save Excel file. Possible causes:`n  - File may be open in Excel`n  - Insufficient disk space`n  - Path too long`n  - Invalid characters in filename`nOriginal error: $errorMsg"
            }
            else {
                throw "Excel export failed: $errorMsg"
            }
        }

        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 50 -Activity "Exporting $ObjectType" -Completed
        $ProgressPreference = $localProgressPref
        
        # Verify file was created and calculate size
        if (-not (Test-Path $filePath)) {
            throw "Export completed but file was not found at: $filePath"
        }
        
        $fileInfo = Get-Item $filePath
        $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Exported: $fileName" -ForegroundColor Green
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Records: $($Data.Count) | Size: $fileSizeKB KB ($fileSizeMB MB)" -ForegroundColor Gray
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Location: $filePath" -ForegroundColor Gray
        
        return @{
            FilePath    = $filePath
            FileName    = $fileName
            FileSize    = $fileSizeKB
            FileSizeMB  = $fileSizeMB
            RecordCount = $Data.Count
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Export failed for $ObjectType" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  OutputPath: $OutputPath" -ForegroundColor Red
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
        # Validate and normalize output path
        $OutputPath = $OutputPath.TrimEnd('\', '/')
        
        # Ensure output directory exists
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force -ErrorAction Stop | Out-Null
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Created directory: $OutputPath" -ForegroundColor Gray
        }
        
        $fileName = "AD_AllObjects_Export_${Timestamp}.xlsx"
        $filePath = Join-Path $OutputPath $fileName
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Target file: $filePath" -ForegroundColor Gray
        
        # Check if file is locked (already open in Excel)
        if (Test-Path $filePath) {
            try {
                $fileStream = [System.IO.File]::Open($filePath, 'Open', 'ReadWrite', 'None')
                $fileStream.Close()
                $fileStream.Dispose()
                Remove-Item $filePath -Force
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Removed existing file" -ForegroundColor Gray
            }
            catch {
                throw "File '$fileName' is locked (may be open in Excel). Please close it and try again."
            }
        }
        
        $totalRecords = 0
        $sheetList = @($AllData.Keys | Sort-Object)
        $totalSheets = $sheetList.Count
        
        # Export each object type to separate worksheet in same workbook
        foreach ($objectType in $sheetList) {
            $data = $AllData[$objectType]
            
            if ($data.Count -gt 0) {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Adding worksheet: $objectType ($($data.Count) records)" -ForegroundColor Gray

                $sheetIndex = [array]::IndexOf($sheetList, $objectType) + 1
                $localProgressPref = $ProgressPreference
                $ProgressPreference = 'Continue'
                Write-Progress -Id 60 -Activity "Exporting Consolidated Workbook" -Status "Worksheet $sheetIndex/$totalSheets — $objectType ($($data.Count) records)" -PercentComplete ([math]::Round(($sheetIndex / ($totalSheets + 1)) * 100))
                $ProgressPreference = $localProgressPref
                
                try {
                    $data | Export-Excel -Path $filePath `
                        -WorksheetName $objectType `
                        -AutoSize `
                        -TableName "${objectType}Table" `
                        -TableStyle Medium6 `
                        -FreezeTopRow `
                        -BoldTopRow `
                        -ErrorAction Stop
                    
                    $totalRecords += $data.Count
                }
                catch {
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to add worksheet '$objectType': $($_.Exception.Message)" -ForegroundColor Red
                    throw
                }
            }
        }
        
        # Add summary worksheet
        $summaryData = foreach ($key in $sheetList) {
            [PSCustomObject]@{
                ObjectType  = $key
                RecordCount = $AllData[$key].Count
                Worksheet   = $key
                ExportedBy  = $script:Config.Domain.CurrentUser
                ExportTime  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
        
        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 60 -Activity "Exporting Consolidated Workbook" -Status "Summary worksheet..." -PercentComplete 95
        $ProgressPreference = $localProgressPref

        try {
            $summaryData | Export-Excel -Path $filePath `
                -WorksheetName "Summary" `
                -AutoSize `
                -TableName "SummaryTable" `
                -TableStyle "Medium9" `
                -FreezeTopRow `
                -BoldTopRow `
                -AutoFilter `
                -ErrorAction Stop
        }
        catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to add Summary worksheet: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }

        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 60 -Activity "Exporting Consolidated Workbook" -Completed
        $ProgressPreference = $localProgressPref
        
        # Verify file was created and get file info
        if (-not (Test-Path $filePath)) {
            throw "Export completed but file was not found at: $filePath"
        }
        
        $fileInfo = Get-Item $filePath
        $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Consolidated export: $fileName" -ForegroundColor Green
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Total records: $totalRecords across $($AllData.Keys.Count) worksheets" -ForegroundColor Gray
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Size: $fileSizeKB KB ($fileSizeMB MB)" -ForegroundColor Gray
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Location: $filePath" -ForegroundColor Gray
        
        return @{
            FilePath       = $filePath
            FileName       = $fileName
            FileSizeKB     = $fileSizeKB
            FileSizeMB     = $fileSizeMB
            RecordCount    = $totalRecords
            WorksheetCount = $AllData.Keys.Count + 1  # +1 for summary sheet
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Consolidated export failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  OutputPath: $OutputPath" -ForegroundColor Red
        Write-Host "  Target file: $fileName" -ForegroundColor Red
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
        $sourceOU = "";
        if ($ADObject.distinguishedName) {
            $sourceOUs = (
                ($ADObject.distinguishedName -split ",") |
                Where-Object { $_ -like "OU=*" } |
                ForEach-Object { $_.Substring(3) }
            )
        
            if ($sourceOUs) {
                [array]::Reverse($sourceOUs)
                $sourceOU = $sourceOUs -join "/"
            }
            else {
                if ($ADObject.distinguishedName -match "CN=([^,]+),CN=([^,]+),DC=") {
                    $sourceOU = $matches[2]
                }
                elseif ($ADObject.distinguishedName -match "CN=([^,]+),DC=") {
                    $sourceOU = $matches[1]
                }
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
            'Source object'                       = $sourceOb
            'Source display name'                 = $sourceDN
            'Source OU'                           = $sourceOU
            'Distinguished name (optional)'       = if ($ADObject.distinguishedName) { $ADObject.distinguishedName } else { '' }
            'Destination object (optional)'       = $sourceOb
            'Destination display name (optional)' = $sourceDN
            'Destination OU'                      = $sourceOU
            'Object type'                         = $ObjectType
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
        [string]$Timestamp,

        [Parameter(Mandatory = $false)]
        [bool]$Combined = $true
    )
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║           CREATING MIGRATION MAPPING FILE                      ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta
    
    try {
        # Collect all mappings into single list
        $allMappings = [System.Collections.Generic.List[PSCustomObject]]::new()
        
        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        $typeList = @($AllScannedObjects.Keys | Sort-Object)
        for ($t = 0; $t -lt $typeList.Count; $t++) {
            $objectType = $typeList[$t]
            $objects = $AllScannedObjects[$objectType]

            if ($objects.Count -gt 0) {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Processing $($objects.Count) $objectType objects..." -ForegroundColor Cyan

                $total = $objects.Count
                for ($i = 0; $i -lt $total; $i++) {
                    $pct = [math]::Round((($i + 1) / $total) * 100)
                    Write-Progress -Id 30 -Activity "Building Migration Mapping" -Status "$objectType — $($i + 1) of $total" -PercentComplete $pct
                    $mapping = ConvertTo-MigrationMapping -ADObject $objects[$i] -ObjectType $objectType
                    $allMappings.Add($mapping)
                }
                Write-Progress -Id 30 -Activity "Building Migration Mapping" -Completed

                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Converted $($objects.Count) $objectType entries" -ForegroundColor Green
            }
        }
        $ProgressPreference = $localProgressPref
        
        if ($allMappings.Count -eq 0) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [WARNING] No objects to export" -ForegroundColor Yellow
            return $null
        }
        
        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] [INFO] Total mapping entries: $($allMappings.Count)" -ForegroundColor White

        # Show breakdown by object type
        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] [INFO] Breakdown by object type:" -ForegroundColor Cyan
        $groups = $allMappings | Group-Object 'Object type'
        foreach ($group in $groups | Sort-Object Name) {
            Write-Host "  - $($group.Name): $($group.Count)" -ForegroundColor White
        }

        if (-not $Combined) {
            # Export one file per object type
            $exportedFiles = [System.Collections.Generic.List[hashtable]]::new()

            foreach ($group in $groups | Sort-Object Name) {
                $objectType  = $group.Name
                $typeMappings = $group.Group

                $fileName = "Migration_${objectType}_Mapping_${Timestamp}.$Extension"
                $filePath = Join-Path $OutputPath $fileName

                if (Test-Path $filePath) { Remove-Item $filePath -Force }

                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Exporting $objectType to: $fileName" -ForegroundColor Cyan

                $localProgressPref2 = $ProgressPreference
                $ProgressPreference = 'Continue'
                Write-Progress -Id 31 -Activity "Writing Mapping File" -Status "$objectType — $fileName ($($typeMappings.Count) records)..." -PercentComplete 0
                $ProgressPreference = $localProgressPref2

                if ($Extension -eq 'csv') {
                    $typeMappings | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
                }
                else {
                    $typeMappings | Export-Excel -Path $filePath `
                        -WorksheetName "Migration Mapping" `
                        -TableName "MappingTable" `
                        -AutoSize
                }

                $localProgressPref2 = $ProgressPreference
                $ProgressPreference = 'Continue'
                Write-Progress -Id 31 -Activity "Writing Mapping File" -Completed
                $ProgressPreference = $localProgressPref2

                $fileInfo  = Get-Item $filePath
                $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
                $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Exported: $fileName ($($typeMappings.Count) records, $fileSizeKB KB)" -ForegroundColor Green

                $exportedFiles.Add(@{
                    FilePath    = $filePath
                    FileName    = $fileName
                    FileSizeKB  = $fileSizeKB
                    FileSizeMB  = $fileSizeMB
                    RecordCount = $typeMappings.Count
                    ObjectType  = $objectType
                })
            }

            return $exportedFiles
        }
        else {
            # Export all mappings to a single combined file
            $fileName = "Migration_Mapping_${Timestamp}.$Extension"
            $filePath = Join-Path $OutputPath $fileName

            if (Test-Path $filePath) { Remove-Item $filePath -Force }

            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Exporting to: $fileName" -ForegroundColor Cyan

            $localProgressPref2 = $ProgressPreference
            $ProgressPreference = 'Continue'
            Write-Progress -Id 31 -Activity "Writing Mapping File" -Status "$fileName ($($allMappings.Count) records)..." -PercentComplete 0
            $ProgressPreference = $localProgressPref2

            if ($Extension -eq 'csv') {
                $allMappings | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
            }
            else {
                $allMappings | Export-Excel -Path $filePath `
                    -WorksheetName "Migration Mapping" `
                    -TableName "MappingTable" `
                    -AutoSize
            }

            $localProgressPref2 = $ProgressPreference
            $ProgressPreference = 'Continue'
            Write-Progress -Id 31 -Activity "Writing Mapping File" -Completed
            $ProgressPreference = $localProgressPref2

            $fileInfo  = Get-Item $filePath
            $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
            $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Migration mapping exported: $fileName" -ForegroundColor Green
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Records: $($allMappings.Count)" -ForegroundColor Gray
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Size: $fileSizeKB KB ($fileSizeMB MB)" -ForegroundColor Gray
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Path: $filePath" -ForegroundColor Gray

            return @{
                FilePath    = $filePath
                FileName    = $fileName
                FileSizeKB  = $fileSizeKB
                FileSizeMB  = $fileSizeMB
                RecordCount = $allMappings.Count
            }
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to export mapping: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}
#endregion

#region Device Migration Mapping Export
function Export-DeviceMigrationMapping {
    <#
    .SYNOPSIS
        Exports device migration mapping file for computers
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$ComputerObjects,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$Timestamp
    )
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║        CREATING DEVICE MIGRATION MAPPING FILE                  ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta
    
    try {
        $deviceMappings = [System.Collections.Generic.List[PSCustomObject]]::new()
        $totalDevices = $ComputerObjects.Count
        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        for ($i = 0; $i -lt $totalDevices; $i++) {
            $computer = $ComputerObjects[$i]
            $pct = [math]::Round((($i + 1) / $totalDevices) * 100)
            Write-Progress -Id 40 -Activity "Building Device Migration Mapping" -Status "Computer $($i + 1) of $totalDevices" -PercentComplete $pct

            # Extract OU from DN
            $sourceOU = ""
            if ($computer.distinguishedName) {
                $sourceOUs = (
                    ($computer.distinguishedName -split ",") |
                    Where-Object { $_ -like "OU=*" } |
                    ForEach-Object { $_.Substring(3) }
                )
            
                if ($sourceOUs) {
                    [array]::Reverse($sourceOUs)
                    $sourceOU = $sourceOUs -join "/"
                }
                else {
                    if ($computer.distinguishedName -match "CN=([^,]+),CN=([^,]+),DC=") {
                        $sourceOU = $matches[2]
                    }
                    elseif ($computer.distinguishedName -match "CN=([^,]+),DC=") {
                        $sourceOU = $matches[1]
                    }
                }
            }

            # Remove trailing $ from computer names
            $deviceName = if ($computer.sAMAccountName) { 
                $computer.sAMAccountName -replace '\$$', '' 
            } else { '' }
            
            # Create device mapping object
            $deviceMappings.Add([PSCustomObject]@{
                'Source device'      = $deviceName
                'Source OU'          = $sourceOU
                'Destination device' = $deviceName
                'Destination OU'     = $sourceOU
            })
        }
        Write-Progress -Id 40 -Activity "Building Device Migration Mapping" -Completed
        $ProgressPreference = $localProgressPref
        
        if ($deviceMappings.Count -eq 0) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [WARNING] No computer objects to export" -ForegroundColor Yellow
            return $null
        }
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Total device mappings: $($deviceMappings.Count)" -ForegroundColor White
        
        # Generate filename
        $fileName = "Device_Migration_Mapping_${Timestamp}.$Extension"
        $filePath = Join-Path $OutputPath $fileName
        
        # Remove existing file
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force
        }
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Exporting to: $fileName" -ForegroundColor Cyan
        
        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 41 -Activity "Writing Device Mapping File" -Status "$fileName ($($deviceMappings.Count) records)..." -PercentComplete 0
        $ProgressPreference = $localProgressPref

        if ($Extension -eq 'csv') {
            # Export to CSV
            $deviceMappings | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        }
        else {
            # Export to Excel
            $deviceMappings | Export-Excel -Path $filePath `
                -WorksheetName "DeviceMapping" `
                -AutoSize `
                -TableName "DeviceMappingTable" `
                -FreezeTopRow `
                -BoldTopRow `
                -AutoFilter
        }

        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 41 -Activity "Writing Device Mapping File" -Completed
        $ProgressPreference = $localProgressPref
        
        # Get file info
        $fileInfo = Get-Item $filePath
        $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Device migration mapping exported: $fileName" -ForegroundColor Green
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Records: $($deviceMappings.Count)" -ForegroundColor Gray
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Size: $fileSizeKB KB" -ForegroundColor Gray
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] Path: $filePath" -ForegroundColor Gray
        
        return @{
            FilePath    = $filePath
            FileName    = $fileName
            FileSizeKB  = $fileSizeKB
            RecordCount = $deviceMappings.Count
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to export device mapping: $($_.Exception.Message)" -ForegroundColor Red
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
        
        if (-not (Initialize-ADModule)) {
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
        $computerObjects = @()

        # Process each object type
        $configList = @($configsToProcess)
        $totalTypes = $configList.Count
        $typeIndex = 0
        foreach ($config in $configList) {
            $typeIndex++
            $localProgressPref = $ProgressPreference
            $ProgressPreference = 'Continue'
            Write-Progress -Id 1 -Activity "AD Object Scanner" -Status "[$typeIndex/$totalTypes] $($config.Name)" -PercentComplete ([math]::Round(($typeIndex / $totalTypes) * 100))
            $ProgressPreference = $localProgressPref
            $objectStartTime = Get-Date
            
            try {
                # Scan
                $objects = Invoke-ADObjectScan -ObjectConfig $config
                
                if ($objects.Count -eq 0) {
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [WARNING] No $($config.Name) objects found" -ForegroundColor Yellow
                    continue
                }

                # Store raw objects for migration mapping
                if ($IncludeMapping) {
                    if ($config.Name -eq 'Computer') {
                        # Store computer objects separately for device migration mapping
                        $computerObjects = $objects
                    }
                    else {
                        $allRawObjects[$config.Name] = $objects
                    }
                }
                
                # Process
                $exportData = Invoke-DataProcessing `
                    -Objects $objects `
                    -ConverterName $config.Converter `
                    -ObjectType $config.Name `
                    -RequestedProperties $config.Properties
                
                #Export
                if ($Extension -eq "csv") {
                    $exportResult = Export-ToCSV `
                        -Data $exportData `
                        -ObjectType $config.Name `
                        -OutputPath $script:Config.OutputPath `
                        -Timestamp $script:Config.Timestamp
                }
                else {
                    $exportResult = Export-ToExcel `
                        -Data $exportData `
                        -ObjectType $config.Name `
                        -OutputPath $script:Config.OutputPath `
                        -Timestamp $script:Config.Timestamp
                }
                
                # Store results
                $script:Config.ScanResults[$config.Name] = @{
                    RecordCount = $exportResult.RecordCount
                    FileName    = $exportResult.FileName
                    FilePath    = $exportResult.FilePath
                    FileSize    = $exportResult.FileSize
                    Duration    = (Get-Date) - $objectStartTime
                }
            }
            catch {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to process $($config.Name): $($_.Exception.Message)" -ForegroundColor Red
                
                $script:Config.ScanResults[$config.Name] = @{
                    RecordCount = 0
                    Error       = $_.Exception.Message
                }
            }
        }

        # Dismiss overall type progress bar
        $localProgressPref = $ProgressPreference
        $ProgressPreference = 'Continue'
        Write-Progress -Id 1 -Activity "AD Object Scanner" -Completed
        $ProgressPreference = $localProgressPref

        # After all objects are scanned, create migration mapping file
        if ($IncludeMapping -and $allRawObjects.Count -gt 0) {
            try {
                $mappingResult = Export-MigrationMapping `
                    -AllScannedObjects $allRawObjects `
                    -OutputPath $script:Config.OutputPath `
                    -Timestamp $script:Config.Timestamp `
                    -Combined $IsCombined
                
                #if ($mappingResult) {
                #    $script:Config.ScanResults['_MigrationMapping'] = $mappingResult
                #}
            }
            catch {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to create migration mapping: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Create device migration mapping file for computers
        if ($IncludeMapping -and $computerObjects.Count -gt 0) {
            try {
                $deviceMappingResult = Export-DeviceMigrationMapping `
                    -ComputerObjects $computerObjects `
                    -OutputPath $script:Config.OutputPath `
                    -Timestamp $script:Config.Timestamp
                
                #if ($deviceMappingResult) {
                #    $script:Config.ScanResults['_DeviceMigrationMapping'] = $deviceMappingResult
                #}
            }
            catch {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to create device migration mapping: $($_.Exception.Message)" -ForegroundColor Red
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
# MIIoZAYJKoZIhvcNAQcCoIIoVTCCKFECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCiGqtuwzl/n27P
# qdKUvAh5d328YCVp0ZF5XrgVeLxlTqCCDZowggawMIIEmKADAgECAhAIrUCyYNKc
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
# EqLoRTGCGiAwghocAgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2ln
# bmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQD3PbKnfwZFFLFp9BUDAdFDAN
# BglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCD1w54NMaZEuZbM7v+XNov7bUB8fbsFt4ZMR8LxucmXzTANBgkq
# hkiG9w0BAQEFAASCAYAupdBXiHQLqAsEhLyE685GBzqhPpa90/Rhq+IV41d9xpQp
# wVWVNh3s38l3KalujjB+TRxlJqroyMPV5Vgek2gVS0V0C+2WpFdpQ4TMz6RqQhDh
# kMYpYCO5JG/ARLdL2IALp8KMTO/BuP7bO88ZitOWO6hT3QBwu10aUJG/T80OiqYM
# ODF7RwDCt5RQxxYpmUDUaUxFxxJVDl2kt8BPBoGqFEYs7L717+ZhCjJbBUYHmfv2
# b5iGb/jj8V/cjE1OnCXDybJQ/ABE6+9wXg5qjofG79keBrEzzpvGVVhYpNFlGmQG
# P8+/68zhhJ7MfS4UOIMDkdiuT/Xl+nLWvHixiNul4oQyZqkAymiT1Xo8O/nHD+mj
# iA1Reu+0IzXhunuLHgmTBg38fzd0ctf1nPjSzFSkcTyknUgB+W9xIPi6FkLjsBFp
# s+9fylUeWEHMhv3YtovayI30/rcflbBsYcI8y+HaW/nedjXG4L4TMovBAh2Hbv4l
# gC5tc6IAxmBv9t/fqLGhghd2MIIXcgYKKwYBBAGCNwMDATGCF2IwghdeBgkqhkiG
# 9w0BBwKgghdPMIIXSwIBAzEPMA0GCWCGSAFlAwQCAQUAMHcGCyqGSIb3DQEJEAEE
# oGgEZjBkAgEBBglghkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQgPnwaR7fwZoo+
# 3JycU/VbJtCGjfaR+lSvrGLb47smGbQCEDBOVqMrcIPe0qQN9TS09kMYDzIwMjYw
# NjA0MDUxNTEyWqCCEzowggbtMIIE1aADAgECAhAKgO8YS43xBYLRxHanlXRoMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcg
# UlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwHhcNMjUwNjA0MDAwMDAwWhcNMzYwOTAz
# MjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4x
# OzA5BgNVBAMTMkRpZ2lDZXJ0IFNIQTI1NiBSU0E0MDk2IFRpbWVzdGFtcCBSZXNw
# b25kZXIgMjAyNSAxMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0Eas
# LRLGntDqrmBWsytXum9R/4ZwCgHfyjfMGUIwYzKomd8U1nH7C8Dr0cVMF3BsfAFI
# 54um8+dnxk36+jx0Tb+k+87H9WPxNyFPJIDZHhAqlUPt281mHrBbZHqRK71Em3/h
# CGC5KyyneqiZ7syvFXJ9A72wzHpkBaMUNg7MOLxI6E9RaUueHTQKWXymOtRwJXcr
# cTTPPT2V1D/+cFllESviH8YjoPFvZSjKs3SKO1QNUdFd2adw44wDcKgH+JRJE5Qg
# 0NP3yiSyi5MxgU6cehGHr7zou1znOM8odbkqoK+lJ25LCHBSai25CFyD23DZgPfD
# rJJJK77epTwMP6eKA0kWa3osAe8fcpK40uhktzUd/Yk0xUvhDU6lvJukx7jphx40
# DQt82yepyekl4i0r8OEps/FNO4ahfvAk12hE5FVs9HVVWcO5J4dVmVzix4A77p3a
# wLbr89A90/nWGjXMGn7FQhmSlIUDy9Z2hSgctaepZTd0ILIUbWuhKuAeNIeWrzHK
# YueMJtItnj2Q+aTyLLKLM0MheP/9w6CtjuuVHJOVoIJ/DtpJRE7Ce7vMRHoRon4C
# WIvuiNN1Lk9Y+xZ66lazs2kKFSTnnkrT3pXWETTJkhd76CIDBbTRofOsNyEhzZtC
# GmnQigpFHti58CSmvEyJcAlDVcKacJ+A9/z7eacCAwEAAaOCAZUwggGRMAwGA1Ud
# EwEB/wQCMAAwHQYDVR0OBBYEFOQ7/PIx7f391/ORcWMZUEPPYYzoMB8GA1UdIwQY
# MBaAFO9vU0rp5AZ8esrikFb2L9RJ7MtOMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDCBlQYIKwYBBQUHAQEEgYgwgYUwJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBdBggrBgEFBQcwAoZRaHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0YW1waW5n
# UlNBNDA5NlNIQTI1NjIwMjVDQTEuY3J0MF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGlu
# Z1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjAL
# BglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAGUqrfEcJwS5rmBB7NEIRJ5j
# QHIh+OT2Ik/bNYulCrVvhREafBYF0RkP2AGr181o2YWPoSHz9iZEN/FPsLSTwVQW
# o2H62yGBvg7ouCODwrx6ULj6hYKqdT8wv2UV+Kbz/3ImZlJ7YXwBD9R0oU62Ptgx
# Oao872bOySCILdBghQ/ZLcdC8cbUUO75ZSpbh1oipOhcUT8lD8QAGB9lctZTTOJM
# 3pHfKBAEcxQFoHlt2s9sXoxFizTeHihsQyfFg5fxUFEp7W42fNBVN4ueLaceRf9C
# q9ec1v5iQMWTFQa0xNqItH3CPFTG7aEQJmmrJTV3Qhtfparz+BW60OiMEgV5GWoB
# y4RVPRwqxv7Mk0Sy4QHs7v9y69NBqycz0BZwhB9WOfOu/CIJnzkQTwtSSpGGhLdj
# nQ4eBpjtP+XB3pQCtv4E5UCSDag6+iX8MmB10nfldPF9SVD7weCC3yXZi/uuhqdw
# kgVxuiMFzGVFwYbQsiGnoa9F5AaAyBjFBtXVLcKtapnMG3VH3EmAp/jsJ3FVF3+d
# 1SVDTmjFjLbNFZUWMXuZyvgLfgyPehwJVxwC+UpX2MSey2ueIu9THFVkT+um1vsh
# ETaWyQo8gmBto/m3acaP9QsuLj3FNwFlTxq25+T4QwX9xa6ILs84ZPvmpovq90K8
# eWyG2N01c4IhSOxqt81nMIIGtDCCBJygAwIBAgIQDcesVwX/IZkuQEMiDDpJhjAN
# BgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQg
# SW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2Vy
# dCBUcnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3MDAwMDAwWhcNMzgwMTE0MjM1OTU5
# WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNV
# BAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hB
# MjU2IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtHgx
# 0wqYQXK+PEbAHKx126NGaHS0URedTa2NDZS1mZaDLFTtQ2oRjzUXMmxCqvkbsDpz
# 4aH+qbxeLho8I6jY3xL1IusLopuW2qftJYJaDNs1+JH7Z+QdSKWM06qchUP+AbdJ
# gMQB3h2DZ0Mal5kYp77jYMVQXSZH++0trj6Ao+xh/AS7sQRuQL37QXbDhAktVJMQ
# bzIBHYJBYgzWIjk8eDrYhXDEpKk7RdoX0M980EpLtlrNyHw0Xm+nt5pnYJU3Gmq6
# bNMI1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC2ZQ8BbfnFRQVESYOszFI2Wv82wnJ
# RfN20VRS3hpLgIR4hjzL0hpoYGk81coWJ+KdPvMvaB0WkE/2qHxJ0ucS638ZxqU1
# 4lDnki7CcoKCz6eum5A19WZQHkqUJfdkDjHkccpL6uoG8pbF0LJAQQZxst7VvwDD
# jAmSFTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8hjj/q8d6ylgxCZSKi17yVp2NL+cn
# T6Toy+rN+nM8M7LnLqCrO2JP3oW//1sfuZDKiDEb1AQ8es9Xr/u6bDTnYCTKIsDq
# 1BtmXUqEG1NqzJKS4kOmxkYp2WyODi7vQTCBZtVFJfVZ3j7OgWmnhFr4yUozZtqg
# PrHRVHhGNKlYzyjlroPxul+bgIspzOwbtmsgY1MCAwEAAaOCAV0wggFZMBIGA1Ud
# EwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9vU0rp5AZ8esrikFb2L9RJ7MtOMB8G
# A1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjAT
# BgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYD
# VR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9
# bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsWgBz+Bz0RdnEwvb4LyLU0pn/N0IfF
# iBowf0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j00DNqhCT3t+s8G0iP5kvN2n7Jd2E4
# /iEIUBO41P5F448rSYJ59Ib61eoalhnd6ywFLerycvZTAz40y8S4F3/a+Z1jEMK/
# DMm/axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2e26MHvVY9gCDA/JYsq7pGdogP8HR
# trYfctSLANEBfHU16r3J05qX3kId+ZOczgj5kjatVB+NdADVZKON/gnZruMvNYY2
# o1f4MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXuvTPSegOOzr4EWj7PtspIHBldNE2K
# 9i697cvaiIo2p61Ed2p8xMJb82Yosn0z4y25xUbI7GIN/TpVfHIqQ6Ku/qjTY6hc
# 3hsXMrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZjE4YtL8Pbzg0c1ugMZyZZd/BdHLi
# Ru7hAWE6bTEm4XYRkA6Tl4KSFLFk43esaUeqGkH/wyW4N7OigizwJWeukcyIPbAv
# jSabnf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQsfch28bZeUz2rtY/9TCA6TD8dC3J
# E3rYkrhLULy7Dc90G6e8BlqmyIjlgp2+VqsS9/wQD7yFylIz0scmbKvFoW2jNrbM
# 1pD2T7m3XDCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ4ghAGFowDQYJKoZIhvcN
# AQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcG
# A1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJl
# ZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMxMTEwOTIzNTk1OVowYjEL
# MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3
# LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv+aQc2jeu+RdSjwwIjBp
# M+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/MbpDgW61bGl20dq7J58soR
# 0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlqczKU0RBEEC7fgvMHhOZ0
# O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxbGrzryc/NrDRAX7F6Zu53
# yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcvak17cjo+A2raRmECQecN4
# x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sEcypukQF8IUzUvK4bA3Vd
# eGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ckXEaPZPfBaYh2mHY9WV1C
# doeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA5EUlibaaRBkrfsCUtNJh
# besz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFjGESVGnZifvaAsPvoZKYz
# 0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+Jqy2QXXeeqxfjT/JvNNB
# ERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotPwtZFX50g/KEexcCPorF+
# CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8GA1UdEwEB/wQFMAMBAf8w
# HQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8GA1UdIwQYMBaAFEXroq/0
# ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5BggrBgEFBQcBAQRtMGsw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcw
# AoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElE
# Um9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMBEGA1UdIAQKMAgwBgYE
# VR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhfoKN0Gz22Ftf3v1cHvZqs
# oYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv9P+Aufih9/Jy3iS8UgPI
# TtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZy51PpwYDE3cnRNTnf+hZ
# qPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTVPeix3P0c2PR3WlxUjG/v
# oVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGyWfVVa88nq2x2zm8jLfR+
# cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3AamfV6peKOK5lDGCA3wwggN4
# AgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEw
# PwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2
# IFNIQTI1NiAyMDI1IENBMQIQCoDvGEuN8QWC0cR2p5V0aDANBglghkgBZQMEAgEF
# AKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8X
# DTI2MDYwNDA1MTUxMlowKwYLKoZIhvcNAQkQAgwxHDAaMBgwFgQU3WIwrIYKLTBr
# 2jixaHlSMAf7QX4wLwYJKoZIhvcNAQkEMSIEIMyF+5naX4g5FWwjF8+FzvzsWOM8
# mFDSAV36HlOg4SGAMDcGCyqGSIb3DQEJEAIvMSgwJjAkMCIEIEqgP6Is11yExVyT
# j4KOZ2ucrsqzP+NtJpqjNPFGEQozMA0GCSqGSIb3DQEBAQUABIICAMT5hZl6T5pC
# 5ziT7u1B2/phRoCxELYNRM/or6/P3ZbxHnnIxpprJhH3ep5Pwzyf8hYSeKFha6o1
# kjyzb901CF29kcbc3oQPNTXZxUH9xhFAg4a5Xn5CuT6iTYx0xtJofkTVOBkvp/4B
# yz1mwhIQfKe1NHU+m/rKPgtocDNxYwqFG+Pr191UQvkWvjbKyJJEnKFkFWguF60o
# IakZKH/l3EhaO3VXfilsYF1qePmV/fzRnwf8AAMk6GWo7/W+vQ3Waki7swM9ONth
# JLa/Cgw+11by/P4ISnwscTXZMQquP9NQTQUr4tMo2KVH4JEH7+PlJ5fyGF3R/rOh
# pzcdkPxGSFl1o0f9j5Wisy6Omkw3HA+Ryx2jmcf90kuAwc6akZTnKuYpbn5YZX3c
# 610RcAZPJ1nP0g/YoV3lS8Saeusuw5Udi5jgydippjmGc5V/Mhh93Xr3llFgC+7v
# hp1LyLgX0h4/sa+Cp5nYp0E4VEmYlqcjE0w4uZiihyzs8P7t8ddHpmIoOOAUBdP+
# 19aN7zNc6yxS5hNJ03TpTQSu4//c3hxAZ9Ezjas4v8gA/dHPvaNJIIBTRvyMW9XH
# GK7VpumjNM6BwLHRnj1morEXkgRwz3a0AE6SRKY2B4JP8VMeO7FEli8k3Ibc1vuX
# //4MIfn5Cf6nvFBLmMJSUtR1uy3O7nih
# SIG # End signature block
