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

$Source = New-ExchangeConnectionObject -OnPremisesConnectionOption (New-ExchangeOnPremisesConnectionOptionObject -ConnectionId '<connection id>')

$Destination  = New-ExchangeConnectionObject -OnlineConnectionOption (New-ExchangeOnlineConnectionOptionObject -BasicCredential (New-BasicCredentialObject -Username '<username>' -Password 'password'))

$DestinationObject = New-DistributionGroupMigrationExchangeMailboxObject -Mailbox '<mailbox address>' -MailboxType DistributionGroup

$MappingContent = New-ExchangeDistributionGroupMappingContentObject -Mailbox '<mailbox address>'  -Destination $DestinationObject

$Mappings = New-ExchangeDistributionGroupMappingObject -Source $Source -Destination $Destination -Contents @($MappingContent)

$PlanNameLabel = New-PlanNameLabelObject -BusinessUnit '<business unit name>' -Wave '<wave name>' -Name '<name>'

$Schedule = New-SimpleScheduleObject -IntervalType Once -StartTime ([Datetime]::Now).AddMinutes(2).ToString('o')

$PlanGroups = @('<plan group id>', '<plan group id>')

$PlanSettings = New-ExchangeDistributionGroupPlanSettingsObject -NameLabel $PlanNameLabel -PolicyId '<migration policy id>' -DatabaseId '<migration database id>' -Schedule $Schedule -PlanGroups $PlanGroups

$Plan = New-ExchangeDistributionGroupPlanObject -Settings $PlanSettings -Mappings $Mappings

$Response = Add-ExchangeDistributionGroupPlan -Plan $Plan -BaseUri $BaseUri -APIKey $ApiKey

$Response.Content