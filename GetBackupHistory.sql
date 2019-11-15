SELECT
	sysdb.name,
	bkup.user_name,
	bkup.backup_finish_date,
	CASE 
		WHEN type='D' then '** FULL **'
		WHEN type='I' then 'DIFFERENTIAL'
		WHEN type='L' then 'LOG'
	END AS Backup_Type,
	(STR(ABS(DATEDIFF(day, GetDate(),(backup_finish_date))))) AS 'Days_Ago',
	ceiling(bkup.backup_size /1048576) AS 'Size Meg',
	cast((bkup.backup_size /1073741824) as decimal (9,2)) AS 'Gig',
	cast((bkup.compressed_backup_size /1073741824) as decimal (9,2)) AS 'Compr_Gig',
	server_name, 
	sysdb.crdate,
	datediff(minute, bkup.backup_start_date, bkup.backup_finish_date) 	as 'Mins',
	cast(cast(datediff(minute, bkup.backup_start_date, bkup.backup_finish_date) AS decimal (8,3))/60 AS decimal (8,1)) AS 'Hours',
	first_lsn, 
	last_lsn, 
	checkpoint_lsn

FROM master.dbo.sysdatabases sysdb
	LEFT OUTER JOIN msdb.dbo.backupset bkup 
		ON bkup.database_name = sysdb.name

WHERE backup_finish_date > DATEADD(DAY, -60, (getdate()))  -- Last 2 days
	AND sysdb.name = 'Cadis_DB'

ORDER BY sysdb.name, bkup.backup_finish_date DESC
GO
