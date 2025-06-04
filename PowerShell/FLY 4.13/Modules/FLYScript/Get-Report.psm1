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


# If the user supplied -Prefix to Import-Module, that applies to the nested module as well
# Force import the nested module again without -Prefix

function Select-Color
{
    param(
    [ValidateSet('CSV','XLS')]
    $Type,
    [string[]]
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
    $JoinIds = $null;
    if($Id.Count -ge 1)
    {
        if($Id.Count -eq 1)
        {
            $JoinIds = $Id[0];
        }else{
        $JoinIds =  $Id -join '&id='
        }
        
    }

    
    return Invoke-WebRequest -Uri "$BaseUri/api/monitor/download-details?id=$JoinIds&type=$ReportType&failedOnly=$FailedOnly&withLogs=$withLogs" -Method Get -Headers @{"Authorization" ="api_key $ApiKey"}
}

function Get-Report
{
    param(    
        [Parameter(Mandatory = $true)]
        [string]
        $APIKey,
    
        [Parameter(Mandatory = $true)]
        [string]
        $BaseUri,

        [Parameter(Mandatory = $true)]
        [ValidateSet('CSV','XLS')]
        $Type,

        [Parameter(Mandatory = $true)]
        [string[]]
        $Id,

        [Boolean]
        $FailedOnly,

        [Boolean]
        $withLogs,

        [Parameter(Mandatory = $true)]
        [String]
        $SavePath
    )
    if(!(Test-Path $SavePath -PathType Container))
    {
        throw "The path [$SavePath] does not exist, please check the path and enter a right one."
    }
     $response = Select-Color -Type $Type -FailedOnly $FailedOnly -withLogs $withLogs -Id $Id -ApiKey $APIKey -BaseUri $BaseUri
     if($response.Headers["Content-Length"].Length -eq 2)
       {
           throw "Failed to download report, please check the entered information. "
       }else
       {
           $Name = $response.Headers["Content-Disposition"].split(";")[1].split('"')[1]
           $path = "$SavePath\$Name"
           $file = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Create)
           $file.write($response.Content, 0, $response.RawContentLength)
           $file.close()
           return @{content = "Successfully download the report, please find the report in this path [$SavePath]."}
       }
    

}

Export-ModuleMember -Function Get-Report