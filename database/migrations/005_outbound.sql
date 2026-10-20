:ON ERROR EXIT
IF OBJECT_ID(N'dbo.PHIEU_XUAT', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.CT_PHIEU_XUAT', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.SEQ_PHIEU_XUAT', N'SO') IS NOT NULL
    THROW 51930, N'Outbound schema has already been applied or is partially present.', 1;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r database/schema/016_phieu_xuat.sql
:r database/schema/017_ct_phieu_xuat.sql
:r database/schema/018_outbound_sequence.sql
COMMIT TRANSACTION;
GO
