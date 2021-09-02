# .SYNOPSIS
#  FLYEnableMailPublicFolder.ps1
#  According to mapping file, enable the public folder mail settings.
#
# .DESCRIPTION
#
# Copyright (c) 2017-2020 AvePoint Inc. All Rights Reserved.

$invocation = (Get-Variable MyInvocation).Value
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$importPath="$currentPath\MailEnabledPF_Mapping.csv"
$jobReportPath="$currentPath\Report_EnableMailPublicFolder_$timestamp.csv"
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

$folders = $folders | select -unique

foreach ($tempFolder in $importValues)
{
  try
  {
    $folder=$tempFolder.DestFolderPath
    Write-Output "Processing folder: $folder"
    Enable-MailPublicFolder -Identity $folder  -ErrorAction Stop
    $reportObj = New-Object -TypeName PSCustomObject
	$reportObj | Add-Member -MemberType NoteProperty -Name "FolderPath" -Value $folder
	$reportObj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Successful"
	$reportObj | Add-Member -MemberType NoteProperty -Name "Comment" -Value ""
    $reports +=  $reportObj
  }
  catch [System.Exception] 
  {
      Write-Warning "Failed to enable: $($folder). Reason:$($_.Exception.Message)"
      $reportObj = New-Object -TypeName PSCustomObject
      $reportObj | Add-Member -MemberType NoteProperty -Name "FolderPath" -Value $folder
      $reportObj | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
      $reportObj | Add-Member -MemberType NoteProperty -Name "Comment" -Value $_.Exception.Message
      $reports +=  $reportObj
  }
}
 Write-Host "Finished. Please check the report for details. Path: $($jobReportPath)" -ForegroundColor Green
$reports | Export-Csv -Path $jobReportPath -NoTypeInformation -Encoding UTF8


