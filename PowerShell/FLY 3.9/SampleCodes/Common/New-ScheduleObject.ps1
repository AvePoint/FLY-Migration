#<StartTime> / <EndTime>

$LocalTime = [DateTime]::Now.AddHours(1).ToString("O")

$UTCTime = [DateTime]::UtcNow.AddHours(1).ToString("O")

#OnlyOnce Schedule

$schedule = New-ScheduleObject -StartTime '<StartTime>' -IntervalType OnlyOnce

#Recurrence Schedule(below schedule will run every day at <StartTime> and will stop recurrence after run 5 times).

$schedule = New-ScheduleObject -StartTime '<StartTime>' -IntervalType Daily -Interval 1 -EndType Occurrences -OccurrencesValue 5

#Recurrence Schedule(below schedule will run every 2 days at <StartTime> and will stop recurrence at <EndTime>).

$schedule = New-ScheduleObject -StartTime '<StartTime>' -IntervalType Daily -Interval 2 -EndType Time -EndTime '<EndTime>'

#Recurrence Schedule(below schedule will run every 2 weeks on 'Monday' And 'Friday' at <StartTime> and will stop recurrence after run 10 times).

$Days = @('Monday', 'Friday')#Acceptable Values ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
$schedule = New-ScheduleObject -StartTime '<StartTime>' -IntervalType Weekly -Interval 2 -Days @Days -EndType Occurrences -OccurrencesValue 10
