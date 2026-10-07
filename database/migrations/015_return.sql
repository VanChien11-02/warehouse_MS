:ON ERROR EXIT
IF OBJECT_ID(N'dbo.PHIEU_TRA_HANG', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.CT_PHIEU_TRA_HANG', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.SEQ_PHIEU_TRA_HANG', N'SO') IS NOT NULL
    THROW 51715, N'Return schema already exists or is partially present.', 1;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r database/schema/026_phieu_tra_hang.sql
:r database/schema/027_ct_phieu_tra_hang.sql
:r database/schema/028_return_sequence.sql
COMMIT TRANSACTION;
GO
