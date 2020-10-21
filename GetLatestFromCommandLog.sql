SELECT DatabaseName,
	   Command,
	   StartTime,
	   EndTime,
	   ErrorNumber,
	   ErrorMessage
  FROM [cs_helper].[dbo].[CommandLog]
  WHERE StartTime >= cast(dateadd(day, -2, getdate()) as date) 
	and CommandType like 'BACKUP_DATABASE'
