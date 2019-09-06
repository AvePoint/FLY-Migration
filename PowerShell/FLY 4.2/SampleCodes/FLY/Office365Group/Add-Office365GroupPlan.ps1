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
 *  Copyright © 2017-2019 AvePoint® Inc. All Rights Reserved.
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>
$ApiKey = '<api key>'
$BaseUri = '<base uri>'

$SourceConnectionId = '<office 365 group connection id>'

$DestinationConnectionId  = '<office 365 group connection id>'

$Source1 = New-Office365GroupObject -Name '<group name>' -Mailbox '<group mailbox>'
$Source2 = New-Office365GroupObject -Name '<group name>' -Mailbox '<group mailbox>'

$Destination1 = New-Office365GroupObject -Name '<group name>' -Mailbox '<group mailbox>'
$Destination2 = New-Office365GroupObject -Name '<group name>' -Mailbox '<group mailbox>'

$MappingContent1 = New-Office365GroupMappingContentObject -Source $Source1 -Destination $Destination1
$MappingContent2 = New-Office365GroupMappingContentObject -Source $Source2 -Destination $Destination2

$Mappings = New-Office365GroupMappingObject -SourceConnectionId $SourceConnectionId -DestinationConnectionId $DestinationConnectionId -Contents @($MappingContent1, $MappingContent2)

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit name>' -Wave '<wave name>' -Name '<name>'

$Schedule = New-ScheduleObject -IntervalType OnlyOnce -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')

$PlanSettings = New-Office365GroupPlanSettingsObject -NameLabel $PlanNameLabel -PolicyId '<migration policy id>' -DatabaseId '<migration database id>' -Schedule $Schedule -OnlyMigrateDocumentsLibrary

$Plan = New-Office365GroupPlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-Office365GroupPlan -Plan $Plan -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content