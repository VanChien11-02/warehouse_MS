SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST111', N'Nhân viên test xuất', '2026-01-01');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST111', N'Nhà cung cấp test xuất');
    INSERT INTO dbo.DOI_TAC_NHAN_HANG (MaDTNH, TenDoiTac, LoaiDoiTac)
        VALUES ('TST111', N'Đối tác test xuất', N'Khách hàng');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai)
        VALUES ('TST111', N'Loại test xuất');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST111', N'Đơn vị test xuất');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST111', N'Sản phẩm test xuất', 'TST111', 'TST111');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST111', N'Kho test xuất');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST111', 'TST111', N'Khu test xuất', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST111', 'TST111', N'Kệ test xuất', 10, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, TrangThai, NgayHoanTat)
        VALUES ('TST111', 'TST111', 'TST111', N'DA_HOAN_THANH', SYSUTCDATETIME());
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST111', 'TST111', 10, 10.1234);
    INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, SoLuongNhap)
        VALUES ('TST111', 'TST111', 'TST111', 10);
    INSERT INTO dbo.PHIEU_XUAT (MaPX, MaDTNH, MaNV)
        VALUES ('TST111', 'TST111', 'TST111');
    INSERT INTO dbo.CT_PHIEU_XUAT (MaPX, MaLo, MaViTri, SoLuong, DonGiaXuat)
        VALUES ('TST111', 'TST111', 'TST111', 2, 12.3456);

    IF (SELECT DonGiaXuat FROM dbo.CT_PHIEU_XUAT
        WHERE MaPX = 'TST111' AND MaLo = 'TST111' AND MaViTri = 'TST111') <> 12.3456
        THROW 51931, N'Đơn giá xuất không giữ bốn chữ số thập phân.', 1;

    BEGIN TRY
        UPDATE dbo.CT_PHIEU_XUAT SET SoLuong = 0
        WHERE MaPX = 'TST111' AND MaLo = 'TST111' AND MaViTri = 'TST111';
        THROW 51932, N'Số lượng xuất 0 được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.CT_PHIEU_XUAT (MaPX, MaLo, MaViTri, SoLuong, DonGiaXuat)
            VALUES ('TST111', 'TST111', 'TST999', 1, 1);
        THROW 51933, N'Vị trí xuất không tồn tại được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        UPDATE dbo.PHIEU_XUAT SET TrangThai = N'DA_HOAN_THANH' WHERE MaPX = 'TST111';
        THROW 51934, N'Phiếu xuất hoàn tất không có thời điểm được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    ROLLBACK TRANSACTION;
    PRINT N'Outbound constraints passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
