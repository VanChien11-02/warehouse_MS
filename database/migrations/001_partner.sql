:ON ERROR EXIT
IF OBJECT_ID(N'dbo.NHA_CUNG_CAP', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.DOI_TAC_NHAN_HANG', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.NHA_CUNG_CAP_SAN_PHAM', N'U') IS NOT NULL
    OR OBJECT_ID(N'dbo.DOI_TAC_SAN_PHAM', N'U') IS NOT NULL
    THROW 51700, N'Partner schema has already been applied or is partially present.', 1;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r database/schema/007_nha_cung_cap.sql
:r database/schema/008_doi_tac_nhan_hang.sql
:r database/schema/009_nha_cung_cap_san_pham.sql
:r database/schema/010_doi_tac_san_pham.sql
COMMIT TRANSACTION;
GO
