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
param(
    [Parameter(Mandatory=$true)]
    [string]$TargetDomain,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Source", "Destination")]
    [string]$TargetDomainType
)

Import-Module ActiveDirectory

do {
    $autoFixInput = Read-Host "Do you want to apply fixes automatically? (Y/N)"
    switch -Regex ($autoFixInput.Trim()) {
        '^(y|yes)$' {
            $AutoFix = $true
            $isValidAutoFixInput = $true
        }
        '^(n|no)$' {
            $AutoFix = $false
            $isValidAutoFixInput = $true
        }
        default {
            Write-Host "Please enter Y or N." -ForegroundColor Yellow
            $isValidAutoFixInput = $false
        }
    }
} while (-not $isValidAutoFixInput)

# Track all errors
$global:ErrorList = @()

function Add-ErrorRecord {
    param([string]$Check, [string]$Message)
    $global:ErrorList += [PSCustomObject]@{
        Check = $Check
        Message = $Message
    }
}

function Set-AdvancedAuditPolicy {
    param([string]$Subcategory, [string]$Expected)
    $success = if ($Expected -match "Success") { "enable" } else { "disable" }
    $failure = if ($Expected -match "Failure") { "enable" } else { "disable" }
    auditpol /set /subcategory:"$Subcategory" /success:$success /failure:$failure | Out-Null
}

function Set-LocalAuditPolicy {
    param([hashtable]$Settings)

    $inf = "$env:TEMP\audit_fix.inf"
    $sdb = "$env:TEMP\audit_fix.sdb"

    $lines = @(
        "[Unicode]"
        "Unicode=yes"
        "[Version]"
        'signature="$CHICAGO$"'
        "Revision=1"
        "[Event Audit]"
    )
    foreach ($k in $Settings.Keys) {
        $lines += "$k = $($Settings[$k])"
    }

    Set-Content -Path $inf -Value $lines -Encoding Unicode
    secedit /configure /db $sdb /cfg $inf /areas SECURITYPOLICY | Out-Null
    Remove-Item $inf, $sdb -ErrorAction SilentlyContinue
}

