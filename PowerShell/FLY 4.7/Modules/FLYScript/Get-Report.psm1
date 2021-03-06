<#
Code generated by Microsoft (R) PSSwagger 0.3.0
Changes may cause incorrect behavior and will be lost if the code is regenerated.
#>


# If the user supplied -Prefix to Import-Module, that applies to the nested module as well
# Force import the nested module again without -Prefix

function Select-Color
{
    param(
    [ValidateSet('CSV','XLS')]
    $Type,
    [String]
    $Id,
    [Boolean]
    $FailedOnly,
    [Boolean]
    $withLogs,
    [String]
    $ApiKey,
    [String]
    $BaseUri
    
    )
    $ReportType = 2;
    if($Type -eq "CSV"){
        $ReportType = 2
    }else{
        $ReportType = 3
    }
    return Invoke-WebRequest -Uri "$BaseUri/api/report/download-details?id=$id&type=$ReportType&failedOnly=$FailedOnly&withLogs=$withLogs" -Method Get -Headers @{"Authorization" ="api_key $ApiKey"}
}

function Get-Report
{
    param(    
        [Parameter(Mandatory = $false)]
        [string]
        $APIKey,
    
        [Parameter(Mandatory = $false)]
        [string]
        $BaseUri,

        [ValidateSet('CSV','XLS')]
        $Type,

        [String]
        $Id,

        [Boolean]
        $FailedOnly,

        [Boolean]
        $withLogs,

        [String]
        $SavePath
    )
     $response = Select-Color -Type $Type -FailedOnly $FailedOnly -withLogs $withLogs -Id $Id -ApiKey $APIKey -BaseUri $BaseUri
     if($response.Headers["Content-Length"].Length -eq 2)
       {
            Write-Host -ForegroundColor Red("Download failed, please check if the information entered is correct. ")
       }else
       {
           $Name = $response.Headers["Content-Disposition"].split(";")[1].split('"')[1]
           $path = "$SavePath\$Name"
           $file = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Create)
           $file.write($response.Content, 0, $response.RawContentLength)
           $file.close()
           return @{content = "Successful download of report."}
       }
    

}

Export-ModuleMember -Function Get-Report