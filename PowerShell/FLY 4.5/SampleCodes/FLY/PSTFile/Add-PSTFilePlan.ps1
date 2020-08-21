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

$ConnAdvancedOption = New-PSTFileConnectionAdvancedSettingsOptionObject -AgentHostName "<agent host name>"

$ConnCredential = New-BasicCredentialObject -Username "<Username>" -Password "<Password>"

$SourceConnection = New-PSTFileConnectionOptionObject -BasicCredential $ConnCredential -Path "<UNC Path>" -AdvancedSettings $ConnAdvancedOption 

$EXOCredential = New-BasicCredentialObject -Username "<Username>" -Password "<Password>" 

$EXOConnOption = New-ExchangeOnlineConnectionOptionObject -BasicCredential $EXOCredential

<# 
$EXOConnOption = New-ExchangeOnlineConnectionOptionObject -ConnectionId "<EXchange online connection id>"
#>

$Source = New-PSTFileObject -Path "<PST File Path>" -Password "<Password>"

$Destination = New-ExchangeMailboxObject -Mailbox '<mailbox address>' -MailboxType UserMailbox

$MappingObject = New-PSTFileMappingContentObject -Source $Source -Destination $Destination

$Mappings = New-PSTFileMappingObject -PstFileConnection $SourceConnection -ExchangeConnectionOption $EXOConnOption -Contents @($MappingObject)

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit name>' -Wave '<wave name>' -Name '<name>'

$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')

$PlanSettings = New-PSTFilePlanSettingObject -NameLabel $PlanNameLabel -PolicyId '<migration policy id>' -DatabaseId '<migration database id>' -Schedule $Schedule

$Plan = New-PSTFilePlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-PSTFilePlan -Plan $Plan -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content