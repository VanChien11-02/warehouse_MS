:ON ERROR EXIT
:r database/seed/catalog_demo.sql
GO

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'LSP002')
        INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
            VALUES ('LSP002', N'Sữa và chế phẩm từ sữa', N'Mát');
    IF NOT EXISTS (SELECT 1 FROM dbo.DON_VI_TINH WHERE MaDVT = 'DVT002')
        INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
            VALUES ('DVT002', N'Chai');
    IF NOT EXISTS (SELECT 1 FROM dbo.SAN_PHAM WHERE MaSP = 'SP0001')
        INSERT INTO dbo.SAN_PHAM
            (MaSP, TenSP, MaLoai, MaDVT, GiaNhapMacDinh, GiaBanMacDinh)
            VALUES ('SP0001', N'Mì ly Modern lẩu thái tôm 65g', 'LSP001', 'DVT001', 12500.0000, 18000.0000);
    IF NOT EXISTS (SELECT 1 FROM dbo.SAN_PHAM WHERE MaSP = 'SP0002')
        INSERT INTO dbo.SAN_PHAM
            (MaSP, TenSP, MaLoai, MaDVT, GiaNhapMacDinh, GiaBanMacDinh)
            VALUES ('SP0002', N'Sữa tươi thanh trùng Vinamilk 100% có đường 900ml', 'LSP002', 'DVT002', 18000.0000, 25000.0000);
    IF NOT EXISTS (SELECT 1 FROM dbo.NHA_CUNG_CAP WHERE MaNCC = 'NCC001')
        INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
            VALUES ('NCC001', N'Công ty Cổ phần Thực phẩm Acecook Việt Nam');
    IF NOT EXISTS (SELECT 1 FROM dbo.DOI_TAC_NHAN_HANG WHERE MaDTNH = 'DT0001')
        INSERT INTO dbo.DOI_TAC_NHAN_HANG (MaDTNH, TenDoiTac, LoaiDoiTac)
            VALUES ('DT0001', N'Siêu thị Co.opmart Cống Quỳnh', N'Khách hàng');
    IF NOT EXISTS (SELECT 1 FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = 'NCC001' AND MaSP = 'SP0001')
        INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP) VALUES ('NCC001', 'SP0001');
    IF NOT EXISTS (SELECT 1 FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = 'NCC001' AND MaSP = 'SP0002')
        INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP) VALUES ('NCC001', 'SP0002');
    IF NOT EXISTS (SELECT 1 FROM dbo.DOI_TAC_SAN_PHAM WHERE MaDTNH = 'DT0001' AND MaSP = 'SP0001')
        INSERT INTO dbo.DOI_TAC_SAN_PHAM (MaDTNH, MaSP) VALUES ('DT0001', 'SP0001');
    IF NOT EXISTS (SELECT 1 FROM dbo.DOI_TAC_SAN_PHAM WHERE MaDTNH = 'DT0001' AND MaSP = 'SP0002')
        INSERT INTO dbo.DOI_TAC_SAN_PHAM (MaDTNH, MaSP) VALUES ('DT0001', 'SP0002');

    IF NOT EXISTS (SELECT 1 FROM dbo.KHO WHERE MaKho = 'KHO001')
        INSERT INTO dbo.KHO (MaKho, TenKho, DiaChi)
            VALUES ('KHO001', N'Kho Trung tâm Thủ Đức', N'Số 12 Quốc lộ 1A, Phường Linh Trung, TP. Thủ Đức, TP.HCM');
    IF NOT EXISTS (SELECT 1 FROM dbo.KHU_VUC WHERE MaKhuVuc = 'KV0001')
        INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
            VALUES ('KV0001', 'KHO001', N'Khu Hàng Khô A - Thủ Đức', N'Khô');
    IF NOT EXISTS (SELECT 1 FROM dbo.KHU_VUC WHERE MaKhuVuc = 'KV0002')
        INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
            VALUES ('KV0002', 'KHO001', N'Khu Bảo Quản Mát B - Thủ Đức', N'Mát');
    IF NOT EXISTS (SELECT 1 FROM dbo.VI_TRI_KHO WHERE MaViTri = 'VT0001')
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('VT0001', 'KV0001', N'Kệ Khô A1 - Lưu trữ Hộp', 100, N'Lưu trữ');
    IF NOT EXISTS (SELECT 1 FROM dbo.VI_TRI_KHO WHERE MaViTri = 'VT0002')
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('VT0002', 'KV0001', N'Kệ Khô A2 - Lấy hàng Hộp', 50, N'Lấy hàng');
    IF NOT EXISTS (SELECT 1 FROM dbo.VI_TRI_KHO WHERE MaViTri = 'VT0003')
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('VT0003', 'KV0002', N'Kệ Mát B1 - Lưu trữ Chai', 50, N'Lưu trữ');
    IF NOT EXISTS (SELECT 1 FROM dbo.VI_TRI_KHO WHERE MaViTri = 'VT0004')
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('VT0004', 'KV0001', N'Kệ Khô Biệt Trữ Hàng Hỏng', 20, N'Hư hỏng');

    IF NOT EXISTS (SELECT 1 FROM dbo.NHAN_VIEN WHERE MaNV = 'NVD001') AND NOT EXISTS (SELECT 1 FROM dbo.NHAN_VIEN)
        INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
            VALUES ('NVD001', N'Nguyễn Hoàng Nam', '2026-01-01');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

