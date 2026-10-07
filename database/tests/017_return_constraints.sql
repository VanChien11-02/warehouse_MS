SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.PHIEU_TRA_HANG', N'U') IS NULL
    OR OBJECT_ID(N'dbo.CT_PHIEU_TRA_HANG', N'U') IS NULL
    OR OBJECT_ID(N'dbo.SEQ_PHIEU_TRA_HANG', N'SO') IS NULL
    THROW 52010, N'Return objects are missing.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PHIEU_TRA_HANG_PX')
    OR NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PHIEU_TRA_HANG_NV')
    OR NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CT_PHIEU_TRA_HANG_PTH')
    OR NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CT_PHIEU_TRA_HANG_LO')
    OR NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CT_PHIEU_TRA_HANG_VI_TRI')
    THROW 52011, N'Return foreign keys are missing.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_CT_PHIEU_TRA_HANG_SO_LUONG')
    OR NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_CT_PHIEU_TRA_HANG_TINH_TRANG')
    OR NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_PHIEU_TRA_HANG_TRANG_THAI')
    OR NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_PHIEU_TRA_HANG_HOAN_TAT')
    THROW 52012, N'Return checks are missing.', 1;
PRINT N'Return constraints passed.';
