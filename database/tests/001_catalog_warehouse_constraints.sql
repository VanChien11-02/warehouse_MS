SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai) VALUES ('TST001', N'Loại kiểm thử');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT) VALUES ('TST001', N'Đơn vị kiểm thử');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST001', N'Sản phẩm kiểm thử', 'TST001', 'TST001');
    INSERT INTO dbo.KHO (MaKho, TenKho) VALUES ('TST001', N'Kho kiểm thử');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST001', 'TST001', N'Khu vực kiểm thử', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST001', 'TST001', N'Vị trí kiểm thử', 100, N'Lưu trữ');

    IF (SELECT GiaNhapMacDinh FROM dbo.SAN_PHAM WHERE MaSP = 'TST001') <> 0
        THROW 51001, N'Giá nhập mặc định không đúng.', 1;

    BEGIN TRY
        INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT, GiaNhapMacDinh)
            VALUES ('TST002', N'Giá âm', 'TST001', 'TST001', -1);
        THROW 51002, N'CHECK giá âm không hoạt động.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
            VALUES ('TST002', 'TST999', N'Kho không tồn tại', N'Khô');
        THROW 51003, N'FOREIGN KEY kho không hoạt động.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('TST002', 'TST001', N'Sức chứa âm', -1, N'Lưu trữ');
        THROW 51004, N'CHECK sức chứa không hoạt động.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    ROLLBACK TRANSACTION;
    PRINT N'Catalog and warehouse constraints passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
