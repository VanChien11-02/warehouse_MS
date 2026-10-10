SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai)
        VALUES ('TST701', N'Loại kiểm thử đối tác');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST701', N'Đơn vị kiểm thử đối tác');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST701', N'Sản phẩm kiểm thử đối tác', 'TST701', 'TST701');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST701', N'Nhà cung cấp kiểm thử');
    INSERT INTO dbo.DOI_TAC_NHAN_HANG (MaDTNH, TenDoiTac, LoaiDoiTac)
        VALUES ('TST701', N'Đối tác kiểm thử', N'Khách hàng');
    INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP)
        VALUES ('TST701', 'TST701');
    INSERT INTO dbo.DOI_TAC_SAN_PHAM (MaDTNH, MaSP)
        VALUES ('TST701', 'TST701');

    BEGIN TRY
        INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP)
            VALUES ('TST701', 'TST701');
        THROW 51701, N'Mapping nhà cung cấp trùng được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.DOI_TAC_SAN_PHAM (MaDTNH, MaSP)
            VALUES ('TST999', 'TST701');
        THROW 51702, N'Mapping đối tác không tồn tại được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        DELETE FROM dbo.SAN_PHAM WHERE MaSP = 'TST701';
        THROW 51703, N'Sản phẩm đang được mapping bị xóa.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    ROLLBACK TRANSACTION;
    PRINT N'Partner constraints passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