BEGIN TRY
    BEGIN TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP WHERE MaPN IN ('PND001', 'PN0001'))
    BEGIN
        DECLARE @MaNVSeed CHAR(6) = COALESCE(
            (SELECT TOP 1 MaNV FROM dbo.NHAN_VIEN WHERE MaNV = 'NVD001'),
            (SELECT TOP 1 MaNV FROM dbo.NHAN_VIEN ORDER BY MaNV)
        );
        INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, GhiChu)
            VALUES ('PND001', 'NCC001', @MaNVSeed, N'Nhập lô hàng tiêu dùng đợt đầu cho Kho Trung tâm Thủ Đức');
        INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
            VALUES ('PND001', 'SP0001', 30, 12500.0000),
                   ('PND001', 'SP0002', 10, 18000.0000);

        DECLARE @Today DATE = CONVERT(DATE,
            SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time');
        DECLARE @Allocation NVARCHAR(MAX) = CONCAT(
            N'[{"maSanPham":"SP0001","maViTri":"VT0001","soLuong":10,"hanSuDung":"',
            CONVERT(CHAR(10), DATEADD(DAY, 30, @Today), 23),
            N'"},{"maSanPham":"SP0001","maViTri":"VT0002","soLuong":20,"hanSuDung":"',
            CONVERT(CHAR(10), DATEADD(DAY, 180, @Today), 23),
            N'"},{"maSanPham":"SP0002","maViTri":"VT0003","soLuong":10,"hanSuDung":"',
            CONVERT(CHAR(10), DATEADD(DAY, 45, @Today), 23), N'"}]');
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'PND001', @PhanBoJson = @Allocation;
    END
    ELSE IF EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP WHERE MaPN = 'PND001' AND TrangThai <> N'DA_HOAN_THANH')
        THROW 52140, N'PND001 đã tồn tại nhưng chưa hoàn tất.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

IF EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP WHERE MaPN = 'PND001')
BEGIN
    IF (SELECT COUNT(*) FROM dbo.LO_HANG WHERE MaPN = 'PND001') <> 3
        THROW 52141, N'Seed phải tạo ba lô cho PND001.', 1;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.BIEN_DONG_TON_KHO b
        JOIN dbo.LO_HANG l ON l.MaLo = b.MaLo
        WHERE l.MaPN = 'PND001' AND b.MaChungTu <> 'PND001'
    )
    BEGIN
        IF (SELECT SUM(SoLuongTon) FROM dbo.TON_KHO ton
            JOIN dbo.LO_HANG lot ON lot.MaLo = ton.MaLo WHERE lot.MaPN = 'PND001') <> 40
            THROW 52142, N'Seed phải tạo 40 đơn vị tồn cho PND001.', 1;
    END;
END;
PRINT N'Demo seed ready.';
