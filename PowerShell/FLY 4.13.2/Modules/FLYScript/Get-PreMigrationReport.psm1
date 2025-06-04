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
 *  Copyright © 2017-2025 AvePoint® Inc. All Rights Reserved. 
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>


# If the user supplied -Prefix to Import-Module, that applies to the nested module as well
# Force import the nested module again without -Prefix

Add-Type -AssemblyName System.Web

 enum PreScanType
{
	SharePoint = 0
	Exchange = 1
	Groups = 2
	Teams = 3
	Slack = 4
	Gmail = 5
	GoogleDrive = 6
	FileSystem = 7
	Box = 8
	Dropbox = 9
    PublicFolder = 10
    TeamsChat = 11
    SlackDirectMessages = 12
    OneDrive = 13
    GoogleChat = 14
}

function Get-PreMigrationReport 
{
    param(    
        [Parameter(Mandatory = $false)]
        [string]
        $APIKey,
    
        [Parameter(Mandatory = $false)]
        [string]
        $BaseUri,
		
		[Parameter(Mandatory = $true)]
        [String]
        $ScopeName,
		
		[PreScanType]
		$Type,
		
        [String]
        $SavePath
		
    )
	$encodeName = [System.Web.HttpUtility]::UrlEncode($ScopeName)
    $response = Invoke-WebRequest -Uri $BaseUri"/api/premigration/plans/downloadreport?name=$encodeName&type=$Type" -Headers @{"Authorization" ="api_key $ApiKey"} -Method Get
    if(-not $response.Headers["Content-Disposition"].Contains("filename"))
       {
            Write-Host -ForegroundColor Red("Download failed, please check if the information entered is correct. ")
       }else
       {
			$Name = $response.Headers["Content-Disposition"].split(";")[1].split('"')[1].Replace('%20',' ')
			$path = "$SavePath\$Name"
			$file = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Create)
			$file.write($response.Content, 0, $response.RawContentLength)
			$file.close()
			return @{content = "Successful download of report. Please find the report in this path [$SavePath]."}
       }

}

Export-ModuleMember -Function Get-PreMigrationReport 