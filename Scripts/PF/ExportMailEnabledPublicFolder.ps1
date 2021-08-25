# .SYNOPSIS
#  FLYExportMailEnabledPublicFolder.ps1
#  Generates a CSV file that contains the list of mail enabled public folders and their email addresses
#
# .DESCRIPTION
#
# Copyright (c) 2017-2020 AvePoint Inc. All Rights Reserved.

$invocation = (Get-Variable MyInvocation).Value
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$csvReportPath="$currentPath\MailEnabledPF_ExportReport_$timestamp.csv";
$logPath="$currentPath\MailEnabledPF_Export.log";
$csvReport = @()
$enabledPFCache=@{}

$error.clear()
try
{
  try
  {
    Write-Output "Begin to get mail enabled public folders by Get-PublicFolder."
    $enabledPublicFolders = Get-PublicFolder -Recurse -ResultSize unlimited | Where {$_.MailEnabled -eq "True"} -ErrorAction Stop
    foreach ($tempFolder in $enabledPublicFolders) 
    { 
      $enabledPFCache.Add($tempFolder.MailRecipientGuid, $tempFolder) 
    }
  }
  catch [System.Exception]
  {
    Write-Warning "Failed to get mail enabled public folders by Get-PublicFolder. Reason:$($_.Exception.Message)"
    exit
  }
  Write-Output "Successful to get mail enabled public folders by Get-PublicFolder. Count:$($enabledPFCache.Count)"
  $mailPublicFolders = Get-MailPublicFolder -ResultSize Unlimited
  foreach ($tempMailFolder in $mailPublicFolders)
  {
    $pf  = $enabledPFCache[$tempMailFolder.Guid]
    if ($pf.parentpath -eq "\")
    {
	    $folderPath = "\" + ($pf.name.trim())
    }
    else
    {
        $folderPath = ($pf.ParentPath.trim()) + "\" + ($pf.Name.trim())
    }
    Write-Output "Process folder: $($pf.name). Folder Path: $($folderPath)"
    $smtpAddress=""
    foreach ($tempMail in $tempMailFolder.EmailAddresses)
    {
	  $tempMailAddress = $tempMail.ToString()
	 if ($tempMailAddress.StartsWith("Smtp:", "CurrentCultureIgnoreCase") -eq $false)
        {
	      continue
	    }
	$smtpAddress += $tempMailAddress.SubString("Smtp:".Length)+";"
    }
    $csvObject = new-object PSObject
	$csvObject | add-member -membertype NoteProperty -name "SourceFolderPath" -Value $folderpath.Replace('\ ','\')
	$csvObject | add-member -membertype NoteProperty -name "DestFolderPath" -Value $folderpath.Replace('\ ','\')
	$csvObject | add-member -membertype NoteProperty -name "EmailAddresses" -Value $smtpAddress.Trim(";")
	$csvReport += $csvObject
}

if ($csvReport.length -gt 0)
  {
    $csvReport | export-csv -Path $csvReportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Successful to generate mail enabled public folder report. Path: $($csvReportPath)"  -ForegroundColor Green
  }
  else
  {
    Write-Warning "There are no mail enbaled public folders."
  }
  }
  catch
  {
    Write-Warning "Failed to get mail enbaled public folders."
  }
Write-Host "If there are any errors, please check the log:$($logPath)" -ForegroundColor Green

$error | Out-File $logPath

