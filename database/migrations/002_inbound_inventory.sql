:ON ERROR EXIT
IF OBJECT_ID(N'dbo.PHIEU_NHAP', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.CT_PHIEU_NHAP', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.LO_HANG', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.TON_KHO', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.SEQ_PHIEU_NHAP', N'SO') IS NOT NULL
    OR OBJECT_ID(N'dbo.SEQ_LO_HANG', N'SO') IS NOT NULL
    THROW 51800, N'Inbound inventory schema has already been applied or is partially present.', 1;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r database/schema/011_phieu_nhap.sql
:r database/schema/012_ct_phieu_nhap.sql
:r database/schema/013_lo_hang.sql
:r database/schema/014_ton_kho.sql
:r database/schema/015_sequences.sql
COMMIT TRANSACTION;
GO
