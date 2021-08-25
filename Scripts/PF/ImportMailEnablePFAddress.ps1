# .SYNOPSIS
#  FLYImportMailEnablePFAddress.ps1
#  According to mapping file, add email address to mail enabled public folder.
#
# .DESCRIPTION
#
# Copyright (c) 2017-2020 AvePoint Inc. All Rights Reserved.

$invocation = (Get-Variable MyInvocation).Value
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$importPath="$currentPath\MailEnabledPF_Mapping.csv"
$jobReportPath="$currentPath\Report_ImportMailEnabledPFAddress_$timestamp.csv"
$reports = @()
$importFile = $Args[0]

if ($importFile -eq $null)
{
    $importFile = $importPath
}
if (test-path $importFile)
{
   Write-Output "Mapping file path:$($importFile)"
}
else
{
   Write-Warning "Mapping file cannot be found."
   exit
}

$importValues = import-csv $importFile

foreach ($value in $importValues)
{
     if($value.DestFolderPath)
   {
     #just test valid folder path
   }
   else
   {
     Write-Warning "DestFolderPath does not exist on $($importFile)"
	 Write-Warning "Please check your mapping file."
     exit
   }
}

 do
 {
    $IsSetPrimary = Read-Host -Prompt "Do you want to set the Primary SMTP Addresses at the time? (Please enter yes or no)"
  }
 until ("yes","no" -contains $IsSetPrimary)
foreach ( $value in $importValues)
{
  try
  {
    $folder=$value.DestFolderPath
    Write-Output "Processing folder $($folder)"
    $publicFolder = Get-MailPublicFolder $folder  -ErrorAction Stop
    $reportObj = New-Object -TypeName PSCustomObject
    $reportObj | Add-Member -MemberType NoteProperty -Name "FolderPath" -Value $folder
    if ($publicFolder -eq $null)
    {
        Write-Warning "Cannot find mail enabled public folder:$($folder)"
        $reportObj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
	    $reportObj | Add-Member -MemberType NoteProperty -Name "Comment" -Value "Cannot find this mail enabled public folder."
		$reports +=  $reportObj
		continue
    }
	if($value.EmailAddresses)
	{
      $addressArrary=$value.EmailAddresses.Split(";",[StringSplitOptions]::RemoveEmptyEntries)
      $primaryAddress=$addressArrary[0]
	  $skipComment=""
      foreach ($value in $addressArrary)
      {
         $tempAddress= "SMTP:"+$value.Trim()
         if($publicFolder.EmailAddresses -notcontains $tempAddress)
         {
	       $publicFolder.EmailAddresses += $tempAddress
         }
		 else
		 {
		   $skipComment+="$($value.Trim()) is skipped due to existed. "
		 }
      }
	  Set-MailPublicFolder -Identity $publicFolder.Identity -EmailAddresses $publicFolder.EmailAddresses -EmailAddressPolicyEnabled $true -WarningAction SilentlyContinue -ErrorAction Stop
	  if($IsSetPrimary -eq 'yes')
	  {
        Set-MailPublicFolder -Identity $publicFolder.Identity -PrimarySmtpAddress $primaryAddress -EmailAddressPolicyEnabled $false 
	    Write-Output "Set PrimarySmtpAddress $($primaryAddress) for $($folder) "
	  }
	  
      $reportObj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Successful"
	  $reportObj | Add-Member -MemberType NoteProperty -Name "Comment" -Value $skipComment     
	}
	else
	{
	  $reportObj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
	  $reportObj | Add-Member -MemberType NoteProperty -Name "Comment" -Value "No EmailAddresses" 
	}
	$reports +=  $reportObj
  }
  catch [System.Exception] 
  {
      Write-Warning "Failed to process: $($folder). Reason:$($_.Exception.Message)"
      $reportObj = New-Object -TypeName PSCustomObject
      $reportObj | Add-Member -MemberType NoteProperty -Name "FolderPath" -Value $folder
      $reportObj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
      $reportObj | Add-Member -MemberType NoteProperty -Name "Comment" -Value $_.Exception.Message
      $reports +=  $reportObj
  }
}
 Write-Host "Finished. Please check the report for details. Path: $($jobReportPath)" -ForegroundColor Green
$reports | Export-Csv -Path $jobReportPath -NoTypeInformation -Encoding UTF8


