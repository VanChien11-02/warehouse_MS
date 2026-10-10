SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai)
        VALUES ('TST301', N'Loại sản phẩm CRUD');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST301', N'Đơn vị CRUD');
    INSERT INTO dbo.SAN_PHAM
        (MaSP, TenSP, MaLoai, MaDVT, GiaNhapMacDinh, GiaBanMacDinh)
        VALUES ('TST301', N'Sản phẩm CRUD', 'TST301', 'TST301', 10.1234, 20.5678);

    IF (SELECT GiaBanMacDinh FROM dbo.SAN_PHAM WHERE MaSP = 'TST301') <> 20.5678
        THROW 51300, N'Giá sản phẩm không giữ bốn chữ số thập phân.', 1;

    BEGIN TRY
        INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
            VALUES ('TST301', N'Mã trùng', 'TST301', 'TST301');
        THROW 51301, N'Mã sản phẩm trùng được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
            VALUES ('TST302', N'Loại sai', 'TST999', 'TST301');
        THROW 51302, N'Loại sản phẩm không tồn tại được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    UPDATE dbo.SAN_PHAM
    SET TenSP = N'Sản phẩm đã sửa', GiaNhapMacDinh = 11.1111
    WHERE MaSP = 'TST301';
    IF (SELECT GiaNhapMacDinh FROM dbo.SAN_PHAM WHERE MaSP = 'TST301') <> 11.1111
        THROW 51303, N'Cập nhật sản phẩm thất bại.', 1;

    DELETE FROM dbo.SAN_PHAM WHERE MaSP = 'TST301';
    IF EXISTS (SELECT 1 FROM dbo.SAN_PHAM WHERE MaSP = 'TST301')
        THROW 51304, N'Xóa sản phẩm chưa tham chiếu thất bại.', 1;

    ROLLBACK TRANSACTION;
    PRINT N'Product CRUD constraints passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
