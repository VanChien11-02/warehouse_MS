SET NOCOUNT ON;

BEGIN TRY
    CREATE USER wms_test_admin WITHOUT LOGIN;
    CREATE USER wms_test_manager WITHOUT LOGIN;
    CREATE USER wms_test_staff WITHOUT LOGIN;
    CREATE USER wms_test_accountant WITHOUT LOGIN;
    CREATE USER wms_test_revoke WITHOUT LOGIN;
    ALTER ROLE wms_admin ADD MEMBER wms_test_admin;
    ALTER ROLE wms_manager ADD MEMBER wms_test_manager;
    ALTER ROLE wms_staff ADD MEMBER wms_test_staff;
    ALTER ROLE wms_accountant ADD MEMBER wms_test_accountant;

    EXECUTE AS USER = 'wms_test_admin';
    IF HAS_PERMS_BY_NAME('dbo.LICH_SU_THAO_TAC', 'OBJECT', 'SELECT') <> 1
        OR HAS_PERMS_BY_NAME('dbo.LICH_SU_THAO_TAC', 'OBJECT', 'INSERT') <> 0
        OR HAS_PERMS_BY_NAME('dbo.NHAN_VIEN', 'OBJECT', 'UPDATE') <> 1
        THROW 52110, N'Quyền Admin trên nhân viên/audit sai.', 1;
    REVERT;

    EXECUTE AS USER = 'wms_test_manager';
    IF HAS_PERMS_BY_NAME('dbo.sp_HoanTatPhieuXuat', 'OBJECT', 'EXECUTE') <> 1
        OR HAS_PERMS_BY_NAME('dbo.SAN_PHAM', 'OBJECT', 'UPDATE') <> 1
        OR HAS_PERMS_BY_NAME('dbo.LICH_SU_THAO_TAC', 'OBJECT', 'SELECT') <> 0
        THROW 52111, N'Quyền Quản lý kho sai.', 1;
    REVERT;

    EXECUTE AS USER = 'wms_test_staff';
    IF HAS_PERMS_BY_NAME('dbo.PHIEU_NHAP', 'OBJECT', 'INSERT') <> 1
        OR HAS_PERMS_BY_NAME('dbo.sp_HoanTatPhieuNhap', 'OBJECT', 'EXECUTE') <> 0
        OR HAS_PERMS_BY_NAME('dbo.vw_LoSapHetHan', 'OBJECT', 'SELECT') <> 1
        OR HAS_PERMS_BY_NAME('dbo.vw_BienDongTonKhoChiTiet', 'OBJECT', 'SELECT') <> 0
        THROW 52112, N'Quyền Nhân viên kho sai.', 1;
    REVERT;

    EXECUTE AS USER = 'wms_test_accountant';
    IF HAS_PERMS_BY_NAME('dbo.vw_BienDongTonKhoChiTiet', 'OBJECT', 'SELECT') <> 1
        OR HAS_PERMS_BY_NAME('dbo.PHIEU_XUAT', 'OBJECT', 'UPDATE') <> 0
        OR HAS_PERMS_BY_NAME('dbo.LICH_SU_THAO_TAC', 'OBJECT', 'SELECT') <> 0
        THROW 52113, N'Quyền Kế toán sai.', 1;
    REVERT;

    GRANT SELECT ON dbo.SAN_PHAM TO wms_test_revoke;
    EXECUTE AS USER = 'wms_test_revoke';
    IF HAS_PERMS_BY_NAME('dbo.SAN_PHAM', 'OBJECT', 'SELECT') <> 1
        THROW 52114, N'GRANT cho user tạm không có hiệu lực.', 1;
    REVERT;
    REVOKE SELECT ON dbo.SAN_PHAM FROM wms_test_revoke;
    EXECUTE AS USER = 'wms_test_revoke';
    IF HAS_PERMS_BY_NAME('dbo.SAN_PHAM', 'OBJECT', 'SELECT') <> 0
        THROW 52115, N'REVOKE cho user tạm không có hiệu lực.', 1;
    REVERT;

    ALTER ROLE wms_admin DROP MEMBER wms_test_admin;
    ALTER ROLE wms_manager DROP MEMBER wms_test_manager;
    ALTER ROLE wms_staff DROP MEMBER wms_test_staff;
    ALTER ROLE wms_accountant DROP MEMBER wms_test_accountant;
    DROP USER wms_test_admin;
    DROP USER wms_test_manager;
    DROP USER wms_test_staff;
    DROP USER wms_test_accountant;
    DROP USER wms_test_revoke;
    PRINT N'Application database roles passed.';
END TRY
BEGIN CATCH
    IF USER_NAME() LIKE 'wms_test_%' REVERT;
    IF USER_ID(N'wms_test_admin') IS NOT NULL
        AND IS_ROLEMEMBER(N'wms_admin', N'wms_test_admin') = 1
        ALTER ROLE wms_admin DROP MEMBER wms_test_admin;
    IF USER_ID(N'wms_test_manager') IS NOT NULL
        AND IS_ROLEMEMBER(N'wms_manager', N'wms_test_manager') = 1
        ALTER ROLE wms_manager DROP MEMBER wms_test_manager;
    IF USER_ID(N'wms_test_staff') IS NOT NULL
        AND IS_ROLEMEMBER(N'wms_staff', N'wms_test_staff') = 1
        ALTER ROLE wms_staff DROP MEMBER wms_test_staff;
    IF USER_ID(N'wms_test_accountant') IS NOT NULL
        AND IS_ROLEMEMBER(N'wms_accountant', N'wms_test_accountant') = 1
        ALTER ROLE wms_accountant DROP MEMBER wms_test_accountant;
    IF USER_ID(N'wms_test_admin') IS NOT NULL DROP USER wms_test_admin;
    IF USER_ID(N'wms_test_manager') IS NOT NULL DROP USER wms_test_manager;
    IF USER_ID(N'wms_test_staff') IS NOT NULL DROP USER wms_test_staff;
    IF USER_ID(N'wms_test_accountant') IS NOT NULL DROP USER wms_test_accountant;
    IF USER_ID(N'wms_test_revoke') IS NOT NULL DROP USER wms_test_revoke;
    THROW;
END CATCH;
