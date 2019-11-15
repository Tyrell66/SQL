USE [DBName]
GO

SELECT
 SUBSTRING(a.FILENAME, 1, 1) Drive,
 [FILE_SIZE_MB] = convert(decimal(12,2),
round(a.size/128.000,2)),
 [SPACE_USED_MB] = convert(decimal(12,2),
round(fileproperty(a.name,'SpaceUsed')/128.000,2)),
 [FREE_SPACE_MB] = convert(decimal(12,2),
round((a.size-fileproperty(a.name,'SpaceUsed'))/128.000,2)) ,
 [FREE_SPACE_%] = convert(decimal(12,2),
(convert(decimal(12,2),round((a.size-fileproperty(a.name,'SpaceUsed'))/128.000,2)) 
/ convert(decimal(12,2),round(a.size/128.000,2)) * 100)),
 a.NAME, a.FILENAME
FROM dbo.sysfiles a
ORDER BY Drive, [Name] 
GO
