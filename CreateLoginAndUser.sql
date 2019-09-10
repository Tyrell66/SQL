:CONNECT ServerNameInFQDN\InstanceName,PortNumber

USE [master]
GO
IF NOT EXISTS (
	SELECT loginname 
	FROM master.dbo.syslogins 
	WHERE name = 'LoginName' 
	)
BEGIN
	CREATE LOGIN [LoginName] WITH PASSWORD=N'LoginPassword',
	DEFAULT_DATABASE=[DatabaseName],   -- Depends on your requirement
	DEFAULT_LANGUAGE=[us_english],   -- Depends on your requirement
	CHECK_EXPIRATION=OFF,   -- Depends on your requirement
	CHECK_POLICY=OFF  -- Depends on your requirement
END
GO

USE [DatabaseName]
GO
IF NOT EXISTS (
		SELECT [name]
		FROM sys.database_principals
		WHERE [name] = 'UserName'
		)
BEGIN
	CREATE USER [UserName]
	FOR LOGIN [LoginName]
	WITH DEFAULT_SCHEMA = [dbo]  -- Depends on your requirement
END
GO

ALTER ROLE [db_datareader] ADD MEMBER [UserName]  -- Depends on your requirement
ALTER ROLE [db_owner] ADD MEMBER [UserName]  -- Depends on your requirement
GO
