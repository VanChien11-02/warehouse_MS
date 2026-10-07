SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP WHERE MaPN = 'CNC001')
    THROW 52130, N'Dữ liệu concurrency test đã tồn tại.', 1;

BEGIN TRANSACTION;
INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
    VALUES ('CNC001', N'Nhân viên test đồng thời', '2026-01-01');
INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
    VALUES ('CNC001', N'Nhà cung cấp test đồng thời');
INSERT INTO dbo.DOI_TAC_NHAN_HANG (MaDTNH, TenDoiTac, LoaiDoiTac)
    VALUES ('CNC001', N'Đối tác test đồng thời', N'Khách hàng');
INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
    VALUES ('CNC001', N'Loại test đồng thời', N'Khô');
INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
    VALUES ('CNC001', N'Đơn vị test đồng thời');
INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
    VALUES ('CNC001', N'Sản phẩm test đồng thời', 'CNC001', 'CNC001');
INSERT INTO dbo.DOI_TAC_SAN_PHAM (MaDTNH, MaSP)
    VALUES ('CNC001', 'CNC001');
INSERT INTO dbo.KHO (MaKho, TenKho)
    VALUES ('CNC001', N'Kho test đồng thời');
INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
    VALUES ('CNC001', 'CNC001', N'Khu test đồng thời', N'Khô');
INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
    VALUES ('CNC001', 'CNC001', N'Vị trí test đồng thời', 10, N'Lưu trữ');
INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, TrangThai, NgayHoanTat)
    VALUES ('CNC001', 'CNC001', 'CNC001', N'DA_HOAN_THANH', SYSUTCDATETIME());
INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
    VALUES ('CNC001', 'CNC001', 6, 1.0000);
INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, HanSuDung, SoLuongNhap)
    VALUES ('CNC001', 'CNC001', 'CNC001', '2099-12-31', 6);
INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
    VALUES ('CNC001', 'CNC001', 6);
INSERT INTO dbo.PHIEU_XUAT (MaPX, MaDTNH, MaNV)
    VALUES ('CNC001', 'CNC001', 'CNC001'),
           ('CNC002', 'CNC001', 'CNC001');
INSERT INTO dbo.CT_PHIEU_XUAT (MaPX, MaLo, MaViTri, SoLuong, DonGiaXuat)
    VALUES ('CNC001', 'CNC001', 'CNC001', 4, 2.0000),
           ('CNC002', 'CNC001', 'CNC001', 4, 2.0000);
COMMIT TRANSACTION;
PRINT N'Concurrency fixture ready.';
