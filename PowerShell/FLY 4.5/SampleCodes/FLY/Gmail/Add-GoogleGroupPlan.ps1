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
$GmailConnectionId = '<gmail connection id>'
$ExchangeConnectionId = '<exchange connection id>'

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit>' -Wave '<wave>' -Name '<name>'

$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([System.DateTime]::Now).AddMinutes(2).ToString("o")

$PlanSettings = New-GoogleGroupPlanSettingsObject -NameLabel $PlanNameLabel -Schedule $Schedule -PolicyId $PolicyId -DatabaseId $DatabseId

$Destination1 = New-GoogleGroupMigrationExchangeMailboxObject -Mailbox '<exchange mailbox>' -MailboxType DistributionGroup 

$Destination2 = New-GoogleGroupMigrationExchangeMailboxObject -Mailbox '<exchange mailbox>' -MailboxType GroupMailbox

$MappingContent1 = New-GoogleGroupMappingContentObject -Mailbox '<gmail mailbox>' -Destination $Destination1

$MappingContent2 = New-GoogleGroupMappingContentObject -Mailbox '<gmail mailbox>' -Destination $Destination2

$DestinationConn = New-ExchangeConnectionObject -OnlineConnectionOption (New-ExchangeOnlineConnectionOptionObject -ConnectionId $ExchangeConnectionId)

$Mappings = New-GoogleGroupMappingObject -SourceConnectionId $GmailConnectionId -Destination $DestinationConn -Contents @($MappingContent1, $MappingContent2)

$Plan = New-GoogleGroupPlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-GoogleGroupPlan -APIKey $ApiKey -BaseUri $BaseUri -Plan $Plan

$Response.Content