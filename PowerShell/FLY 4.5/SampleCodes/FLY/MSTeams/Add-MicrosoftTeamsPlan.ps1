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
$ApiKey = '<api key>'
$BaseUri = '<base uri>'

$SourceConnectionId = '<microsoft teams connection id>'

$DestinationConnectionId  = '<microsoft teams connection id>'

$Source1 = New-MSTeamsObject -Mailbox '<teams mailbox>' -Name '<teams name>'
$Source2 = New-MSTeamsObject -Mailbox '<teams mailbox>' -Name '<teams name>'

$Destination1 = New-MSTeamsObject -Mailbox '<teams mailbox>' -Name '<teams name>'
$Destination2 = New-MSTeamsObject -Mailbox '<teams mailbox>' -Name '<teams name>'

$MappingContent1 = New-MSTeamsMappingContentObject -Source $Source1 -Destination $Destination1
$MappingContent2 = New-MSTeamsMappingContentObject -Source $Source2 -Destination $Destination2

$Mappings = New-MSTeamsMappingObject -SourceConnectionId $SourceConnectionId -DestinationConnectionId $DestinationConnectionId -Contents @($MappingContent1, $MappingContent2)

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit name>' -Wave '<wave name>' -Name '<name>'

$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')

$ConversationSetting = New-ConversationsMigrationSettingsObject -Scope Customization -Duration 12 -DurationUnit Month -Style HTMLFileAndMessages

$PlanSettings = New-MSTeamsPlanSettingsObject -NameLabel $PlanNameLabel -PolicyId '<migration policy id>' -DatabaseId '<migration database id>' -Schedule $Schedule  -ConversationsMigrationSettings $ConversationSetting -MigrateMembers -MigrateGroupPlanner -OnlyMigrateDocumentsLibrary

$Plan = New-MSTeamsPlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-MicrosoftTeamsPlan -Plan $Plan -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content