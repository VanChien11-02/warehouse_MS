SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    IF (SELECT COUNT(*) FROM dbo.[ROLE]
        WHERE MaRole IN ('ADMIN', 'QLKHO', 'NVKHO', 'KETOAN')) <> 4
        THROW 51100, N'Thiếu role ứng dụng.', 1;

    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST101', N'Nhân viên kiểm thử', '2026-01-01');
    INSERT INTO dbo.TAI_KHOAN (MaTK, MaNV, MaRole, TenTK, MatKhauHash)
        VALUES ('TST101', 'TST101', 'NVKHO', N'test.auth.1', REPLICATE('x', 60));

    IF (SELECT COUNT(*) FROM dbo.TAI_KHOAN WHERE MaNV = 'TST101' AND TrangThai = 1) <> 1
        THROW 51101, N'Tài khoản hợp lệ không được lưu.', 1;

    BEGIN TRY
        INSERT INTO dbo.TAI_KHOAN (MaTK, MaNV, MaRole, TenTK, MatKhauHash)
            VALUES ('TST102', 'TST101', 'NVKHO', N'test.auth.2', REPLICATE('x', 60));
        THROW 51102, N'Một nhân viên có nhiều tài khoản.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;

    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST102', N'Nhân viên kiểm thử hai', '2026-01-01');
    BEGIN TRY
        INSERT INTO dbo.TAI_KHOAN (MaTK, MaNV, MaRole, TenTK, MatKhauHash)
            VALUES ('TST102', 'TST102', 'NVKHO', N'test.auth.1', REPLICATE('x', 60));
        THROW 51103, N'Tên tài khoản không duy nhất.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;

    ROLLBACK TRANSACTION;
    PRINT N'Auth constraints passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
