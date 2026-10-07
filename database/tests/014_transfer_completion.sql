SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @CleanupSql NVARCHAR(MAX) = N'
    DELETE FROM dbo.LICH_SU_THAO_TAC WHERE MaTK = ''TST141'';
    DELETE FROM dbo.BIEN_DONG_TON_KHO WHERE MaChungTu IN (''TST141'', ''TST142'', ''TST143'', ''TST144'', ''TST145'');
    DELETE FROM dbo.CT_PHIEU_CHUYEN_KHO WHERE MaPCK IN (''TST141'', ''TST142'', ''TST143'', ''TST144'', ''TST145'');
    DELETE FROM dbo.PHIEU_CHUYEN_KHO WHERE MaPCK IN (''TST141'', ''TST142'', ''TST143'', ''TST144'', ''TST145'');
    DELETE ton FROM dbo.TON_KHO ton JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo
        WHERE lo.MaPN = ''TST141'';
    DELETE FROM dbo.LO_HANG WHERE MaPN = ''TST141'';
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = ''TST141'';
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN = ''TST141'';
    DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = ''TST141'';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP = ''TST141'';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = ''TST141'';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = ''TST141'';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri IN (''TST141'', ''TST142'', ''TST143'');
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc IN (''TST141'', ''TST142'', ''TST143'');
    DELETE FROM dbo.KHO WHERE MaKho IN (''TST141'', ''TST142'');
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = ''TST141'';
    DELETE FROM dbo.TAI_KHOAN WHERE MaTK = ''TST141'';
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = ''TST141'';
';

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST141', N'Nhân viên test chuyển', '2026-01-01');
    INSERT INTO dbo.TAI_KHOAN (MaTK, MaNV, MaRole, TenTK, MatKhauHash)
        VALUES ('TST141', 'TST141', 'QLKHO', N'test.transfer.audit',
            '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST141', N'Nhà cung cấp test chuyển');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
        VALUES ('TST141', N'Loại test chuyển', N'Khô');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST141', N'Đơn vị test chuyển');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST141', N'Sản phẩm test chuyển', 'TST141', 'TST141');
    INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP)
        VALUES ('TST141', 'TST141');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST141', N'Kho nguồn test chuyển'),
               ('TST142', N'Kho đích test chuyển');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST141', 'TST141', N'Khu nguồn', N'Khô'),
               ('TST142', 'TST142', N'Khu đích', N'Khô'),
               ('TST143', 'TST142', N'Khu mát', N'Mát');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST141', 'TST141', N'Vị trí nguồn', 6, N'Lưu trữ'),
               ('TST142', 'TST142', N'Vị trí đích', 4, N'Lưu trữ'),
               ('TST143', 'TST143', N'Vị trí sai loại', 10, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV)
        VALUES ('TST141', 'TST141', 'TST141');
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST141', 'TST141', 6, 7.2500);
    COMMIT TRANSACTION;

    EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST141',
        @PhanBoJson = N'[{"maSanPham":"TST141","maViTri":"TST141","soLuong":6}]';
    DECLARE @MaLo CHAR(6) = (SELECT MaLo FROM dbo.LO_HANG WHERE MaPN = 'TST141');
    IF @MaLo IS NULL THROW 51970, N'Không tạo được lô nguồn.', 1;

    INSERT INTO dbo.PHIEU_CHUYEN_KHO (MaPCK, MaNV)
        VALUES ('TST141', 'TST141'), ('TST142', 'TST141'),
               ('TST143', 'TST141'), ('TST144', 'TST141');
    INSERT INTO dbo.CT_PHIEU_CHUYEN_KHO
        (MaPCK, MaLo, MaViTriNguon, MaViTriDich, SoLuong)
        VALUES ('TST141', @MaLo, 'TST141', 'TST142', 3),
               ('TST142', @MaLo, 'TST141', 'TST142', 4),
               ('TST143', @MaLo, 'TST141', 'TST142', 2),
               ('TST144', @MaLo, 'TST141', 'TST143', 1);

    EXEC dbo.sp_HoanTatChuyenKho @MaPCK = 'TST141', @MaTK = 'TST141';
    IF (SELECT SoLuongTon FROM dbo.TON_KHO
        WHERE MaViTri = 'TST141' AND MaLo = @MaLo) <> 3
        THROW 51971, N'Tồn nguồn sau chuyển sai.', 1;
    IF (SELECT SoLuongTon FROM dbo.TON_KHO
        WHERE MaViTri = 'TST142' AND MaLo = @MaLo) <> 3
        THROW 51972, N'Tồn đích sau chuyển sai.', 1;
    IF (SELECT SUM(SoLuongThayDoi) FROM dbo.BIEN_DONG_TON_KHO
        WHERE LoaiNghiepVu = N'CHUYEN' AND MaChungTu = 'TST141') <> 0
        THROW 51973, N'Chuyển kho chưa ghi hai phía cân bằng.', 1;
    IF (SELECT COUNT(*) FROM dbo.LICH_SU_THAO_TAC
        WHERE MaTK = 'TST141' AND TenBang = N'PHIEU_CHUYEN_KHO'
          AND MaBanGhi = 'TST141' AND HanhDong = N'COMPLETE') <> 1
        THROW 52042, N'Hoàn tất chuyển chưa ghi actor audit.', 1;
    IF (SELECT SUM(SoLuongThayDoi) FROM dbo.vw_BienDongTonKhoChiTiet
        WHERE MaKho = 'TST141' AND MaSP = 'TST141') <> 3
        THROW 51974, N'Báo cáo kho nguồn sau chuyển sai.', 1;
    IF (SELECT SUM(SoLuongThayDoi) FROM dbo.vw_BienDongTonKhoChiTiet
        WHERE MaKho = 'TST142' AND MaSP = 'TST141') <> 3
        THROW 51975, N'Báo cáo kho đích sau chuyển sai.', 1;

    BEGIN TRY
        EXEC dbo.sp_HoanTatChuyenKho @MaPCK = 'TST141';
        THROW 51976, N'Phiếu chuyển được hoàn tất hai lần.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51302 THROW;
    END CATCH;
    BEGIN TRY
        EXEC dbo.sp_HoanTatChuyenKho @MaPCK = 'TST142';
        THROW 51977, N'Chuyển vượt tồn nguồn được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51306 THROW;
    END CATCH;
    BEGIN TRY
        EXEC dbo.sp_HoanTatChuyenKho @MaPCK = 'TST143';
        THROW 51978, N'Chuyển vượt sức chứa đích được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51307 THROW;
    END CATCH;
    BEGIN TRY
        EXEC dbo.sp_HoanTatChuyenKho @MaPCK = 'TST144';
        THROW 51979, N'Chuyển vào khu sai bảo quản được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51305 THROW;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.BIEN_DONG_TON_KHO
        WHERE LoaiNghiepVu = N'CHUYEN' AND MaChungTu IN ('TST142', 'TST143', 'TST144'))
        THROW 51980, N'Phiếu chuyển thất bại đã ghi biến động.', 1;
    IF (SELECT SoLuongTon FROM dbo.TON_KHO
        WHERE MaViTri = 'TST141' AND MaLo = @MaLo) <> 3
        THROW 51981, N'Phiếu chuyển thất bại đã thay đổi tồn.', 1;

    INSERT INTO dbo.PHIEU_CHUYEN_KHO (MaPCK, MaNV)
        VALUES ('TST145', 'TST141');
    INSERT INTO dbo.CT_PHIEU_CHUYEN_KHO
        (MaPCK, MaLo, MaViTriNguon, MaViTriDich, SoLuong)
        VALUES ('TST145', @MaLo, 'TST141', 'TST142', 1);
    INSERT INTO dbo.BIEN_DONG_TON_KHO
        (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
        VALUES (N'CHUYEN', 'TST145', 'TST141', @MaLo, -1, SYSUTCDATETIME());
    BEGIN TRY
        EXEC dbo.sp_HoanTatChuyenKho @MaPCK = 'TST145';
        THROW 51982, N'Lỗi ghi sổ cuối transaction không rollback tồn.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;
    IF (SELECT SoLuongTon FROM dbo.TON_KHO
        WHERE MaViTri = 'TST141' AND MaLo = @MaLo) <> 3
        OR (SELECT SoLuongTon FROM dbo.TON_KHO
        WHERE MaViTri = 'TST142' AND MaLo = @MaLo) <> 3
        THROW 51983, N'Lỗi ghi sổ cuối transaction để tồn dở dang.', 1;
    IF (SELECT TrangThai FROM dbo.PHIEU_CHUYEN_KHO WHERE MaPCK = 'TST145') <> N'NHAP'
        THROW 51984, N'Lỗi ghi sổ cuối transaction vẫn hoàn tất phiếu.', 1;

    EXEC sp_executesql @CleanupSql;
    PRINT N'Transfer completion passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    EXEC sp_executesql @CleanupSql;
    THROW;
END CATCH;
