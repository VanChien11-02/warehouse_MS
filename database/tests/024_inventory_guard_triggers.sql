SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @CleanupSql NVARCHAR(MAX) = N'
    DELETE FROM dbo.BIEN_DONG_TON_KHO WHERE MaChungTu = ''TST241'';
    DELETE FROM dbo.TON_KHO WHERE MaLo IN (''TST241'', ''TST242'', ''TST243'');
    DELETE FROM dbo.LO_HANG WHERE MaPN = ''TST241'';
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = ''TST241'';
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN = ''TST241'';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri IN (''TST241'', ''TST242'');
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = ''TST241'';
    DELETE FROM dbo.KHO WHERE MaKho = ''TST241'';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP IN (''TST241'', ''TST242'');
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = ''TST241'';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT IN (''TST241'', ''TST242'');
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = ''TST241'';
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = ''TST241'';
';

BEGIN TRY
    IF (SELECT COUNT(*) FROM sys.triggers WHERE parent_class = 1 AND is_disabled = 0
        AND name IN (N'trg_LoHang_GioiHanPhanBo', N'trg_CtPhieuNhap_GioiHanLo',
                     N'trg_TonKho_BaoVeViTri', N'trg_BienDongTonKho_DungChieu')) <> 4
        THROW 52200, N'Thiếu trigger bảo vệ dữ liệu kho.', 1;

    BEGIN TRANSACTION;
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST241', N'Nhân viên test trigger', '2026-01-01');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST241', N'Nhà cung cấp test trigger');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai)
        VALUES ('TST241', N'Loại test trigger');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST241', N'Đơn vị test TST241'),
               ('TST242', N'Đơn vị test TST242');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST241', N'Sản phẩm thùng', 'TST241', 'TST241'),
               ('TST242', N'Sản phẩm chai', 'TST241', 'TST242');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST241', N'Kho test trigger');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST241', 'TST241', N'Khu test trigger', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST241', 'TST241', N'Vị trí một', 8, N'Lưu trữ'),
               ('TST242', 'TST241', N'Vị trí hai', 8, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV)
        VALUES ('TST241', 'TST241', 'TST241');
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST241', 'TST241', 7, 1.0000),
               ('TST241', 'TST242', 3, 1.0000);
    COMMIT TRANSACTION;

    -- Hai lô hợp lệ riêng lẻ nhưng tổng 8 vượt dòng nhập 7.
    BEGIN TRY
        INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, SoLuongNhap)
            VALUES ('TST241', 'TST241', 'TST241', 4),
                   ('TST242', 'TST241', 'TST241', 4);
        THROW 52201, N'Trigger cho phép hai lô vượt dòng nhập.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51820 THROW;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaPN = 'TST241')
        THROW 52202, N'Insert lô nhiều dòng không rollback nguyên tử.', 1;

    INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, SoLuongNhap)
        VALUES ('TST241', 'TST241', 'TST241', 4),
               ('TST242', 'TST241', 'TST241', 3),
               ('TST243', 'TST241', 'TST242', 3);

    BEGIN TRY
        UPDATE dbo.CT_PHIEU_NHAP
        SET SoLuong = CASE WHEN MaSP = 'TST241' THEN 6 ELSE 4 END
        WHERE MaPN = 'TST241';
        THROW 52203, N'Giảm dòng nhập dưới số lô được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51821 THROW;
    END CATCH;
    IF (SELECT SoLuong FROM dbo.CT_PHIEU_NHAP
        WHERE MaPN = 'TST241' AND MaSP = 'TST241') <> 7
       OR (SELECT SoLuong FROM dbo.CT_PHIEU_NHAP
        WHERE MaPN = 'TST241' AND MaSP = 'TST242') <> 3
        THROW 52204, N'Cập nhật dòng nhập nhiều dòng không rollback nguyên tử.', 1;

    -- Hai dòng tồn cộng lại vượt sức chứa; cả hai phải bị từ chối.
    BEGIN TRY
        INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
            VALUES ('TST241', 'TST241', 5), ('TST241', 'TST242', 4);
        THROW 52205, N'Vị trí nhận tồn vượt sức chứa.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51822 THROW;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.TON_KHO WHERE MaViTri = 'TST241')
        THROW 52206, N'Insert tồn nhiều dòng không rollback nguyên tử.', 1;

    INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
        VALUES ('TST241', 'TST241', 4), ('TST241', 'TST242', 3);
    BEGIN TRY
        INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
            VALUES ('TST241', 'TST243', 1);
        THROW 52207, N'Vị trí được trộn hai đơn vị tính.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51823 THROW;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.TON_KHO WHERE MaViTri = 'TST241' AND MaLo = 'TST243')
        THROW 52208, N'Tồn sai đơn vị tính không được rollback.', 1;
    INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
        VALUES ('TST242', 'TST243', 3);

    BEGIN TRY
        INSERT INTO dbo.BIEN_DONG_TON_KHO
            (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
        VALUES (N'NHAP', 'TST241', 'TST241', 'TST241', 4, SYSUTCDATETIME()),
               (N'XUAT', 'TST241', 'TST241', 'TST242', 1, SYSUTCDATETIME());
        THROW 52209, N'Sổ xuất nhận biến động tăng.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51824 THROW;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.BIEN_DONG_TON_KHO WHERE MaChungTu = 'TST241')
        THROW 52210, N'Ghi sổ nhiều dòng không rollback nguyên tử.', 1;
    INSERT INTO dbo.BIEN_DONG_TON_KHO
        (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
    VALUES (N'NHAP', 'TST241', 'TST241', 'TST241', 4, SYSUTCDATETIME()),
           (N'XUAT', 'TST241', 'TST241', 'TST242', -1, SYSUTCDATETIME());

    EXEC sp_executesql @CleanupSql;
    PRINT N'Inventory guard triggers passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    EXEC sp_executesql @CleanupSql;
    THROW;
END CATCH;
