SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Today DATE = CONVERT(DATE,
        SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time');

    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST201', N'Nhân viên test hàm', '2026-01-01');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST201', N'Nhà cung cấp test hàm');
    INSERT INTO dbo.DOI_TAC_NHAN_HANG (MaDTNH, TenDoiTac, LoaiDoiTac)
        VALUES ('TST201', N'Đối tác test hàm', N'Khách hàng');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai)
        VALUES ('TST201', N'Loại test hàm');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST201', N'Đơn vị test hàm');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST201', N'Sản phẩm test hàm', 'TST201', 'TST201');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST201', N'Kho test hàm');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST201', 'TST201', N'Khu test hàm', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST201', 'TST201', N'Vị trí tốt', 20, N'Lưu trữ'),
               ('TST202', 'TST201', N'Vị trí hỏng', 20, N'Hư hỏng');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, TrangThai, NgayHoanTat)
        VALUES ('TST201', 'TST201', 'TST201', N'DA_HOAN_THANH', SYSUTCDATETIME());
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST201', 'TST201', 11, 7.2500);
    INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, HanSuDung, SoLuongNhap)
        VALUES ('TST201', 'TST201', 'TST201', DATEADD(DAY, 5, @Today), 6),
               ('TST202', 'TST201', 'TST201', NULL, 2),
               ('TST203', 'TST201', 'TST201', DATEADD(DAY, -1, @Today), 3);
    INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
        VALUES ('TST201', 'TST201', 5),
               ('TST202', 'TST202', 2),
               ('TST201', 'TST203', 3);
    INSERT INTO dbo.PHIEU_XUAT (MaPX, MaDTNH, MaNV, TrangThai, NgayHoanTat)
        VALUES ('TST201', 'TST201', 'TST201', N'DA_HOAN_THANH', SYSUTCDATETIME());
    INSERT INTO dbo.CT_PHIEU_XUAT (MaPX, MaLo, MaViTri, SoLuong, DonGiaXuat)
        VALUES ('TST201', 'TST201', 'TST201', 1, 12.0000);

    IF dbo.fn_TonTheoSanPham('TST201') <> 10
        OR dbo.fn_TonTheoLo('TST201') <> 5
        OR dbo.fn_TonTheoLo('TST999') <> 0
        THROW 52045, N'Hàm tổng tồn theo sản phẩm/lô sai.', 1;
    IF dbo.fn_TonKhaDungTaiViTri('TST201', 'TST201') <> 5
        OR dbo.fn_TonKhaDungTaiViTri('TST202', 'TST202') <> 0
        OR dbo.fn_TonKhaDungTaiViTri('TST203', 'TST201') <> 0
        THROW 52046, N'Hàm tồn khả dụng không loại hàng hỏng/hết hạn.', 1;
    IF dbo.fn_GiaTriTonKho('TST201') <> 72.5000
        OR dbo.fn_GiaTriTonKho('TST999') <> 0
        THROW 52047, N'Hàm giá trị tồn không dùng giá nhập thực tế.', 1;
    IF (SELECT COUNT(*) FROM dbo.fn_LoSapHetHan(5) WHERE MaKho = 'TST201') <> 1
        OR (SELECT COUNT(*) FROM dbo.fn_LoSapHetHan(4) WHERE MaKho = 'TST201') <> 0
        OR (SELECT COUNT(*) FROM dbo.vw_LoSapHetHan WHERE MaKho = 'TST201') <> 1
        THROW 52048, N'Lô sắp hết hạn sai mốc ngày hoặc tình trạng.', 1;
    IF (SELECT SoLuongTon FROM dbo.vw_TonKhoTheoSanPham
        WHERE MaKho = 'TST201' AND MaSP = 'TST201') <> 10
        OR (SELECT GiaTriTon FROM dbo.vw_TonKhoTheoSanPham
        WHERE MaKho = 'TST201' AND MaSP = 'TST201') <> 72.5000
        THROW 52049, N'View tồn theo sản phẩm sai.', 1;
    IF (SELECT SUM(SoLuongNhap) FROM dbo.vw_LichSuNhapKho
        WHERE MaPN = 'TST201') <> 11
        OR (SELECT SUM(GiaTriNhap) FROM dbo.vw_LichSuNhapKho
        WHERE MaPN = 'TST201') <> 79.7500
        THROW 52050, N'View lịch sử nhập sai.', 1;
    IF (SELECT SUM(SoLuong) FROM dbo.vw_LichSuXuatKho
        WHERE MaPX = 'TST201') <> 1
        OR (SELECT SUM(GiaTriXuat) FROM dbo.vw_LichSuXuatKho
        WHERE MaPX = 'TST201') <> 12.0000
        THROW 52051, N'View lịch sử xuất sai.', 1;

    ROLLBACK TRANSACTION;
    PRINT N'Inventory functions and views passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
