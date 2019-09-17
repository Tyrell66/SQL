PRINT @@SERVERNAME
GO

USE [DatabaseName]
GO
IF EXISTS (
	SELECT DP1.name AS 'role', 
	   isnull (DP2.name, 'No members') AS 'Members'
	 FROM sys.database_role_members AS DRM  
	 RIGHT OUTER JOIN sys.database_principals AS DP1  
	   ON DRM.role_principal_id = DP1.principal_id  
	 LEFT OUTER JOIN sys.database_principals AS DP2  
	   ON DRM.member_principal_id = DP2.principal_id  
	WHERE DP1.name = 'db_denydatareader'  -- Replace with the db_role you want to match.
		AND DP2.name = 'OAAD\STOXX-wft-user'  -- Replace with the login name you want to match.
	)
	BEGIN
		PRINT 'Dropping user OAAD\STOXX-wft-user from db_denydatareader'  -- Update accordingly.
		ALTER ROLE [db_denydatareader] DROP MEMBER [OAAD\STOXX-wft-user] -- Update accordingly.
	END
ELSE
	PRINT 'User OAAD\STOXX-wft-user is not a member of db_denydatareader' -- Update accordingly.
GO
