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

$SourceConnectionId = '<file system connection id>'

$DestinationCredential = New-SharePointCredentialObject -AccountName '<account name>' -AppProfileName '<app profile name>'

$Source = New-FSPathObject -Level Folder -Path '<folder path>'

$Destination = New-FSMigrationSharePointObject -Level Library -Url '<library url>'

$MappingContent = New-FSMappingContentObject -Source  $Source -Destination $Destination -Method AttachAsChild

$Mappings = New-FSMappingObject -SourceConnectionId $SourceConnectionId -DestinationCredential $DestinationCredential -Contents @($MappingContent)

$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now.AddMinutes(2).ToString('o'))

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit name>' -Wave '<wave name>' -Name '<name>'

$PlanSettings = New-FSPlanSettingsObject -MigrationMode HighSpeed -DatabaseId '<migration database id>' -PolicyId '<migration policy id>' -Schedule $Schedule -NameLabel $PlanNameLabel

$Plan = New-FSPlanObject -Settings $PlanSettings -Mappings $Mappings

$ServiceResponse = Add-FSPlan -BaseUri $BaseUri -APIKey $ApiKey -PlanSettings $Plan

$ServiceResponse.Content