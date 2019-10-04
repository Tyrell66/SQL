DECLARE @VersionKeyword nvarchar(max)
SET @VersionKeyword = '--// Version: '

SELECT sys.schemas.[name] AS SchemaName,
       sys.objects.[name] AS ObjectName,
       CASE WHEN CHARINDEX(@VersionKeyword,OBJECT_DEFINITION(sys.objects.[object_id])) > 0 THEN SUBSTRING(OBJECT_DEFINITION(sys.objects.[object_id]),CHARINDEX(@VersionKeyword,OBJECT_DEFINITION(sys.objects.[object_id])) + LEN(@VersionKeyword) + 1, 19) END AS [Version],
       CAST(CHECKSUM(CAST(OBJECT_DEFINITION(sys.objects.[object_id]) AS nvarchar(max)) COLLATE SQL_Latin1_General_CP1_CI_AS) AS bigint) AS [Checksum]
FROM sys.objects
INNER JOIN sys.schemas ON sys.objects.[schema_id] = sys.schemas.[schema_id]
WHERE sys.schemas.[name] = 'dbo'
AND sys.objects.[name] IN('CommandExecute','DatabaseBackup','DatabaseIntegrityCheck','IndexOptimize')
ORDER BY sys.schemas.[name] ASC, sys.objects.[name] ASC