if ($TargetDomainType -eq "Destination") {
    Write-Host "=== ALIAS GROUP CHECK ==="

    $netbios = (Get-ADDomain).NetBIOSName

    $found = Get-ADGroup -Filter * -Properties groupType, SamAccountName |
    Where-Object {
        ($_.SamAccountName -like ($netbios + '$$$*')) -and
        ($_.groupType -band 0x4) -and
        ($_.groupType -band 0x80000000)
    } |
    Select-Object -First 1

    if ($found) {
        Write-Host "[PASS]: Alias group found -> $($found.SamAccountName)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL]: Alias group NOT found" -ForegroundColor Red
        Add-ErrorRecord -Check "Alias Group" -Message "Alias group NOT found"

        if ($AutoFix) {
            try {
                $aliasName = $netbios + '$$$'
                New-ADGroup -Name $aliasName -SamAccountName $aliasName -GroupScope DomainLocal -GroupCategory Security -ErrorAction Stop
                Write-Host "[FIXED]: Created alias group -> $aliasName" -ForegroundColor Cyan
            } catch {
                Write-Host "[FIX FAILED]: Unable to create alias group -> $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "=== ALIAS GROUP CHECK ==="
    Write-Host "[SKIP]: Alias group check is not required for Source domain" -ForegroundColor Yellow
}


if ($TargetDomainType -eq "Destination") {
    Write-Host "=== Tcpip Client Support CHECK ==="
    $tcpipClientSupportPath = "HKLM:\SYSTEM\CurrentControlSet\Control\LSA"
    $tcpipClientSupportName = "TcpipClientSupport"

    try {
        $value = (Get-ItemProperty -Path $tcpipClientSupportPath -Name $tcpipClientSupportName -ErrorAction Stop).$tcpipClientSupportName

        if ($value -eq 1) {
            Write-Host "[PASS]: TcpipClientSupport = 1" -ForegroundColor Green
        } else {
            Write-Host "[FAIL]: TcpipClientSupport = $value (expected 1)" -ForegroundColor Red
            Add-ErrorRecord -Check "TcpipClientSupport" -Message "Value is $value (expected 1)"

            if ($AutoFix) {
                try {
                    Set-ItemProperty -Path $tcpipClientSupportPath -Name $tcpipClientSupportName -Value 1 -Type DWord -ErrorAction Stop
                    Write-Host "[FIXED]: TcpipClientSupport set to 1" -ForegroundColor Cyan
                } catch {
                    Write-Host "[FIX FAILED]: Unable to set TcpipClientSupport -> $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
    catch {
        Write-Host "FAIL: TcpipClientSupport not found" -ForegroundColor Red
        Add-ErrorRecord -Check "TcpipClientSupport" -Message "Registry key not found"

        if ($AutoFix) {
            try {
                New-ItemProperty -Path $tcpipClientSupportPath -Name $tcpipClientSupportName -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                Write-Host "[FIXED]: Created TcpipClientSupport = 1" -ForegroundColor Cyan
            } catch {
                Write-Host "[FIX FAILED]: Unable to create TcpipClientSupport -> $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "=== Tcpip Client Support CHECK ==="
    Write-Host "[SKIP]: TcpipClientSupport check is not required for Source domain" -ForegroundColor Yellow
}

if ($TargetDomainType -eq "Source") {
    Write-Host "=== LDAP PORT 389 CHECK ($TargetDomain) ==="

    try {
        $ldapPortCheck = Test-NetConnection -ComputerName $TargetDomain -Port 389 -WarningAction SilentlyContinue

        if ($ldapPortCheck.TcpTestSucceeded) {
            Write-Host "[PASS]: Port 389 is open on $TargetDomain" -ForegroundColor Green
        } else {
            Write-Host "[FAIL]: Port 389 is NOT reachable on $TargetDomain" -ForegroundColor Red
            Add-ErrorRecord -Check "LDAP Port 389" -Message "Port 389 is not reachable on $TargetDomain"
        }
    }
    catch {
        Write-Host "[FAIL]: Unable to test port 389 on $TargetDomain" -ForegroundColor Red
        Add-ErrorRecord -Check "LDAP Port 389" -Message "Failed to test port 389 on $TargetDomain"
    }
}

$expected = @{
    "User Account Management"                 = "Success and Failure"
    "Application Group Management"            = "Success and Failure"
    "Computer Account Management"             = "Success and Failure"
    "Distribution Group Management"           = "Success and Failure"
    "Other Account Management Events"         = "Success and Failure"
    "Security Group Management"               = "Success and Failure"
    "Directory Service Access"                = "Success"
    "Detailed Directory Service Replication"  = "Success"
    "Directory Service Changes"               = "Success"
    "Directory Service Replication"           = "Success"
}

$output = auditpol /get /category:*

# Parse result
$result = @{}

foreach ($line in $output) {
    if ($line -match "^\s{2,}(.+?)\s{2,}(.+)$") {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        $result[$name] = $value
    }
}

Write-Host "=== ADVANCED AUDIT POLICY CHECK ==="

$advAuditToFix = @{}

foreach ($key in $expected.Keys) {
    $actual = $result[$key]

    if (-not $actual) {
        Write-Host "[MISSING] $key" -ForegroundColor Yellow
        $advAuditToFix[$key] = $expected[$key]
        continue
    }

    if ($actual -eq $expected[$key]) {
        Write-Host "[PASS] $key -> $actual" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $key -> Expected: $($expected[$key]) | Actual: $actual" -ForegroundColor Red
        Add-ErrorRecord -Check "Advanced Audit Policy" -Message "$key - Expected: $($expected[$key]), Actual: $actual"
        $advAuditToFix[$key] = $expected[$key]
    }
}

if ($AutoFix -and $advAuditToFix.Count -gt 0) {
    $confirm = Read-Host "`nUpdate Advanced Audit Policy settings? (Y/N)"
    if ($confirm -match '^(y|yes)$') {
        foreach ($key in $advAuditToFix.Keys) {
            try {
                Set-AdvancedAuditPolicy -Subcategory $key -Expected $advAuditToFix[$key]
                Write-Host "[FIXED] $key -> $($advAuditToFix[$key])" -ForegroundColor Cyan
            } catch {
                Write-Host "[FIX FAILED] $key -> $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "[SKIP] Advanced Audit Policy fix cancelled by user" -ForegroundColor Yellow
    }
}

$expected = @{
    "User Account Management" = "Success and Failure"
    "Directory Service Access" = "Success"
}

$temp = "$env:TEMP\audit.cfg"
secedit /export /cfg $temp > $null 2>&1

$map = @{
    "AuditAccountManage" = "User Account Management"
    "AuditDSAccess"      = "Directory Service Access"
}

$result = @{}

Get-Content $temp | ForEach-Object {
    foreach ($key in $map.Keys) {
        if ($_ -match "^$key\s*=\s*(\d+)") {
            $val = [int]$matches[1]

            $text = switch ($val) {
                0 { "No Auditing" }
                1 { "Success" }
                2 { "Failure" }
                3 { "Success and Failure" }
            }

            $name = $map[$key]
            $result[$name] = $text
        }
    }
}

Remove-Item $temp -ErrorAction SilentlyContinue

Write-Host "=== LOCAL AUDIT POLICY CHECK ==="

$auditValueMap = @{ "No Auditing" = 0; "Success" = 1; "Failure" = 2; "Success and Failure" = 3 }
$reverseMap = @{}
foreach ($k in $map.Keys) { $reverseMap[$map[$k]] = $k }
$localAuditToFix = @{}

foreach ($key in $expected.Keys) {
    $actual = $result[$key]

    if (-not $actual) {
        Write-Host "[MISSING] $key" -ForegroundColor Yellow
        $localAuditToFix[$reverseMap[$key]] = $auditValueMap[$expected[$key]]
        continue
    }

    if ($actual -eq $expected[$key]) {
        Write-Host "[PASS] $key -> $actual" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $key -> Expected: $($expected[$key]) | Actual: $actual" -ForegroundColor Red
        Add-ErrorRecord -Check "Local Audit Policy" -Message "$key - Expected: $($expected[$key]), Actual: $actual"
        $localAuditToFix[$reverseMap[$key]] = $auditValueMap[$expected[$key]]
    }
}

if ($AutoFix -and $localAuditToFix.Count -gt 0) {
    $confirm = Read-Host "`nUpdate Local Audit Policy settings? (Y/N)"
    if ($confirm -match '^(y|yes)$') {
        try {
            Set-LocalAuditPolicy -Settings $localAuditToFix
            foreach ($k in $localAuditToFix.Keys) {
                Write-Host "[FIXED] $k -> $($localAuditToFix[$k])" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "[FIX FAILED] Local Audit Policy -> $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "[SKIP] Local Audit Policy fix cancelled by user" -ForegroundColor Yellow
    }
}

Write-Host "=== CHECK TRUST WITH $TargetDomain ===" -ForegroundColor Cyan

$sc = nltest /sc_verify:$TargetDomain 2>&1

$match = $sc | Where-Object {
    $_ -match "Trust Verification Status\s*=\s*0\s+0x0\s+NERR_Success"
}

if ($match) {
    Write-Host "`n[PASS]: Trust Verification Status = NERR_Success" -ForegroundColor Green
} else {
    Add-ErrorRecord -Check "Trust Verification" -Message "nltest /sc_verify failed for $TargetDomain"
    Write-Host "`n[FAIL]: Trust Verification Status NOT OK" -ForegroundColor Red
}

Write-Host "`n=== CHECK TRUST OBJECT ===" -ForegroundColor Cyan

try {
    $trust = Get-ADTrust -Identity $TargetDomain -ErrorAction Stop

    Write-Host "Trust Type      : $($trust.TrustType)"
    Write-Host "Direction       : $($trust.Direction)"
    Write-Host "Attributes      : $($trust.TrustAttributes)"
}
catch {
    Write-Host "[FAIL] Trust not found in AD" -ForegroundColor Red
    Add-ErrorRecord -Check "Trust Object" -Message "Trust $TargetDomain not found in Active Directory"
    $trust = $null
}

Write-Host "`n=== CHECK SID FILTERING ===" -ForegroundColor Cyan

if ($trust) {
    if ($trust.TrustAttributes -band 0x4) {
        Write-Host "[WARNING] SID Filtering ENABLED (Quarantined), You may need to turn off SID Filtering for migration." -ForegroundColor Yellow
        Add-ErrorRecord -Check "SID Filtering" -Message "SID Filtering is ENABLED (may block SID history migration)"
    } else {
        Write-Host "[PASS] SID Filtering DISABLED" -ForegroundColor Green
    }
} else {
    Write-Host "[SKIP] Cannot check SID filtering (trust object not found)" -ForegroundColor Yellow
}

if ($TargetDomainType -eq "Destination" -and $AutoFix) {
    Write-Host "`n=== FIX: GRANT 'Migrate SID History' TO EVERYONE ===" -ForegroundColor Cyan
    try {
        $domainDN = (Get-ADDomain).DistinguishedName
        dsacls $domainDN /G "Everyone:CA;Migrate SID History" | Out-Null
        Write-Host "[FIXED]: Granted 'Migrate SID History' control access right to Everyone on $domainDN" -ForegroundColor Cyan
    } catch {
        Write-Host "[FIX FAILED]: Unable to grant 'Migrate SID History' -> $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($global:ErrorList.Count -eq 0) {
    Write-Host "`n✓ All checks PASSED" -ForegroundColor Green
} else {
    Write-Host "`n✗ Found $($global:ErrorList.Count) issue(s):`n" -ForegroundColor Red
    
    foreach ($err in $global:ErrorList) {
        Write-Host "  [$($err.Check)] $($err.Message)" -ForegroundColor Red
    }
    
    Write-Host "`nPlease fix the issues above before proceeding with SID history migration.`n" -ForegroundColor Yellow
    Write-Host "[PASS] SID Filtering DISABLED" -ForegroundColor Green
}
# SIG # Begin signature block
# MIIoZAYJKoZIhvcNAQcCoIIoVTCCKFECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDHEpirAIDphLRb
# U/p+y8YdTFj0jpYWqvoInNrO3wxMeqCCDZowggawMIIEmKADAgECAhAIrUCyYNKc
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
# SIb3DQEJBDEiBCA2S3DXuz0vIMl7XmhYfaGXr090sXgnqkSIAUz5LBo92zANBgkq
# hkiG9w0BAQEFAASCAYCrdByEHHD6ty8auYrf4eUsA65VBeHVYmhfX6A3hsLELqlV
# FmBfSFEfTZxO+uTamG8SqxRqjsxEVuXVrCK2br+riWqJ80VIJ3YI6zrQrh5MBqsu
# B7YnGXs/8iG8wkjr9PWaimxTS2lF1cHN638ts3AiXY16y0SSCI0W/0POR5Udqd4r
# fCgdwofCdyImnd7wtjxfIwd+HcttBV/jXTwiPAg+LIRG1w8ivNTCcuCmxz6rlKO0
# 6DDPrLWVIFgyStvNTne4bCG6OBOqw8wInBTHi/iH0Iesw3a5Of0lRq+Fu8pnVUDE
# ItUwdtOpQEWJUfGpdc72SzmHtX2mfC2RjAmY/2b9iPsPEUEWcJdyxtQoR0XeLDFI
# Bm4CvMNSDgQDvrrJrQfnNFo215FYVALZw1nxttEOJW4Cae3+IoHxX3fKSsTTcLRN
# ciGouscw+5/7vxPzrRfnU2SEyj0kuKISQZKTCA9mscRnKHYKAG84PpD85SwxhZT7
# 479ZuryL9RFxhBw7URuhghd2MIIXcgYKKwYBBAGCNwMDATGCF2IwghdeBgkqhkiG
# 9w0BBwKgghdPMIIXSwIBAzEPMA0GCWCGSAFlAwQCAQUAMHcGCyqGSIb3DQEJEAEE
# oGgEZjBkAgEBBglghkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQgn0BuqDgMBMrg
# hbemNISPIICAaWujx9jr9CrCvpxAROcCEH7p2u9bW5BEvRBKvpzmKxgYDzIwMjYx
# MDE0MDMxODA0WqCCEzowggbtMIIE1aADAgECAhAIT9wzT35FTtvDD4/5khg1MA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcg
# UlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwHhcNMjYwODA1MDAwMDAwWhcNMzcxMTA0
# MjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4x
# OzA5BgNVBAMTMkRpZ2lDZXJ0IFNIQTI1NiBSU0E0MDk2IFRpbWVzdGFtcCBSZXNw
# b25kZXIgMjAyNiAxMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtnum
# 8sn+zUr41JtMZbP9OMYw+HwJDpG5xkIu/lqcfNYmMX81YmsUiHLbh9ykpeWBGKTL
# hYBrAN9Tdg/QEzG32XcObmgIblnr0CoQ3WSAeDZ6nH6X6VkFyYkJw3QBJREwvm4U
# hLzSxmwPA7cFKRTEOMsmEEj6qJk/dqLEAL+oQYuOwE2UuiX1Vnul8YReIyWd4kgL
# n9gq6LNXM0UplkR6jL/QHxmb6fMoGBJYbnaUI7XD6cKDpekK2SVMld4iDbzeHDtO
# aaxldH5IxuNusQ69nd8/ZXEiB5Hbxj3RlK13cX1W4DlFXKdv/CEhM8Cj1vvlmvhN
# royPdRGbbpBlgyf8Wdu5N6ByhFwURn0U6ozlPoxN22v+fviUhP+6DR547OZnpBMW
# Dfei1f5sVGwiiW/KQTWOK97g+4RJpPzPNV4VYMAwO2jM2Aty2QYPVmOQTJm0msuX
# nJrSbl2gf9JylpkJlWXqk1Q4LJsxz+TELoQCZIljbgvTJgoPU2R12ydv8i1UqL/a
# delA0y7U9Pmmtbze9Xx3rtajC5SzQd1jgfwAwsa90v9YcSPdmeoyoBBA/27cCL23
# 7l5DTYYPDLQ4ON3OLTGWnvRb6jDrf/T75gMRfUzSLCBQfBusm9+mSWRlC/Df6S/e
# 9Q8i13CuhzOT2Jx+V/nlbXM4QoBwlUAhelwwJT0CAwEAAaOCAZUwggGRMAwGA1Ud
# EwEB/wQCMAAwHQYDVR0OBBYEFBTJY4owLtRK+26U8+bjQH717M3iMB8GA1UdIwQY
# MBaAFO9vU0rp5AZ8esrikFb2L9RJ7MtOMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDCBlQYIKwYBBQUHAQEEgYgwgYUwJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBdBggrBgEFBQcwAoZRaHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0YW1waW5n
# UlNBNDA5NlNIQTI1NjIwMjVDQTEuY3J0MF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGlu
# Z1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjAL
# BglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAI3FOmEenVIK35msCYB+fShA
# sWvSYvLBItoNdAgQ2jIqrGsVsluXMJU/+mRebBc52s6lbKAvOVPXaizmKkMLLflE
# EKDZQx4CkS2t8aHPjkXha3hYZ010htFa3dhNgmalH5vuWvh3tTCf4frTS7gPtGc4
# Z/xaPhQ2AB1mR8eEe/WbH0RWHvVIl6VwQ3+g5FKNfN2N/DWJkf13w2H+2GfqEfbd
# 35Ww8CvoYBjLNIDTadcPWdgsjsiOaK/7EsKJgLjUNIVgvcaFOLLQ/GlrA+0ZHJoF
# UbOr5SJN8zykPspXIXlpDJY/gqFUZRROeab9GVgmhbdOJcD/63RhxPahFUGbckRO
# NqMe6DYAv6/mOG0pWd3cPStsdcS7buj5DyniwRY8yooMH6ptx5vpP/pZzBPBeZD2
# U4IsthyxB5Jaa8qrOkB5z160TXiM5ADMspZ0TfD9MJoq0tFpFPssKRFhWeEDYPvc
# UuN7U7lvcdHl4ezQ3NT/7Ffs1sR1yh/LRbdZ3B3Vc6q2WmD8mDC0p9kzl2o73iVt
# S946IkEj7FkRsZGww1teYxERROC745xrtjvcw9ZyyUjHZWGRIpJeMNsPquCDf0fk
# yHtB+J4AiNZqCQk23rxh+KbpyMTNVKItJ5l92Svl20U9NbqMBOVYl1h54NEYLJq1
# /xHWFKPNK903zJZA9P2DMIIGtDCCBJygAwIBAgIQDcesVwX/IZkuQEMiDDpJhjAN
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
# IFNIQTI1NiAyMDI1IENBMQIQCE/cM09+RU7bww+P+ZIYNTANBglghkgBZQMEAgEF
# AKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8X
# DTI2MTAxNDAzMTgwNFowKwYLKoZIhvcNAQkQAgwxHDAaMBgwFgQUUdmr2gNJc9hP
# QmaspIJI5rNpxDkwLwYJKoZIhvcNAQkEMSIEIGBaKpVMNAKYJ9cMMewzbiM8DASs
# NlWFSquZ7NPV5BgwMDcGCyqGSIb3DQEJEAIvMSgwJjAkMCIEIC2gnaf0Ex+f5y22
# xebpyWVnVa8EPx6nQswNISDhQev8MA0GCSqGSIb3DQEBAQUABIICAKSbWWoVksUX
# fZbhZec/URT2tRdPoqh93GGF/v+Hpyo9Z1pMNwInYqnnIKpS/zCEgVblWxSzwm9n
# dUFc6tQnxVNPdQkNuz5PFhO79LmEkwH2UTGjgz71REIJrdP542Rc9+BZSCvHdhVL
# s5rWmln0twXqyndfTllIkAYjv67hJOoTecnIvIiR2SZWNNtUiuEqSZ7UxzzuWrsg
# O+Y0RfhVD4lcq9B+SHpbPniid5r3xVQhu+jqO7b8zv818Jji9Hk8EL+rJ+aCVWiO
# 2XioD+rWjpy69PnvQf8bEnlPpXBSf1VfhH2TGewCVAvRlJEqeuA3T8PNfCfgZfTd
# csL2k4FJOE+8S0fwLcDEtK7aDfgRnJUKLoo9MTCZtyxlRzRs7kaBWuNyy55NjPmN
# 7JhVgAZqVdhGpynTvCaI68PW0NGlMU+T3bawtXC1iLzR6N6xIo5UfQwFCmhgu67p
# GiQbSG1+7Fs5eAG0WOxuSbm49QZDd2jVpxZTCgNgg6GUNTq/h9kHtM54OoeSQwAx
# yIQ2oWSopcJu3BtsgmhSAYjUBJSgXAxBrozWhK67cBrNnu83eCNobmSEgirUww/6
# QuE9MJxx06GUO+vnD2ZRNc5DbgIYBCeBZjinTBhPHx0Aq3iC954z8iXs9AUxpqPl
# qCNO+/NqLdoRvNHHM54zFyeZLaHoKKvQ
# SIG # End signature block
