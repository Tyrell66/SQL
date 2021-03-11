--source: https://www.mssqltips.com/sqlservertip/6158/how-to-check-monthly-growth-of-database-in-sql-server/
--SECTION 1 BEGIN
WITH BackupsSize AS(
SELECT TOP 1000
      rn = ROW_NUMBER() OVER (ORDER BY DATEPART(year,[backup_start_date]) ASC, DATEPART(month,[backup_start_date]) ASC)
    , [Year]  = DATEPART(year,[backup_start_date])
    , [Month] = DATEPART(month,[backup_start_date])
    , [Backup Size GB] = CONVERT(DECIMAL(10,2),ROUND(AVG([backup_size]/1024/1024/1024),4))
    , [Compressed Backup Size GB] = CONVERT(DECIMAL(10,2),ROUND(AVG([compressed_backup_size]/1024/1024/1024),4))
FROM 
    msdb.dbo.backupset
WHERE 
    [database_name] = N'XXXX'
AND [type] = 'D'
AND backup_start_date BETWEEN DATEADD(mm, - 13, GETDATE()) AND GETDATE()
GROUP BY 
    [database_name]
    , DATEPART(yyyy,[backup_start_date])
    , DATEPART(mm, [backup_start_date])
ORDER BY [Year],[Month]) 
--SECTION 1 END
 
--SECTION 2 BEGIN
SELECT 
   b.Year,
   b.Month,
   b.[Backup Size GB],
   0 AS deltaNormal,
   b.[Compressed Backup Size GB],
   0 AS deltaCompressed
FROM BackupsSize b
WHERE b.rn = 1
UNION
SELECT 
   b.Year,
   b.Month,
   b.[Backup Size GB],
   b.[Backup Size GB] - d.[Backup Size GB] AS deltaNormal,
   b.[Compressed Backup Size GB],
   b.[Compressed Backup Size GB] - d.[Compressed Backup Size GB] AS deltaCompressed
FROM BackupsSize b
CROSS APPLY (
   SELECT bs.[Backup Size GB],bs.[Compressed Backup Size GB]
   FROM BackupsSize bs
   WHERE bs.rn = b.rn - 1
) AS d
--SECTION 2 END
