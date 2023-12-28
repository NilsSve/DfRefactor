SELECT der.percent_complete as PercentageComplete, dest.text as QueryText, der.command as QueryType,
der.start_time as QueryStartTime,
convert(varchar, datediff(s, start_time, getdate())/(60*60)) + ': ' + convert(varchar, datediff(s, start_time, getdate())%(60*60)/60) + ': ' + convert(varchar, datediff(s, start_time, getdate())%60) as TotalQueryRunningTime,
dateadd(s,estimated_completion_time/1000, getdate()) as EstematedCompletionTime
FROM sys.dm_exec_requests der
CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) dest
where der.command in('BACKUP DATABASE', 'BACKUP LOG')