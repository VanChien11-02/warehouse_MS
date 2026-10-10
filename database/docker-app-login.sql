:ON ERROR EXIT
IF SUSER_ID(N'bluestock_app') IS NULL
    EXEC (N'CREATE LOGIN [bluestock_app] WITH PASSWORD = N''$(APP_DB_PASSWORD)'', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF');
ELSE
    EXEC (N'ALTER LOGIN [bluestock_app] WITH PASSWORD = N''$(APP_DB_PASSWORD)''');
GO
USE BlueStock;
GO
IF USER_ID(N'bluestock_app') IS NULL
    CREATE USER [bluestock_app] FOR LOGIN [bluestock_app];
IF IS_ROLEMEMBER(N'db_owner', N'bluestock_app') <> 1
    ALTER ROLE [db_owner] ADD MEMBER [bluestock_app];
GO
