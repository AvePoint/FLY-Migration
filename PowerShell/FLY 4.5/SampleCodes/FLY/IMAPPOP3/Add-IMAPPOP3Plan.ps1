﻿<# /********************************************************************
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

$BasicCredential = New-BasicCredentialObject -Username '<Username>' -Password '<password>'

$DestinationConnOption = New-ExchangeOnlineConnectionOptionObject -BasicCredential $BasicCredential

$DestinationConnection = New-ExchangeConnectionObject -OnlineConnectionOption $DestinationConnOption

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit>' -Wave '<wave>' -Name '<name>'

$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([System.DateTime]::Now).AddMinutes(2).ToString("o")

$PlanSettings = New-IMAPPOP3PlanSettingsObject -NameLabel $PlanNameLabel -Schedule $Schedule -PolicyId $PolicyId -DatabaseId $DatabseId -SynchronizeDeletion

$SourceConnection = New-IMAPPOP3ConnectionObject -Type Outlook -ServerName 'imap-mail.outlook.com' -Port 993 -EnableSSL

$Source1 = New-IMAPPOP3MailBoxObject -Mailbox '<outlook mailbox>' -Password '<password>'
$Source2 = New-IMAPPOP3MailBoxObject -Mailbox '<outlook mailbox>' -Password '<password>'

$MappingContent1 = New-IMAPPOP3MappingContentObject -Source $Source1 -DestinationMailbox '<exchange mailbox>' -MigrateArchivedMailboxOrFolder
$MappingContent2 = New-IMAPPOP3MappingContentObject -Source $Source2 -DestinationMailbox '<exchange mailbox>' -MigrateArchivedMailboxOrFolder

$Mappings = New-IMAPPOP3MappingObject -Source $SourceConnection -Destination $DestinationConnection -Contents @($MappingContent1, $MappingContent2)

$Plan = New-IMAPPOP3PlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-IMAPPOP3Plan -APIKey $ApiKey -BaseUri $BaseUri -Plan $Plan

$Response.Content