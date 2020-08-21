<# /********************************************************************
 *
 *  PROPRIETARY and CONFIDENTIAL
 *
 *  This file is licensed from, and is a trade secret of:
 *
 *                   AvePoint, Inc.
 *                   Harborside Financial Center
 *                   9th Fl.   Plaza Ten
 *                   Jersey City, NJ 07311
 *                   United States of America
 *                   Telephone: +1-800-661-6588
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
 *  Copyright © 2017-2020 AvePoint® Inc. All Rights Reserved.
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>
$ApiKey = '<ApiKey>'
$BaseUri = '<BaseUri>'
$PolicyId = '<policy id>'
$DatabseId = '<migration database id>'
$DropboxConnectionId = '<dropbox connection id>'
$SharePointAccountName = '<sharepoint account name>'

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit>' -Wave '<wave>' -Name '<name>'

$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([System.DateTime]::Now).AddMinutes(2).ToString("o")

$PlanSettings = New-DropboxPlanSettingsObject -NameLabel $PlanNameLabel -Schedule $Schedule -PolicyId $PolicyId -DatabaseId $DatabseId  -MigrateVersions

$Source1 = New-DropboxObject -Path '<user@contoso.com>' -Level Folder

$Source2 = New-DropboxObject -Path '<user@contoso.com\folder>' -Level Folder

$Destination1 = New-DropboxMigrationSharePointObject -Url '<sharepoint library url>' -Level Library

$Destination2 = New-DropboxMigrationSharePointObject -Url '<sharepoint folder url>' -Level Folder

$MappingContent1 = New-DropboxMappingContentObject -Source $Source1 -Destination $Destination1 -Method Combine

$MappingContent2 = New-DropboxMappingContentObject -Source $Source2 -Destination $Destination2 -Method AttachAsChild

$Credential = New-SharePointCredentialObject -AccountName $SharePointAccountName

$Mappings = New-DropboxPlanMappingObject -SourceConnectionId $DropboxConnectionId -DestinationCredential $Credential -Contents @($MappingContent1, $MappingContent2)

$Plan = New-DropboxPlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-DropboxPlan -APIKey $ApiKey -BaseUri $BaseUri -PlanSettings $Plan

$Response.Content