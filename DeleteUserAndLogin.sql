:CONNECT ServerNameInFQDN\InstanceName,PortNumber   -- Replace by exact values.
GO

USE [DatabaseName]  -- Define here the Database name you want to target.
GO
IF EXISTS (
		SELECT [name]
		FROM sys.database_principals
		WHERE [name] = 'UserName'   -- Replace UserName by the ID of the user.
		)
BEGIN
	DROP USER [UserName]   -- Replace UserName by the ID of the user.
END
GO
-- Duplicate the block above if you need to delete several users or in savaral databases.

USE [master]  -- Leave master as it is. 
GO
IF EXISTS (
	SELECT loginname 
	FROM master.dbo.syslogins 
	WHERE name = 'LoginName'          -- Replace LoginName by the ID of the login.
	)
BEGIN
	DROP LOGIN [LoginName]          -- Replace LoginName by the ID of the login.
END
GO
-- Duplicate the block above if you need to delete several logins.
