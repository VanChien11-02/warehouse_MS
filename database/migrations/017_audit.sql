:ON ERROR EXIT
IF OBJECT_ID(N'dbo.LICH_SU_THAO_TAC', N'U') IS NOT NULL
    THROW 51717, N'Audit table already exists.', 1;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r database/schema/029_lich_su_thao_tac.sql
COMMIT TRANSACTION;
GO
