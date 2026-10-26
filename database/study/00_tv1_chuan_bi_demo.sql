-- CHUẨN BỊ MỘT LẦN. Chọn đúng BlueStock trong SSMS, rồi chạy toàn file.
-- Dữ liệu học riêng: HS0001. Không dùng phiếu thật của người dùng.
-- Nếu báo trùng mã: dừng, không tự xóa dữ liệu đang có.
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRAN;
    IF EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaLo IN ('HS0001', 'HS0002'))
        THROW 52902, N'Mã lô demo đã có dữ liệu; dừng để tránh dùng nhầm.', 1;
    INSERT dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('HS0001', N'Nhân viên demo SSMS TV1', '2026-01-01');
    INSERT dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('HS0001', N'Nhà cung cấp demo SSMS TV1');
    INSERT dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
        VALUES ('HS0001', N'Loại demo SSMS TV1', N'Khô');
    INSERT dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('HS0001', N'Hộp demo SSMS TV1');
    INSERT dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('HS0001', N'Hàng demo SSMS TV1', 'HS0001', 'HS0001');
    INSERT dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP) VALUES ('HS0001', 'HS0001');
    INSERT dbo.KHO (MaKho, TenKho) VALUES ('HS0001', N'Kho demo SSMS TV1');
    INSERT dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('HS0001', 'HS0001', N'Khu demo SSMS TV1', N'Khô');
    INSERT dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('HS0001', 'HS0001', N'Kệ demo SSMS TV1', 100, N'Lưu trữ'),
               ('HS0002', 'HS0001', N'Kệ nhỏ demo SSMS TV1', 5, N'Lưu trữ');
    INSERT dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, GhiChu)
        VALUES ('HS0001', 'HS0001', 'HS0001', N'DEMO_SSMS_TV1_20261025');
    INSERT dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('HS0001', 'HS0001', 10, 12500);
    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    THROW;
END CATCH;

SELECT MaPN, MaSP, SoLuong, DonGiaNhap FROM dbo.CT_PHIEU_NHAP WHERE MaPN = 'HS0001';
SELECT MaViTri, SucChua FROM dbo.VI_TRI_KHO WHERE MaViTri IN ('HS0001', 'HS0002');
