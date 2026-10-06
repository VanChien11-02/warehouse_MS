SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
        VALUES ('TST401', N'Loại kiểm thử danh mục', N'Khô');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST401', N'Đơn vị kiểm thử danh mục');

    UPDATE dbo.LOAI_SAN_PHAM SET TenLoai = N'Loại đã sửa' WHERE MaLoai = 'TST401';
    UPDATE dbo.DON_VI_TINH SET TenDVT = N'Đơn vị đã sửa' WHERE MaDVT = 'TST401';
    IF (SELECT TenLoai FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'TST401') <> N'Loại đã sửa'
        THROW 51400, N'Cập nhật loại sản phẩm thất bại.', 1;
    IF (SELECT TenDVT FROM dbo.DON_VI_TINH WHERE MaDVT = 'TST401') <> N'Đơn vị đã sửa'
        THROW 51401, N'Cập nhật đơn vị tính thất bại.', 1;

    BEGIN TRY
        INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
            VALUES ('TST402', N'Đơn vị đã sửa');
        THROW 51402, N'Tên đơn vị tính trùng được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
            VALUES ('TST402', N'Loại sai bảo quản', N'Nóng');
        THROW 51403, N'Loại bảo quản sai được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST401', N'Sản phẩm tham chiếu', 'TST401', 'TST401');

    BEGIN TRY
        DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'TST401';
        THROW 51404, N'Loại sản phẩm đang được dùng bị xóa.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = 'TST401';
        THROW 51405, N'Đơn vị tính đang được dùng bị xóa.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    DELETE FROM dbo.SAN_PHAM WHERE MaSP = 'TST401';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'TST401';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = 'TST401';
    IF EXISTS (SELECT 1 FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'TST401')
        THROW 51406, N'Xóa loại sản phẩm chưa tham chiếu thất bại.', 1;
    IF EXISTS (SELECT 1 FROM dbo.DON_VI_TINH WHERE MaDVT = 'TST401')
        THROW 51407, N'Xóa đơn vị tính chưa tham chiếu thất bại.', 1;

    ROLLBACK TRANSACTION;
    PRINT N'Catalog reference CRUD constraints passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
