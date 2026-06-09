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

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputFilePath,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = ".\OwnerChange_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

# Validate input file exists
if (-not (Test-Path $InputFilePath)) {
    Write-Host "[ERROR] Input file not found: $InputFilePath" -ForegroundColor Red
    exit 1
}

# Detect and validate file extension
$Extension = [System.IO.Path]::GetExtension($InputFilePath).TrimStart('.').ToLower()
if ($Extension -notin @('csv', 'xlsx')) {
    Write-Host "[ERROR] Unsupported file format: .$Extension" -ForegroundColor Red
    Write-Host "[ERROR] Only CSV and XLSX files are supported" -ForegroundColor Red
    exit 1
}

# Install Microsoft.Graph module if needed
if (!(Get-Module Microsoft.Graph -ListAvailable | Where-Object {$_.Version -eq "2.29.1"})) {
    Write-Host "Installing Microsoft.Graph 2.29.1..." -ForegroundColor Yellow
    try {
        Install-Module Microsoft.Graph -RequiredVersion 2.29.1 -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "[SUCCESS] Microsoft.Graph installed via Install-Module." -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Install-Module failed. Attempting direct download fallback..." -ForegroundColor Yellow
        try {
            $mgModules = @(
                "Microsoft.Graph.Authentication",
                "Microsoft.Graph.Identity.DirectoryManagement",
                "Microsoft.Graph.Users"
            )
            foreach ($moduleName in $mgModules) {
                try {
                    Import-Module $moduleName -ErrorAction Stop
                    Write-Host "  [INFO] $moduleName already available, skipping download" -ForegroundColor Cyan
                    continue
                } catch {
                    # Module not available, proceed with download
                }
                
                $modulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$moduleName"
                if (-not (Test-Path $modulePath)) {
                    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
                }
                
                Write-Host "  Downloading $moduleName..." -ForegroundColor Cyan
                $webClient = New-Object System.Net.WebClient
                $moduleUrl = "https://www.powershellgallery.com/api/v2/package/$moduleName/2.29.1"
                $nupkgFile = Join-Path $env:TEMP "$moduleName.nupkg"
                $zipFile   = Join-Path $env:TEMP "$moduleName.zip"

                $webClient.DownloadFile($moduleUrl, $nupkgFile)
                Copy-Item $nupkgFile $zipFile -Force

                if (Test-Path $modulePath) {
                    Remove-Item $modulePath -Recurse -Force -ErrorAction SilentlyContinue
                }

                Write-Host "  Extracting $moduleName..." -ForegroundColor Cyan
                Expand-Archive -Path $zipFile -DestinationPath $modulePath -Force -ErrorAction SilentlyContinue

                Remove-Item $nupkgFile -Force -ErrorAction SilentlyContinue
                Remove-Item $zipFile   -Force -ErrorAction SilentlyContinue

                Write-Host "  [SUCCESS] $moduleName installed via direct download." -ForegroundColor Green
            }

            Import-Module Microsoft.Graph.Authentication -Force -ErrorAction Stop
            Import-Module Microsoft.Graph.Identity.DirectoryManagement -Force -ErrorAction Stop
            Import-Module Microsoft.Graph.Users -Force -ErrorAction Stop
            Write-Host "[SUCCESS] Microsoft.Graph modules imported successfully." -ForegroundColor Green
            
        } catch {
            Write-Host "[ERROR] Failed to install Microsoft.Graph via direct download: $_" -ForegroundColor Red
            Write-Host "Please install Microsoft.Graph 2.29.1 manually and re-run this script." -ForegroundColor Red
            exit 1
        }
    }
}

