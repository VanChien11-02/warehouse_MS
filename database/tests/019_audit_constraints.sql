SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.LICH_SU_THAO_TAC', N'U') IS NULL
    THROW 52030, N'Audit table is missing.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_LICH_SU_THAO_TAC_TAI_KHOAN')
    THROW 52031, N'Audit account foreign key is missing.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_LICH_SU_THAO_TAC_HANH_DONG')
    OR NOT EXISTS (SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_LICH_SU_THAO_TAC_DU_LIEU_CU')
    OR NOT EXISTS (SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_LICH_SU_THAO_TAC_DU_LIEU_MOI')
    THROW 52032, N'Audit action/JSON checks are missing.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE name = N'IX_LICH_SU_THAO_TAC_THOI_GIAN'
      AND object_id = OBJECT_ID(N'dbo.LICH_SU_THAO_TAC'))
    THROW 52033, N'Audit time index is missing.', 1;
PRINT N'Audit constraints passed.';
