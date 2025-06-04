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
 *  Copyright © 2017-2024 AvePoint® Inc. All Rights Reserved.
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>
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
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
function Update-UpdateMigrationOptions
{
	 param(    
        [Parameter(Mandatory = $true)]
        [string]
        $APIKey,
    
        [Parameter(Mandatory = $true)]
        [string]
        $BaseUri,
		
		[Parameter(Mandatory = $true)]
        [String]
        $CsvPath
    )
    try{
        Write-Host "Start to update migration options."
	    $Mappings = GetUserMappings($CsvPath)
        if($Mappings -eq $null -or $Mappings.Count -le 1){
            Write-Host -ForegroundColor Red "The Mapping information cannot be empty."
        } else {
            Write-Host "Migration options were updated."
            Write-Host "You can view the report generated in the same directory as the script."
        }
	}catch{
    Write-Host -ForegroundColor Red $_
    }
}

function GetUserMappings($path){
    $fileExtension = [System.IO.Path]::GetExtension($path);
    $headerFormat = 'Plan Name,Convert to Shared Mailbox,Migrate Archive Mailbox,Migrate Deletion Folder'.ToLower();
    if([string]::IsNullOrEmpty($fileExtension) -or $fileExtension -notmatch '.csv'){
       throw "Incorrect file path or incorrect file format'."
    }
    if(![System.IO.File]::Exists($path)){
        throw "Could not find file '$path'."
    }
	$ImportCsv = Import-Csv -Path $path -Encoding UTF8
    $resultPath = CreateCsv($path);
    #$ImportCsv | Select-Object *,"Status","Comment" | Export-Csv -Path $NewFilePath -NoTypeInformation
    $mappings = $ImportCsv | select -Property @{label="PlanName";expression={$($_."Plan Name")}},@{label="ConvertToSharedMailbox";expression={$($_."Convert to Shared Mailbox")}},@{label="MigrateArchiveMailbox";expression={$($_."Migrate Archive Mailbox")}},@{label="MigrateDeletonsFolder";expression={$($_."Migrate Deletions Folder")}}
    foreach($mapping in $mappings)
	{
        if(![string]::IsNullOrEmpty($mapping.'ConvertToSharedMailbox'.ToLower())){
         if($mapping.'ConvertToSharedMailbox'.ToLower() -eq "yes")
	       {
		        $mapping.'ConvertToSharedMailbox' = $true
	       }
           elseif($mapping.'ConvertToSharedMailbox'.ToLower() -eq "no"){
                 $mapping.'ConvertToSharedMailbox' = $false
           }
        }
        if(![string]::IsNullOrEmpty($mapping.'MigrateArchiveMailbox'.ToLower())){
         if($mapping.'MigrateArchiveMailbox'.ToLower() -eq "yes")
	       {
		        $mapping.'MigrateArchiveMailbox' = $true
	       }elseif($mapping.'MigrateArchiveMailbox'.ToLower() -eq "no"){
                 $mapping.'MigrateArchiveMailbox' = $false
           }
        }
		if(![string]::IsNullOrEmpty($mapping.'MigrateDeletonsFolder'.ToLower())){
         if($mapping.'MigrateDeletonsFolder'.ToLower() -eq "yes")
	        {
		        $mapping.'MigrateDeletonsFolder' = $true
	        }elseif($mapping.'MigrateDeletonsFolder'.ToLower() -eq "no"){
                 $mapping.'MigrateDeletonsFolder' = $false
            }
        }
        try{
             $response = Invoke-WebRequest -Uri "$BaseUri/api/exchange/plans/updatemappingaction" -Method Post -Headers @{"Authorization" ="api_key $ApiKey"} -Body (ConvertTo-Json $mapping) -ContentType "application/json"
             $response
             AddDataToCsv -fileName $resultPath -data $mapping -status 'successful' -comment ''
        }catch{
            AddDataToCsv -fileName $resultPath -data $mapping -status 'Failed' -comment $_
            Write-Host -ForegroundColor Red $_
        }
	}
    return $mappings;
}
function CreateCsv($fileName)
{
 $fileName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)+(Get-Date -Format 'yyyyMMddHHmmss') +'-result.csv';
 $props = @("Plan Name",
            'Status',
            'Comment')
 $props | Export-Csv $fileName -NoTypeInformation -Force
 Import-Csv -Path $fileName | ? {$_.trim() -ne "" } | Export-Csv $fileName
 #gc $fileName | ? {$_.trim() -ne "" } | set-content $fileName -Force
 return $fileName
}
function AddDataToCsv{
 param(    
        [string]
        $fileName,
        [object]
        $data,
        [String]
        $status,
        [String]
        $comment
    )
$Path = Get-ScriptDirectory
@([PSCustomObject]@{'Plan Name' = $data.'PlanName';'Status'=$status;'Comment'=$comment}) | Export-csv "$Path\$fileName"  -Append -Force -NoTypeInformation
}