USE [master]
GO

DECLARE @DBName as sysname;
DECLARE @db_id as int;
DECLARE @DBListCursor as CURSOR;
DECLARE @SQL as NVARCHAR(500);

SET @DBListCursor = CURSOR FORWARD_ONLY FOR
SELECT Name, database_id
  FROM sys.databases
	WHERE database_id > 4 AND name <> 'cs_helper'
 
 
OPEN @DBListCursor;
FETCH NEXT FROM @DBListCursor INTO @DBName, @db_id
 WHILE @@FETCH_STATUS = 0
BEGIN
	--PRINT CONVERT(nvarchar,@db_id)+' '+@DBName    -- Replace this line with the query you want to execute against all the DBs.
	SET @SQL = 'USE [master]' + CHAR(13) + CHAR(10) + 
	           'GO' + CHAR(13) + CHAR(10) + 
			   CHAR(13) + CHAR(10) + 
			   'ALTER DATABASE [' + @DBName + '] SET QUERY_STORE = ON ' + CHAR(13) + CHAR(10) + 
			   'GO ' + CHAR(13) + CHAR(10) + 
			   'ALTER DATABASE [' + @DBName + '] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, MAX_STORAGE_SIZE_MB = 200) ' + CHAR(13) + CHAR(10) + 
			   'GO'
	PRINT @SQL
	--EXEC sp_executesql @SQL
	--PRINT 'Next please...'
	FETCH NEXT FROM @DBListCursor INTO @DBName,@DB_id;
END
CLOSE @DBListCursor;
DEALLOCATE @DBListCursor;
