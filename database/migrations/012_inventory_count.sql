:ON ERROR EXIT
IF OBJECT_ID(N'dbo.PHIEU_KIEM_KE', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.CT_KIEM_KE', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.SEQ_PHIEU_KIEM_KE', N'SO') IS NOT NULL
    THROW 51714, N'Inventory count schema already exists or is partially present.', 1;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r database/schema/023_phieu_kiem_ke.sql
:r database/schema/024_ct_kiem_ke.sql
:r database/schema/025_count_sequence.sql
COMMIT TRANSACTION;
GO
