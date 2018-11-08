# Dependencies

Windows, PowerShell 5.1+

PSSwaggerUtility 

reference 'https://www.powershellgallery.com/packages/PSSwaggerUtility' to get more details

# How to import PSModule

Import-Module '<your-service-root-folder>/FLYMigration

###########################################################################################
#                                                                                         #
# if the certificate binding to your serivce is invalid, below code is required.          #
#                                                                                         #
###########################################################################################
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
###########################################################################################