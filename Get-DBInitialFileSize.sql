USE cs_helper
GO
SELECT 

db.name AS [Logical Name],
CASE WHEN db.[type] = 0 THEN 'Rows Data'
ELSE 'Log' END AS [File Type],
(db.size*8)/1024 AS initialSize

FROM sys.database_files db
