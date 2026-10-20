:ON ERROR EXIT
:r database/seed/catalog_demo.sql
GO

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'LSP002')
        INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
            VALUES ('LSP002', N'Hàng mát mẫu', N'Mát');
    IF NOT EXISTS (SELECT 1 FROM dbo.DON_VI_TINH WHERE MaDVT = 'DVT002')
        INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
            VALUES ('DVT002', N'Chai');
    IF NOT EXISTS (SELECT 1 FROM dbo.SAN_PHAM WHERE MaSP = 'SP0001')
        INSERT INTO dbo.SAN_PHAM
            (MaSP, TenSP, MaLoai, MaDVT, GiaNhapMacDinh, GiaBanMacDinh)
            VALUES ('SP0001', N'Mì hộp mẫu', 'LSP001', 'DVT001', 12500.0000, 18000.0000);
    IF NOT EXISTS (SELECT 1 FROM dbo.SAN_PHAM WHERE MaSP = 'SP0002')
        INSERT INTO dbo.SAN_PHAM
            (MaSP, TenSP, MaLoai, MaDVT, GiaNhapMacDinh, GiaBanMacDinh)
            VALUES ('SP0002', N'Sữa tươi mẫu', 'LSP002', 'DVT002', 18000.0000, 25000.0000);
    IF NOT EXISTS (SELECT 1 FROM dbo.NHA_CUNG_CAP WHERE MaNCC = 'NCC001')
        INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
            VALUES ('NCC001', N'Nhà cung cấp mẫu');
    IF NOT EXISTS (SELECT 1 FROM dbo.DOI_TAC_NHAN_HANG WHERE MaDTNH = 'DT0001')
        INSERT INTO dbo.DOI_TAC_NHAN_HANG (MaDTNH, TenDoiTac, LoaiDoiTac)
            VALUES ('DT0001', N'Khách hàng mẫu', N'Khách hàng');
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
            VALUES ('KHO001', N'Kho mẫu', N'Địa chỉ giả phục vụ demo');
    IF NOT EXISTS (SELECT 1 FROM dbo.KHU_VUC WHERE MaKhuVuc = 'KV0001')
        INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
            VALUES ('KV0001', 'KHO001', N'Khu khô mẫu', N'Khô');
    IF NOT EXISTS (SELECT 1 FROM dbo.KHU_VUC WHERE MaKhuVuc = 'KV0002')
        INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
            VALUES ('KV0002', 'KHO001', N'Khu mát mẫu', N'Mát');
    IF NOT EXISTS (SELECT 1 FROM dbo.VI_TRI_KHO WHERE MaViTri = 'VT0001')
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('VT0001', 'KV0001', N'Kệ khô A', 100, N'Lưu trữ');
    IF NOT EXISTS (SELECT 1 FROM dbo.VI_TRI_KHO WHERE MaViTri = 'VT0002')
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('VT0002', 'KV0001', N'Kệ lấy hàng B', 50, N'Lấy hàng');
    IF NOT EXISTS (SELECT 1 FROM dbo.VI_TRI_KHO WHERE MaViTri = 'VT0003')
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('VT0003', 'KV0002', N'Kệ mát A', 50, N'Lưu trữ');
    IF NOT EXISTS (SELECT 1 FROM dbo.VI_TRI_KHO WHERE MaViTri = 'VT0004')
        INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES ('VT0004', 'KV0001', N'Kệ hàng hỏng', 20, N'Hư hỏng');

    IF NOT EXISTS (SELECT 1 FROM dbo.NHAN_VIEN WHERE MaNV = 'NVD001')
        INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
            VALUES ('NVD001', N'Nhân viên dữ liệu mẫu', '2026-01-01');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

BEGIN TRY
    BEGIN TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP WHERE MaPN = 'PND001')
    BEGIN
        INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, GhiChu)
            VALUES ('PND001', 'NCC001', 'NVD001', N'Dữ liệu giả để thử tồn và FEFO');
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
    ELSE IF (SELECT TrangThai FROM dbo.PHIEU_NHAP WHERE MaPN = 'PND001') <> N'DA_HOAN_THANH'
        THROW 52140, N'PND001 đã tồn tại nhưng chưa hoàn tất.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

IF (SELECT COUNT(*) FROM dbo.LO_HANG WHERE MaPN = 'PND001') <> 3
    THROW 52141, N'Seed phải tạo ba lô mẫu.', 1;
IF (SELECT SUM(SoLuongTon) FROM dbo.TON_KHO ton
    JOIN dbo.LO_HANG lot ON lot.MaLo = ton.MaLo WHERE lot.MaPN = 'PND001') <> 40
    THROW 52142, N'Seed phải tạo 40 đơn vị tồn mẫu.', 1;
PRINT N'Demo seed ready.';
