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

$SourceConnectionId = '<google drive connection id>'

$Credential = New-SharePointCredentialObject -AccountName '<account name>' -AppProfileName '<app profile name>'

$Source1 = New-GoogleDriveObject -Level Folder -Path '<Shared Drive\Folder>'
$Source2 = New-GoogleDriveObject -Level Folder -Path '<My Drive>'

$Destination1 = New-GoogleDriveMigrationSharePointObject -Level Library -Url '<sharepoint library url>'
$Destination2 = New-GoogleDriveMigrationSharePointObject -Level Folder -Url '<sharepoint folder url>'

$MappingContent1 = New-GoogleDriveMappingContentObject -Source $Source1 -Destination $Destination1 -Method Combine
$MappingContent2 = New-GoogleDriveMappingContentObject -Source $Source2 -Destination $Destination2 -Method AttachAsChild

$Mappings = New-GoogleDriveMappingObject -SourceConnectionId $SourceConnectionId -DestinationCredential $Credential -Contents @($MappingContent1, $MappingContent2)

$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now.AddMinutes(2).ToString('o'))

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit name>' -Wave '<wave name>' -Name '<name>'

$PlanGroups = @('<plan group id>')

$PlanSettings = New-GoogleDrivePlanSettingsObject -NameLabel $PlanNameLabel -Schedule $Schedule -DatabaseId '<migration database id>' -PolicyId '<policy id>' -PlanGroups $PlanGroups -MigrateVersions

$Plan = New-GoogleDrivePlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-GoogleDrivePlan -BaseUri $BaseUri -APIKey $ApiKey -PlanSettings $Plan

$Response.Content