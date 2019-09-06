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
#<StartTime> / <EndTime>

$LocalTime = [DateTime]::Now.AddHours(1).ToString("O")

$UTCTime = [DateTime]::UtcNow.AddHours(1).ToString("O")

#OnlyOnce Schedule

$schedule = New-ScheduleObject -StartTime '<StartTime>' -IntervalType OnlyOnce

#Recurrence Schedule(below schedule will run every day at <StartTime> and will stop recurrence after run 5 times).

$schedule = New-ScheduleObject -StartTime '<StartTime>' -IntervalType Daily -Interval 1 -EndType Occurrences -OccurrencesValue 5

#Recurrence Schedule(below schedule will run every 2 days at <StartTime> and will stop recurrence at <EndTime>).

$schedule = New-ScheduleObject -StartTime '<StartTime>' -IntervalType Daily -Interval 2 -EndType Time -EndTime '<EndTime>'

