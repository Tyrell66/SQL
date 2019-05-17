USE DBName
GO
SELECT file_id, name as [logical_file_name], physical_name
FROM sys.database_files
