WITH MostRecentRestore AS
(
SELECT 
RowNum = ROW_NUMBER() OVER (PARTITION BY RH.Destination_database_name ORDER BY RH.Restore_Date DESC),
RH.Restore_date, 
BS.[database_name] as Source_Database, 
RH.Destination_Database_Name, 
BS.Backup_Start_Date, 
BS.Backup_Finish_Date, 
CASE WHEN RH.restore_type = 'D' THEN 'Database'
  WHEN RH.restore_type = 'F' THEN 'File'
  WHEN RH.restore_type = 'G' THEN 'Filegroup'
  WHEN RH.restore_type = 'I' THEN 'Differential'
  WHEN RH.restore_type = 'L' THEN 'Log'
  WHEN RH.restore_type = 'V' THEN 'Verifyonly'
  WHEN RH.restore_type = 'R' THEN 'Revert'
  ELSE RH.restore_type 
END AS Restore_Type,
RH.[Replace],
RH.[Recovery],
RH.Restore_Date AS Restored_On,
BMF.physical_device_name AS Restored_From,
RF.destination_phys_name AS Current_DB_File_Location,
RH.user_name AS Restored_By,
BS.machine_name,
BS.Server_Name
FROM msdb.dbo.RestoreHistory RH 
INNER JOIN msdb.dbo.BackupSet BS ON RH.backup_set_id = BS.backup_set_id
INNER JOIN msdb.dbo.restorefile RF ON RH.Restore_History_id = RF.Restore_History_id
INNER JOIN msdb.dbo.Backupmediafamily BMF ON bs.media_set_id = bmf.media_set_id
)
SELECT *
FROM MostRecentRestore
WHERE [RowNum] = 1 AND destination_database_name = 'YourDatabaseName'
