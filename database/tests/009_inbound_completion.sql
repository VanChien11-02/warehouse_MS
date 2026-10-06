SET NOCOUNT ON;
SET XACT_ABORT OFF;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST901', N'Nhân viên test hoàn tất nhập', '2026-01-01');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST901', N'Nhà cung cấp test hoàn tất nhập'),
               ('TST902', N'Nhà cung cấp thiếu mapping');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
        VALUES ('TST901', N'Loại test hoàn tất nhập', N'Khô');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST901', N'Đơn vị test hoàn tất nhập');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST901', N'Sản phẩm test hoàn tất nhập', 'TST901', 'TST901');
    INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP)
        VALUES ('TST901', 'TST901');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST901', N'Kho test hoàn tất nhập');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST901', 'TST901', N'Khu khô test hoàn tất nhập', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST901', 'TST901', N'Kệ test hoàn tất nhập', 10, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV)
        VALUES ('TST901', 'TST901', 'TST901'),
               ('TST902', 'TST901', 'TST901'),
               ('TST903', 'TST902', 'TST901'),
               ('TST904', 'TST901', 'TST901');
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST901', 'TST901', 6, 10.1234),
               ('TST902', 'TST901', 5, 10.1234),
               ('TST903', 'TST901', 1, 10.1234),
               ('TST904', 'TST901', 2, 10.1234);
    COMMIT TRANSACTION;

    EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST901',
        @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST901","soLuong":6,"ngaySanXuat":"2026-01-01","hanSuDung":"2026-12-31"}]';

    IF (SELECT TrangThai FROM dbo.PHIEU_NHAP WHERE MaPN = 'TST901') <> N'DA_HOAN_THANH'
        THROW 51901, N'Phiếu nhập không hoàn tất.', 1;
    IF (SELECT COUNT(*) FROM dbo.LO_HANG WHERE MaPN = 'TST901') <> 1
        THROW 51902, N'Số lô tạo không đúng.', 1;
    IF (SELECT SUM(ton.SoLuongTon) FROM dbo.TON_KHO ton
        JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo WHERE lo.MaPN = 'TST901') <> 6
        THROW 51903, N'Tồn sau nhập không đúng.', 1;

    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST901',
            @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST901","soLuong":6}]';
        THROW 51904, N'Phiếu nhập được hoàn tất hai lần.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51102 THROW;
    END CATCH;
    IF (SELECT COUNT(*) FROM dbo.LO_HANG WHERE MaPN = 'TST901') <> 1
        THROW 51905, N'Hoàn tất lặp tạo thêm lô.', 1;

    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST902',
            @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST901","soLuong":5}]';
        THROW 51906, N'Nhập vượt sức chứa được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51112 THROW;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaPN = 'TST902')
        THROW 51907, N'Phiếu vượt sức chứa vẫn tạo lô.', 1;

    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST903',
            @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST901","soLuong":1}]';
        THROW 51908, N'Nhà cung cấp thiếu mapping được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51106 THROW;
    END CATCH;

    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST904',
            @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST901","soLuong":1}]';
        THROW 51909, N'Phân bổ thiếu số lượng được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51108 THROW;
    END CATCH;

    BEGIN TRANSACTION;
    DELETE ton FROM dbo.TON_KHO ton JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo
        WHERE lo.MaPN IN ('TST901', 'TST902', 'TST903', 'TST904');
    DELETE FROM dbo.LO_HANG WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904');
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904');
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904');
    DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = 'TST901';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP = 'TST901';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'TST901';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = 'TST901';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri = 'TST901';
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = 'TST901';
    DELETE FROM dbo.KHO WHERE MaKho = 'TST901';
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC IN ('TST901', 'TST902');
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = 'TST901';
    COMMIT TRANSACTION;
    PRINT N'Inbound completion passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    BEGIN TRANSACTION;
    DELETE ton FROM dbo.TON_KHO ton JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo
        WHERE lo.MaPN IN ('TST901', 'TST902', 'TST903', 'TST904');
    DELETE FROM dbo.LO_HANG WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904');
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904');
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904');
    DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = 'TST901';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP = 'TST901';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'TST901';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = 'TST901';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri = 'TST901';
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = 'TST901';
    DELETE FROM dbo.KHO WHERE MaKho = 'TST901';
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC IN ('TST901', 'TST902');
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = 'TST901';
    COMMIT TRANSACTION;
    THROW;
END CATCH;
