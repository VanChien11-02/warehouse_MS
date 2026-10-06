:ON ERROR EXIT
IF OBJECT_ID(N'dbo.PHIEU_CHUYEN_KHO', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.CT_PHIEU_CHUYEN_KHO', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.SEQ_PHIEU_CHUYEN_KHO', N'SO') IS NOT NULL
    THROW 51712, N'Transfer schema already exists or is partially present.', 1;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r database/schema/020_phieu_chuyen_kho.sql
:r database/schema/021_ct_phieu_chuyen_kho.sql
:r database/schema/022_transfer_sequence.sql
COMMIT TRANSACTION;
GO