# Install ImportExcel module if xlsx format is requested
if ($Extension -eq 'xlsx') {
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Write-Host "Installing ImportExcel module..." -ForegroundColor Yellow
        
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            
            Install-Module -Name ImportExcel -Scope CurrentUser -Force -ErrorAction Stop
            Write-Host "[SUCCESS] ImportExcel module installed via Install-Module" -ForegroundColor Green
        }
        catch {
            Write-Host "[WARN] Install-Module failed. Attempting direct download fallback..." -ForegroundColor Yellow
            
            try {
                try {
                    Import-Module ImportExcel -ErrorAction Stop
                    Write-Host "[INFO] ImportExcel already available, skipping download" -ForegroundColor Cyan
                } catch {
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
                        Remove-Item $modulePath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    
                    Write-Host "  Extracting module files..." -ForegroundColor Cyan
                    Expand-Archive -Path $zipFile -DestinationPath $modulePath -Force -ErrorAction SilentlyContinue
                    
                    Remove-Item $nupkgFile -Force -ErrorAction SilentlyContinue
                    Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
                    
                    Write-Host "[SUCCESS] ImportExcel module installed via direct download" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "[ERROR] Failed to install ImportExcel module: $_" -ForegroundColor Red
                Write-Host "Please install ImportExcel module manually and re-run this script." -ForegroundColor Red
                Write-Host "  Install-Module -Name ImportExcel -Scope CurrentUser" -ForegroundColor Gray
                exit 1
            }
        }
        
        if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
            Write-Host "[ERROR] ImportExcel module installation verification failed!" -ForegroundColor Red
            exit 1
        }
    }
    
    Import-Module ImportExcel -ErrorAction Stop
    Write-Host "[SUCCESS] ImportExcel module loaded" -ForegroundColor Green
}

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Device.ReadWrite.All","User.Read.All","Directory.AccessAsUser.All"

$org = Get-MgOrganization
$context = Get-MgContext
Write-Host "`n+----------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "|                      TENANT INFORMATION                        |" -ForegroundColor Cyan
Write-Host "+----------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host " Tenant Name   : $($org.DisplayName)" -ForegroundColor Yellow 
Write-Host " Tenant ID     : $($org.Id)" -ForegroundColor Yellow 
Write-Host " Signed in as  : $($context.Account)" -ForegroundColor Yellow 
Write-Host " Scopes        : $($context.Scopes -join ', ')" -ForegroundColor Yellow 
Write-Host "+----------------------------------------------------------------+`n" -ForegroundColor Cyan

# Import device data from file
Write-Host "Importing device data from file..." -ForegroundColor Cyan
if ($Extension -eq 'xlsx') {
    $deviceData = Import-Excel -Path $InputFilePath
} else {
    $deviceData = Import-Csv -Path $InputFilePath
}

Write-Host "[INFO] Found $($deviceData.Count) device entries in file" -ForegroundColor Cyan
Write-Host "`nStarting batch owner update process...`n" -ForegroundColor Yellow

# Initialize counters
$successCount = 0
$failureCount = 0
$skippedCount = 0
$logEntries = @()

