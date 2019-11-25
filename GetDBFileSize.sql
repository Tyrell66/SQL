-- Source: https://www.mssqltips.com/sqlservertip/1629/determine-free-space-consumed-space-and-total-space-allocated-for-sql-server-databases/

CREATE PROCEDURE dbo.usp_Sizing @Granularity VARCHAR(10) = NULL, @Database_Name sysname = NULL AS   
DECLARE @SQL VARCHAR(5000)   

IF EXISTS (SELECT NAME FROM tempdb..sysobjects WHERE NAME = '##Results')    
   BEGIN    
       DROP TABLE ##Results    
   END   
      
CREATE TABLE ##Results ([Database Name] sysname, 
[File Name] sysname, 
[Physical Name] NVARCHAR(260),
[File Type] VARCHAR(4), 
[Total Size in Mb] INT, 
[Available Space in Mb] INT, 
[Growth Units] VARCHAR(15), 
[Max File Size in Mb] INT)   

SELECT @SQL =    
'USE [?] INSERT INTO ##Results([Database Name], [File Name], [Physical Name],    
[File Type], [Total Size in Mb], [Available Space in Mb],    
[Growth Units], [Max File Size in Mb])    
SELECT DB_NAME(),   
[name] AS [File Name],    
physical_name AS [Physical Name],    
[File Type] =    
CASE type   
WHEN 0 THEN ''Data'''    
+   
           'WHEN 1 THEN ''Log'''   
+   
       'END,   
