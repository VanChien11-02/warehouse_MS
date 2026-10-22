SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.DOI_SOAT_GIA_TRI', N'U') IS NULL
    THROW 52060, N'Accounting reconciliation table is missing.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.DOI_SOAT_GIA_TRI')
      AND name = N'PK_DOI_SOAT_GIA_TRI')
    THROW 52061, N'Reconciliation uniqueness is missing.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID(N'dbo.DOI_SOAT_GIA_TRI')
      AND name = N'FK_DOI_SOAT_GIA_TRI_TAI_KHOAN')
    THROW 52062, N'Reconciliation accountant reference is missing.', 1;
IF (SELECT COUNT(*) FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.DOI_SOAT_GIA_TRI')
      AND name IN (N'CK_DOI_SOAT_GIA_TRI_LOAI', N'CK_DOI_SOAT_GIA_TRI_TRANG_THAI',
                   N'CK_DOI_SOAT_GIA_TRI_GIA_TRI', N'CK_DOI_SOAT_GIA_TRI_KET_QUA')) <> 4
    THROW 52063, N'Reconciliation value/status checks are missing.', 1;
PRINT N'Accounting reconciliation constraints passed.';
