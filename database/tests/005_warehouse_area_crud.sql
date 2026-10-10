SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO dbo.KHO (MaKho, TenKho, DiaChi)
        VALUES ('TST501', N'Kho kiểm thử CRUD', N'Địa chỉ cũ');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST501', 'TST501', N'Khu kiểm thử CRUD', N'Khô');
    UPDATE dbo.KHO SET DiaChi = N'Địa chỉ mới' WHERE MaKho = 'TST501';
    UPDATE dbo.KHU_VUC SET TenKhuVuc = N'Khu đã sửa' WHERE MaKhuVuc = 'TST501';
    IF (SELECT DiaChi FROM dbo.KHO WHERE MaKho = 'TST501') <> N'Địa chỉ mới'
        THROW 51500, N'Cập nhật kho thất bại.', 1;
    IF (SELECT TenKhuVuc FROM dbo.KHU_VUC WHERE MaKhuVuc = 'TST501') <> N'Khu đã sửa'
        THROW 51501, N'Cập nhật khu vực thất bại.', 1;

    BEGIN TRY
        INSERT INTO dbo.KHO (MaKho, TenKho) VALUES ('TST502', N'Kho kiểm thử CRUD');
        THROW 51502, N'Tên kho trùng được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
            VALUES ('TST502', 'TST501', N'Khu đã sửa', N'Mát');
        THROW 51503, N'Tên khu vực trùng trong kho được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
            VALUES ('TST502', 'TST999', N'Khu sai kho', N'Mát');
        THROW 51504, N'Khu vực tham chiếu kho sai được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST501', 'TST501', N'Vị trí tham chiếu', 10, N'Lưu trữ');
    BEGIN TRY
        DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = 'TST501';
        THROW 51505, N'Khu vực đang được dùng bị xóa.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    ROLLBACK TRANSACTION;
    PRINT N'Warehouse and area CRUD constraints passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
