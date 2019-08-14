:CONNECT delacroix.prod.ci.dom
EXECUTE AS LOGIN = 'idx-ub001'
USE [master]
SELECT SUSER_NAME(), USER_NAME();  
USE [reverelivedata]
SELECT SUSER_NAME(), USER_NAME();  
REVERT
