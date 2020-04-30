# FLY Migration PowerShell

## Dependencies
PowerShell 5.1+

## Import PowerShell Modules
Go to the folder where you’ve installed FLY Manager, and then open the “PowerShell” folder. Run Import-FLYMigration.ps1 with administrator permission.

## Update Certificate Policy for PowerShell
Run the scripts below to update the certificate policy before you run any of your own scripts. 

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

## Get FLY URL and API Key
To ensure your PowerShell scripts can connect to FLY, you must set values for the BaseUri and ApiKey parameters.
1. BaseUri - The URL of your FLY Manager. For example, https://localhost:20100
2. ApiKey - The key to authorize the API calls. You can get the API key from FLY interface > Management > General Settings > API Keys.
