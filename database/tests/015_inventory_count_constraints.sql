SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.PHIEU_KIEM_KE', N'U') IS NULL
    OR OBJECT_ID(N'dbo.CT_KIEM_KE', N'U') IS NULL
    OR OBJECT_ID(N'dbo.SEQ_PHIEU_KIEM_KE', N'SO') IS NULL
    THROW 51990, N'Inventory count objects are missing.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PHIEU_KIEM_KE_NV')
    OR NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PHIEU_KIEM_KE_VI_TRI')
    OR NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CT_KIEM_KE_PKK')
    OR NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CT_KIEM_KE_LO')
    THROW 51991, N'Inventory count foreign keys are missing.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_PHIEU_KIEM_KE_TRANG_THAI')
    OR NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_PHIEU_KIEM_KE_HOAN_TAT')
    OR NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_CT_KIEM_KE_SO_LUONG_HE_THONG')
    OR NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_CT_KIEM_KE_SO_LUONG_THUC_TE')
    THROW 51992, N'Inventory count checks are missing.', 1;
PRINT N'Inventory count constraints passed.';
