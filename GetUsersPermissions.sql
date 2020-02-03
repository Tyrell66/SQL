--DB LEVEL LOGIN PERMISSIONS =============================================================================

DECLARE @DBuser_sql VARCHAR(4000)
DECLARE @DBuser_table TABLE (DBName VARCHAR(200), UserName VARCHAR(250), LoginType VARCHAR(500), Authentication_type VARCHAR(250),AssociatedRole VARCHAR(200))
SET @DBuser_sql='SELECT ''?'' AS DBName,a.name AS Name,a.type_desc AS LoginType, CASE a.authentication_type
WHEN 0 THEN ''No Authentication''
WHEN 1 THEN ''Uncontained User - Instance Level''
WHEN 2 THEN ''Contained User - Database Level''
WHEN 3 THEN ''Windows Login User'' END As AuthenticationType,
USER_NAME(b.role_principal_id) AS AssociatedRole FROM ?.sys.database_principals a
RIGHT OUTER JOIN ?.sys.database_role_members b ON a.principal_id=b.member_principal_id
WHERE a.sid IS NOT NULL AND a.type NOT IN (''C'')
AND a.is_fixed_role <> 1 AND a.name NOT LIKE ''##%'' AND a.name NOT LIKE ''NT%''
AND a.name NOT IN (''public'',''dbo'',''guest'')
AND ''?'' NOT IN (''master'',''msdb'',''model'',''tempdb'') ORDER BY DBName'
INSERT @DBuser_table
EXEC sp_MSforeachdb @command1=@dbuser_sql
SELECT * FROM @DBuser_table
--WHERE DBName = 'TSTXENG01' and UserName like 'stx-mo%'
ORDER BY DBName
