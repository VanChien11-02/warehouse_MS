SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO dbo.KHO (MaKho, TenKho) VALUES ('TST601', N'Kho kiểm thử vị trí');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST601', 'TST601', N'Khu kiểm thử vị trí', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST601', 'TST601', N'Kệ kiểm thử', 100, N'Lưu trữ');
    UPDATE dbo.VI_TRI_KHO SET TenViTri = N'Kệ đã sửa' WHERE MaViTri = 'TST601';
    IF (SELECT TenViTri FROM dbo.VI_TRI_KHO WHERE MaViTri = 'TST601') <> N'Kệ đã sửa'
        THROW 51600, N'Cập nhật vị trí thất bại.', 1;

    BEGIN TRY
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('TST602', 'TST601', N'Kệ đã sửa', 50, N'Lấy hàng');
        THROW 51601, N'Tên vị trí trùng trong khu vực được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('TST602', 'TST999', N'Sai khu vực', 50, N'Lưu trữ');
        THROW 51602, N'Vị trí tham chiếu khu vực sai được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('TST602', 'TST601', N'Kệ âm', -1, N'Lưu trữ');
        THROW 51603, N'Sức chứa âm được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri = 'TST601';
    IF EXISTS (SELECT 1 FROM dbo.VI_TRI_KHO WHERE MaViTri = 'TST601')
        THROW 51604, N'Xóa vị trí chưa tham chiếu thất bại.', 1;

    ROLLBACK TRANSACTION;
    PRINT N'Position CRUD constraints passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
