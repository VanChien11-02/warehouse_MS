SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @CleanupSql NVARCHAR(MAX) = N'
    DELETE FROM dbo.BIEN_DONG_TON_KHO WHERE MaChungTu IN (''TST161'', ''TST162'', ''TST163'', ''TST164'', ''TST165'');
    DELETE FROM dbo.CT_KIEM_KE WHERE MaPKK IN (''TST161'', ''TST162'', ''TST163'', ''TST164'');
    DELETE FROM dbo.PHIEU_KIEM_KE WHERE MaPKK IN (''TST161'', ''TST162'', ''TST163'', ''TST164'');
    DELETE ton FROM dbo.TON_KHO ton JOIN dbo.LO_HANG lot ON lot.MaLo = ton.MaLo WHERE lot.MaPN = ''TST161'';
    DELETE FROM dbo.LO_HANG WHERE MaPN = ''TST161'';
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = ''TST161'';
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN = ''TST161'';
    DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = ''TST161'';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP = ''TST161'';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = ''TST161'';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = ''TST161'';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri = ''TST161'';
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = ''TST161'';
    DELETE FROM dbo.KHO WHERE MaKho = ''TST161'';
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = ''TST161'';
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = ''TST161'';
';

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST161', N'Nhân viên kiểm kê', '2026-01-01');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST161', N'Nhà cung cấp kiểm kê');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
        VALUES ('TST161', N'Loại kiểm kê', N'Khô');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST161', N'Đơn vị kiểm kê');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST161', N'Sản phẩm kiểm kê', 'TST161', 'TST161');
    INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP)
        VALUES ('TST161', 'TST161');
    INSERT INTO dbo.KHO (MaKho, TenKho) VALUES ('TST161', N'Kho kiểm kê');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST161', 'TST161', N'Khu kiểm kê', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST161', 'TST161', N'Vị trí kiểm kê', 8, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV)
        VALUES ('TST161', 'TST161', 'TST161');
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST161', 'TST161', 6, 7.2500);
    COMMIT TRANSACTION;

    EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST161',
        @PhanBoJson = N'[{"maSanPham":"TST161","maViTri":"TST161","soLuong":6}]';
    DECLARE @MaLo CHAR(6) = (SELECT MaLo FROM dbo.LO_HANG WHERE MaPN = 'TST161');
    IF @MaLo IS NULL THROW 51993, N'Không tạo được lô kiểm kê.', 1;

    INSERT INTO dbo.PHIEU_KIEM_KE (MaPKK, MaNV, MaViTri)
        VALUES ('TST161', 'TST161', 'TST161'),
               ('TST162', 'TST161', 'TST161'),
               ('TST163', 'TST161', 'TST161');
    INSERT INTO dbo.CT_KIEM_KE (MaPKK, MaLo, SoLuongHeThong, SoLuongThucTe, LyDoChenhLech)
        VALUES ('TST161', @MaLo, 6, 4, NULL),
               ('TST162', @MaLo, 6, 9, N'Kiểm tra sức chứa'),
               ('TST163', @MaLo, 6, 4, N'Hao hụt');

    BEGIN TRY
        EXEC dbo.sp_HoanTatKiemKe @MaPKK = 'TST161';
        THROW 51994, N'Thiếu lý do vẫn hoàn tất kiểm kê.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51405 THROW;
    END CATCH;
    BEGIN TRY
        EXEC dbo.sp_HoanTatKiemKe @MaPKK = 'TST162';
        THROW 51995, N'Vượt sức chứa vẫn hoàn tất kiểm kê.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51407 THROW;
    END CATCH;
    UPDATE dbo.CT_KIEM_KE SET LyDoChenhLech = N'Hao hụt' WHERE MaPKK = 'TST161';
    UPDATE dbo.TON_KHO SET SoLuongTon = 5 WHERE MaViTri = 'TST161' AND MaLo = @MaLo;
    BEGIN TRY
        EXEC dbo.sp_HoanTatKiemKe @MaPKK = 'TST161';
        THROW 51996, N'Snapshot cũ vẫn được ghi sổ.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51406 THROW;
    END CATCH;
    UPDATE dbo.TON_KHO SET SoLuongTon = 6 WHERE MaViTri = 'TST161' AND MaLo = @MaLo;

    EXEC dbo.sp_HoanTatKiemKe @MaPKK = 'TST163';
    IF (SELECT SoLuongTon FROM dbo.TON_KHO WHERE MaViTri = 'TST161' AND MaLo = @MaLo) <> 4
        THROW 51997, N'Điều chỉnh tồn sai.', 1;
    IF (SELECT SoLuongThayDoi FROM dbo.BIEN_DONG_TON_KHO
        WHERE LoaiNghiepVu = N'KIEM_KE' AND MaChungTu = 'TST163') <> -2
        THROW 51998, N'Biến động kiểm kê sai.', 1;
    IF (SELECT ChenhLech FROM dbo.vw_ChenhLechKiemKe
        WHERE MaPKK = 'TST163' AND MaLo = @MaLo) <> -2
        THROW 52002, N'Báo cáo chênh lệch kiểm kê sai.', 1;
    BEGIN TRY
        EXEC dbo.sp_HoanTatKiemKe @MaPKK = 'TST163';
        THROW 51999, N'Phiếu kiểm kê được ghi hai lần.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51402 THROW;
    END CATCH;

    INSERT INTO dbo.PHIEU_KIEM_KE (MaPKK, MaNV, MaViTri)
        VALUES ('TST164', 'TST161', 'TST161');
    INSERT INTO dbo.CT_KIEM_KE (MaPKK, MaLo, SoLuongHeThong, SoLuongThucTe, LyDoChenhLech)
        VALUES ('TST164', @MaLo, 4, 3, N'Hao hụt');
    INSERT INTO dbo.BIEN_DONG_TON_KHO
        (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
        VALUES (N'KIEM_KE', 'TST164', 'TST161', @MaLo, -1, SYSUTCDATETIME());
    BEGIN TRY
        EXEC dbo.sp_HoanTatKiemKe @MaPKK = 'TST164';
        THROW 52000, N'Lỗi ghi sổ không rollback tồn.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;
    IF (SELECT SoLuongTon FROM dbo.TON_KHO WHERE MaViTri = 'TST161' AND MaLo = @MaLo) <> 4
        OR (SELECT TrangThai FROM dbo.PHIEU_KIEM_KE WHERE MaPKK = 'TST164') <> N'NHAP'
        THROW 52001, N'Lỗi ghi sổ để lại thay đổi dở dang.', 1;

    EXEC sp_executesql @CleanupSql;
    PRINT N'Inventory count completion passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    EXEC sp_executesql @CleanupSql;
    THROW;
END CATCH;
