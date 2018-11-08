# FLY Migration PowerShell

## Dependencies
PowerShell 5.1+

## Import PowerShell Modules
Go to the folder you installed FLY Manager, open folder "PowerShell".
Run Import-FLYMigration.ps1 with Administrator rights.

## Update Certificate Policy for PowerShell
Run the scripts below, to update the certificae policy.

```powershell
Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
```
