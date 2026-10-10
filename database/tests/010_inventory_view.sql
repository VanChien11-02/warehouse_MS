SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST101', N'Nhân viên test view tồn', '2026-01-01');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST101', N'Nhà cung cấp test view tồn');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai)
        VALUES ('TST101', N'Loại test view tồn');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST101', N'Đơn vị test view tồn');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST101', N'Sản phẩm test view tồn', 'TST101', 'TST101');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST101', N'Kho test view tồn');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST101', 'TST101', N'Khu test view tồn', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST101', 'TST101', N'Kệ test view tồn', 100, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, TrangThai, NgayHoanTat)
        VALUES ('TST101', 'TST101', 'TST101', N'DA_HOAN_THANH', SYSUTCDATETIME());
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV)
        VALUES ('TST102', 'TST101', 'TST101');
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST101', 'TST101', 4, 12.3456),
               ('TST102', 'TST101', 2, 99.9999);
    INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, SoLuongNhap)
        VALUES ('TST101', 'TST101', 'TST101', 4),
               ('TST102', 'TST102', 'TST101', 2);
    INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
        VALUES ('TST101', 'TST101', 4),
               ('TST101', 'TST102', 2);

    IF (SELECT COUNT(*) FROM dbo.vw_TonKhoChiTiet WHERE MaViTri = 'TST101') <> 1
        THROW 51921, N'View tồn phải loại phiếu nhập nháp.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.vw_TonKhoChiTiet
        WHERE MaViTri = 'TST101' AND MaLo = 'TST101' AND MaKho = 'TST101'
          AND MaSP = 'TST101' AND MaPN = 'TST101' AND SoLuongTon = 4
          AND DonGiaNhap = 12.3456)
        THROW 51922, N'View tồn không truy được vị trí, lô, chứng từ và giá gốc.', 1;

    ROLLBACK TRANSACTION;
    PRINT N'Inventory view passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