# Process each device
$counter = 0
foreach ($entry in $deviceData) {
    $counter++
    $deviceName = $entry.DeviceName
    $deviceId = $entry.ObjectId
    $newOwnerUPN = $entry.OwnerUPN
    
    Write-Host "[$counter/$($deviceData.Count)] Processing: $deviceName" -ForegroundColor Cyan
    
    $logEntry = [PSCustomObject]@{
        DeviceName = $deviceName
        DeviceId = $deviceId
        NewOwnerUPN = $newOwnerUPN
        Status = ""
        Message = ""
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    try {
        # Skip if explicitly marked as "No Owner"
        if ($newOwnerUPN -eq "No Owner") {
            Write-Host "  [SKIP] No owner change requested (marked as 'No Owner')" -ForegroundColor Gray
            $skippedCount++
            $logEntry.Status = "Skipped"
            $logEntry.Message = "No owner change requested"
            $logEntries += $logEntry
            continue
        }
        
        # Verify device exists
        try {
            $device = Get-MgDevice -DeviceId $deviceId -ErrorAction Stop
        } catch {
            Write-Host "  [ERROR] Device not found in Azure AD" -ForegroundColor Red
            $failureCount++
            $logEntry.Status = "Failed"
            $logEntry.Message = "Device not found in Azure AD"
            $logEntries += $logEntry
            continue
        }
        
        # Get current owners
        $currentOwners = Get-MgDeviceRegisteredOwner -DeviceId $deviceId -All -ErrorAction SilentlyContinue
        
        # Handle empty/whitespace - reset owner to none
        if ([string]::IsNullOrWhiteSpace($newOwnerUPN)) {
            Write-Host "  [INFO] Resetting device to no owner" -ForegroundColor Cyan
            
            # Remove all current owners
            if ($currentOwners) {
                foreach ($currentOwner in $currentOwners) {
                    try {
                        Remove-MgDeviceRegisteredOwnerByRef -DeviceId $deviceId -DirectoryObjectId $currentOwner.Id -ErrorAction Stop
                        Write-Host "  [INFO] Removed owner: $($currentOwner.Id)" -ForegroundColor Gray
                    } catch {
                        Write-Host "  [WARN] Failed to remove owner: $($currentOwner.Id)" -ForegroundColor Yellow
                    }
                }
                Write-Host "  [SUCCESS] Device owner reset to none" -ForegroundColor Green
                $successCount++
                $logEntry.Status = "Success"
                $logEntry.Message = "Owner reset to none"
            } else {
                Write-Host "  [SKIP] Device already has no owner" -ForegroundColor Yellow
                $skippedCount++
                $logEntry.Status = "Skipped"
                $logEntry.Message = "Device already has no owner"
            }
            
            $logEntries += $logEntry
            continue
        }
        
        # Get new owner user object
        try {
            $newOwner = Get-MgUser -UserId $newOwnerUPN -ErrorAction Stop
        } catch {
            Write-Host "  [ERROR] User not found: $newOwnerUPN" -ForegroundColor Red
            $failureCount++
            $logEntry.Status = "Failed"
            $logEntry.Message = "User not found: $newOwnerUPN"
            $logEntries += $logEntry
            continue
        }
        
        # Check if the new owner is already the owner
        if ($currentOwners.Id -contains $newOwner.Id) {
            Write-Host "  [SKIP] User is already an owner" -ForegroundColor Yellow
            $skippedCount++
            $logEntry.Status = "Skipped"
            $logEntry.Message = "User is already an owner"
            $logEntries += $logEntry
            continue
        }
        
        # Remove current owners
        if ($currentOwners) {
            foreach ($currentOwner in $currentOwners) {
                try {
                    Remove-MgDeviceRegisteredOwnerByRef -DeviceId $deviceId -DirectoryObjectId $currentOwner.Id -ErrorAction Stop
                    Write-Host "  [INFO] Removed current owner: $($currentOwner.Id)" -ForegroundColor Gray
                } catch {
                    Write-Host "  [WARN] Failed to remove current owner: $($currentOwner.Id)" -ForegroundColor Yellow
                }
            }
        }
        
        # Add new owner
        New-MgDeviceRegisteredOwnerByRef -DeviceId $deviceId -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$($newOwner.Id)" -ErrorAction Stop
        Write-Host "  [SUCCESS] Owner updated to: $newOwnerUPN" -ForegroundColor Green
        $successCount++
        $logEntry.Status = "Success"
        $logEntry.Message = "Owner successfully updated"
        $logEntries += $logEntry
        
    } catch {
        Write-Host "  [ERROR] Failed to update owner: $_" -ForegroundColor Red
        $failureCount++
        $logEntry.Status = "Failed"
        $logEntry.Message = $_.Exception.Message
        $logEntries += $logEntry
    }
    
    Write-Host ""
}

# Display summary
Write-Host "`n+----------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "|                        UPDATE SUMMARY                          |" -ForegroundColor Cyan
Write-Host "+----------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host " Total Processed : $($deviceData.Count)" -ForegroundColor Yellow
Write-Host " Successful      : $successCount" -ForegroundColor Green
Write-Host " Failed          : $failureCount" -ForegroundColor Red
Write-Host " Skipped         : $skippedCount" -ForegroundColor Gray
Write-Host "+----------------------------------------------------------------+`n" -ForegroundColor Cyan

# Export log file
$logEntries | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8
Write-Host "[INFO] Log file exported to: $LogPath" -ForegroundColor Cyan

if ($failureCount -gt 0) {
    Write-Host "`n+----------------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "|                    COMPLETED WITH ERRORS                       |" -ForegroundColor Yellow
    Write-Host "+----------------------------------------------------------------+`n" -ForegroundColor Yellow
} else {
    Write-Host "`n+----------------------------------------------------------------+" -ForegroundColor Green
    Write-Host "|                 UPDATE COMPLETED SUCCESSFULLY                  |" -ForegroundColor Green
    Write-Host "+----------------------------------------------------------------+`n" -ForegroundColor Green
}
# SIG # Begin signature block
# MIIoZQYJKoZIhvcNAQcCoIIoVjCCKFICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAIB4xCHD3SoQDL
# 68+gAb7l/O4tMunvEcs/PqB1zCkn/6CCDZowggawMIIEmKADAgECAhAIrUCyYNKc
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
# SIb3DQEJBDEiBCAzA1FiUsrIwxcGJaO3GIv43G69bay7vSAH7fSHwSkKLDANBgkq
# hkiG9w0BAQEFAASCAYDbFT2anZbwkczyVUPnDZu3u0scmcBejcfmIpRHG3JPPf/h
# OsJjJyeGLJZT/Av3LdLwh+PW1616x31tMpYvOkoY/dDihkeQ2GzYHAmgw1vnTmOy
# XAPTyQnxv/TqHHp01/0nAhe9OYBCbjH244i0YsURBi2Tc7aHspkBaEp0z0rxg8ze
# v0fxrWbJY69Tn+0j+5Q20rAl/vwwz26lm/qJWxrz1cH13W8nWkakq2hu238VBcU0
# y490wjoKw6TTz+Yyqe9i+1oz8GBdQ98X1M+bd4JXuYgX6duTcEUTEWVfip8zBTOK
# IGKJzp7ies3q3OqvMF6WhoL8dhmMoUMmLnokS6C59BqWGscPoOpipxHkjan8VH3E
# 2A9fJFJGZpmXK03ke1AGnx75wq39b+CehM+ZIYvhInoGhd1lh98YtK/Liuvn3QaL
# yFowraF4zv7X3t8Y3NHUW2znsgvNkl6s4ZWpL/vapluUSvEhsms4fGjJMosNtZKe
# T7neHxHlRhFbIrv1N6uhghd3MIIXcwYKKwYBBAGCNwMDATGCF2MwghdfBgkqhkiG
# 9w0BBwKgghdQMIIXTAIBAzEPMA0GCWCGSAFlAwQCAQUAMHgGCyqGSIb3DQEJEAEE
# oGkEZzBlAgEBBglghkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQgCVp1nLqm1SpJ
# HvV7uKB3f9aHXGMY8DxXhfhkpANruloCEQC0FZBHGviz6jlXnMaghgPiGA8yMDI2
# MDYwNDA1MTIyOFqgghM6MIIG7TCCBNWgAwIBAgIQCoDvGEuN8QWC0cR2p5V0aDAN
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
# Fw0yNjA2MDQwNTEyMjhaMCsGCyqGSIb3DQEJEAIMMRwwGjAYMBYEFN1iMKyGCi0w
# a9o4sWh5UjAH+0F+MC8GCSqGSIb3DQEJBDEiBCBpf+TQUsT1AywU9izcHlm0j3Iw
# yRvJqXu1RYZL+Z5/YzA3BgsqhkiG9w0BCRACLzEoMCYwJDAiBCBKoD+iLNdchMVc
# k4+CjmdrnK7Ksz/jbSaaozTxRhEKMzANBgkqhkiG9w0BAQEFAASCAgB68p6nrqUM
# qQqY3a6RfU+cCP9D/iEdnDW+cCK2UolKUL6YW4S0pcz4zHRMvv+tk7ILqjY3YFIx
# s1+e6K0Ok4k0Zy95pRlqu/8TYdyi5/Skdywfr4ckjSiBcHv7xwCOnhksKUGT+HcS
# o6UwFN7S7j6n4JApuRy8WUcQyQLAfgVddOtxz0Y09J9anAFdRxi/mJrf1K8aDJaL
# DUAIz0q8CcVxSBm2IyIxwJwbfrqqu13HXoJjtnG/JwzceMGyT4pNaq/mtA9HKHqM
# nVnhVDPUnFrLbBFYW0oMyzSxOVGj1fZ1XwLB9xjWjrrTavxdCWgztOcjU9PkOxHx
# alu+xrJyivyZ1YvPzorKo+LONC0vny5Oz6SWsaxX9GdrA7R40tfy5uJL8Gdh3/wo
# 6rX1gsMon37tnZHzy0v7ChduCY2mnvenNSsqygHXoRmAWM+q0CBDMwK6dtfnTNky
# XufboFzwwotc+zMu6C9SiNIwzfZsVobghpWXwCKLEYL7Yuik1NX3tArWJQuAKYPH
# tiG9WpMuKlt4UK17Rqc2m4ka0VYbaFulA8yDtPPnh2wq+V9uw7kmUVnuxhnRxNWX
# EHNiZkmAINyzJQbW+803+My8T9Q3AECnLN7bSceLgwUkLzKpcBSZRFcwqgZAilsl
# LNu46fXswjTfvFqRIxbNOrwb+xr7I6554w==
# SIG # End signature block
