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

function Covert-UtcTime($Time)
{
	$Result = @{ HasError = $false ; Message = "";Time = ""}
	$Pattern = "^[1-9][0-9]{3}\-([0-9][1-9]|[1-9][0-9])\-([0-9][1-9]|[1-9][0-9]) [0-9]{2}\:[0-9]{2}\:[0-9]{2}"
	$MathResult = $Time -match $Pattern
	if($MathResult)
	{
		$TimeZone = "+"+(Get-TimeZone).BaseUtcOffset.toString().Substring(0,5)
		$SetTime = ([Datetime]$Time).ToString("o")+$TimeZone
		$Result["Time"] = $SetTime;
		if(([Datetime]$Time.Replace('"',"")) -gt [Datetime]::Now)
		{
			$Result["HasError"] = $true;
			$Result["Message"] = "The time configured cannot be later than the current time."
			return $Result
		}
		return $Result;
	}
	else
	{
		$Result["HasError"] = $true;
		$Result["Message"] = "Please check if the time format you entered is correct."
		return $Result;
	}
}

function Get-FileInfo($file){
    if(!(Test-Path $file))
    {
      throw "The file was not found, please check if the path[$file] exists."
    }
    $fileName = Split-Path -Path $file -Leaf;
    
    if(!("csv","excel").Contains($fileName.Split(".")[1])){
        throw "The file format is incorrect.Only csv and xlsx format files are supported for upload"
    }
    $fileContent = Get-Content -Path $file -Encoding Byte
    return @{"FileName"=$fileName;"FileContent" = $fileContent}
    
}


function Get-UserMappings{
    param(    
        [String]
        $Path
    )
    if([string]::IsNullOrEmpty($Path)){
        return @();
    }else{
        $fileName = [System.IO.Path]::GetFileName($path);
        $fileExtension = [System.IO.Path]::GetExtension($path);
        if([string]::IsNullOrEmpty($fileExtension) -or $fileExtension -notmatch '.csv'){
           throw "Incorrect the '$fileName' file path or incorrect file format."
        }
        if(![System.IO.File]::Exists($path)){
            throw "Could not find file '$path'."
        }
        if((Import-Csv -Path $Path -Encoding UTF8) -eq $null){
            throw "The '$fileName' file cannot be empty"
        }

        $mappings = Import-Csv -Path $Path -Encoding UTF8 -Header "Source","Destination"
        $SourceHeader = @('Source User/Group','Source Domain');
        $DestinationHeader = @('Destination User/Group','Destination Domain');
        if(!$SourceHeader.Contains($mappings[0].Source) -or !$DestinationHeader.Contains($mappings[0].Destination)){
            
            throw "The '$fileName' file is empty or in the wrong format, check the contents of the file."
        }
        $mappingList = @()
        $index = 0;
		foreach($mapping in $mappings)
		{
            if($index -eq 0){
            $index++;
            continue;
            }
			$mappingList += New-MappingsObject -Source $mapping."Source" -Destination $mapping."Destination"
		}

        return $mappingList;
    }
}