[Total Size in Mb] =   
CASE ceiling([size]/128)    
WHEN 0 THEN 1   
ELSE ceiling([size]/128)   
END,   
[Available Space in Mb] =    
CASE ceiling([size]/128)   
WHEN 0 THEN (1 - CAST(FILEPROPERTY([name], ''SpaceUsed''' + ') as int) /128)   
ELSE (([size]/128) - CAST(FILEPROPERTY([name], ''SpaceUsed''' + ') as int) /128)   
END,   
[Growth Units]  =    
CASE [is_percent_growth]    
WHEN 1 THEN CAST(growth AS varchar(20)) + ''%'''   
+   
           'ELSE CAST(growth*8/1024 AS varchar(20)) + ''Mb'''   
+   
       'END,   
[Max File Size in Mb] =    
CASE [max_size]   
WHEN -1 THEN NULL   
WHEN 268435456 THEN NULL   
ELSE [max_size]   
END   
FROM sys.database_files   
ORDER BY [File Type], [file_id]'   

--Print the command to be issued against all databases   
PRINT @SQL   

--Run the command against each database   
EXEC sp_MSforeachdb @SQL   

--UPDATE ##Results SET [Free Space %] = [Available Space in Mb]/[Total Size in Mb] * 100   

--Return the Results   
--If @Database_Name is NULL:   
IF @Database_Name IS NULL   
   BEGIN   
       IF @Granularity = 'Database'   
           BEGIN   
               SELECT    
               T.[Database Name],   
               T.[Total Size in Mb] AS [DB Size (Mb)],   
               T.[Available Space in Mb] AS [DB Free (Mb)],   
               T.[Consumed Space in Mb] AS [DB Used (Mb)],   
               D.[Total Size in Mb] AS [Data Size (Mb)],   
               D.[Available Space in Mb] AS [Data Free (Mb)],   
               D.[Consumed Space in Mb] AS [Data Used (Mb)],   
               CEILING(CAST(D.[Available Space in Mb] AS decimal(10,1))/D.[Total Size in Mb]*100) AS [Data Free %],   
               L.[Total Size in Mb] AS [Log Size (Mb)],   
               L.[Available Space in Mb] AS [Log Free (Mb)],   
               L.[Consumed Space in Mb] AS [Log Used (Mb)],   
               CEILING(CAST(L.[Available Space in Mb] AS decimal(10,1))/L.[Total Size in Mb]*100) AS [Log Free %]   
               FROM    
                   (   
                   SELECT [Database Name],   
                       SUM([Total Size in Mb]) AS [Total Size in Mb],   
                       SUM([Available Space in Mb]) AS [Available Space in Mb],   
                       SUM([Total Size in Mb]-[Available Space in Mb]) AS [Consumed Space in Mb]    
                   FROM ##Results   
                   GROUP BY [Database Name]   
                   ) AS T   
                   INNER JOIN    
                   (   
                   SELECT [Database Name],   
                       SUM([Total Size in Mb]) AS [Total Size in Mb],   
                       SUM([Available Space in Mb]) AS [Available Space in Mb],   
                       SUM([Total Size in Mb]-[Available Space in Mb]) AS [Consumed Space in Mb]    
                   FROM ##Results   
                   WHERE ##Results.[File Type] = 'Data'   
                   GROUP BY [Database Name]   
                   ) AS D ON T.[Database Name] = D.[Database Name]   
                   INNER JOIN   
                   (   
                   SELECT [Database Name],   
                       SUM([Total Size in Mb]) AS [Total Size in Mb],   
                       SUM([Available Space in Mb]) AS [Available Space in Mb],   
                       SUM([Total Size in Mb]-[Available Space in Mb]) AS [Consumed Space in Mb]    
                   FROM ##Results   
                   WHERE ##Results.[File Type] = 'Log'   
                   GROUP BY [Database Name]   
                   ) AS L ON T.[Database Name] = L.[Database Name]   
               ORDER BY D.[Database Name]   
           END   
   ELSE   
       BEGIN   
           SELECT [Database Name],   
               [File Name],   
               [Physical Name],   
               [File Type],   
               [Total Size in Mb] AS [DB Size (Mb)],   
               [Available Space in Mb] AS [DB Free (Mb)],   
               CEILING(CAST([Available Space in Mb] AS decimal(10,1)) / [Total Size in Mb]*100) AS [Free Space %],   
               [Growth Units],   
               [Max File Size in Mb] AS [Grow Max Size (Mb)]    
           FROM ##Results    
       END   
   END   

--Return the Results   
--If @Database_Name is provided   
ELSE   
   BEGIN   
       IF @Granularity = 'Database'   
           BEGIN   
               SELECT    
               T.[Database Name],   
               T.[Total Size in Mb] AS [DB Size (Mb)],   
               T.[Available Space in Mb] AS [DB Free (Mb)],   
               T.[Consumed Space in Mb] AS [DB Used (Mb)],   
               D.[Total Size in Mb] AS [Data Size (Mb)],   
               D.[Available Space in Mb] AS [Data Free (Mb)],   
               D.[Consumed Space in Mb] AS [Data Used (Mb)],   
               CEILING(CAST(D.[Available Space in Mb] AS decimal(10,1))/D.[Total Size in Mb]*100) AS [Data Free %],   
               L.[Total Size in Mb] AS [Log Size (Mb)],   
               L.[Available Space in Mb] AS [Log Free (Mb)],   
               L.[Consumed Space in Mb] AS [Log Used (Mb)],   
               CEILING(CAST(L.[Available Space in Mb] AS decimal(10,1))/L.[Total Size in Mb]*100) AS [Log Free %]   
               FROM    
                   (   
                   SELECT [Database Name],   
                       SUM([Total Size in Mb]) AS [Total Size in Mb],   
                       SUM([Available Space in Mb]) AS [Available Space in Mb],   
                       SUM([Total Size in Mb]-[Available Space in Mb]) AS [Consumed Space in Mb]    
                   FROM ##Results   
                   WHERE [Database Name] = @Database_Name   
                   GROUP BY [Database Name]   
                   ) AS T   
                   INNER JOIN    
                   (   
                   SELECT [Database Name],   
                       SUM([Total Size in Mb]) AS [Total Size in Mb],   
                       SUM([Available Space in Mb]) AS [Available Space in Mb],   
                       SUM([Total Size in Mb]-[Available Space in Mb]) AS [Consumed Space in Mb]    
                   FROM ##Results   
                   WHERE ##Results.[File Type] = 'Data'   
                       AND [Database Name] = @Database_Name   
                   GROUP BY [Database Name]   
                   ) AS D ON T.[Database Name] = D.[Database Name]   
                   INNER JOIN   
                   (   
                   SELECT [Database Name],   
                       SUM([Total Size in Mb]) AS [Total Size in Mb],   
                       SUM([Available Space in Mb]) AS [Available Space in Mb],   
                       SUM([Total Size in Mb]-[Available Space in Mb]) AS [Consumed Space in Mb]    
                   FROM ##Results   
                   WHERE ##Results.[File Type] = 'Log'   
                       AND [Database Name] = @Database_Name   
                   GROUP BY [Database Name]   
                   ) AS L ON T.[Database Name] = L.[Database Name]   
               ORDER BY D.[Database Name]   
           END   
       ELSE   
           BEGIN   
               SELECT [Database Name],   
               [File Name],   
               [Physical Name],   
               [File Type],   
               [Total Size in Mb] AS [DB Size (Mb)],   
               [Available Space in Mb] AS [DB Free (Mb)],   
               CEILING(CAST([Available Space in Mb] AS decimal(10,1))/[Total Size in Mb]*100) AS [Free Space %],   
               [Growth Units],   
               [Max File Size in Mb] AS [Grow Max Size (Mb)]    
               FROM ##Results    
               WHERE [Database Name] = @Database_Name   
           END   
   END   
DROP TABLE ##Results   
