SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @CleanupSql NVARCHAR(MAX) = N'
    DELETE FROM dbo.TON_KHO WHERE MaViTri IN (''TST211'', ''TST212'');
    DELETE FROM dbo.LO_HANG WHERE MaPN = ''TST211'';
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = ''TST211'';
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN = ''TST211'';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri IN (''TST211'', ''TST212'');
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc IN (''TST211'', ''TST212'');
    DELETE FROM dbo.KHO WHERE MaKho = ''TST211'';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP = ''TST211'';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = ''TST211'';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = ''TST211'';
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = ''TST211'';
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = ''TST211'';
';

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST211', N'Nhân viên test vị trí', '2026-01-01');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST211', N'Nhà cung cấp test vị trí');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai)
        VALUES ('TST211', N'Loại test vị trí');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST211', N'Đơn vị test vị trí');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST211', N'Sản phẩm test vị trí', 'TST211', 'TST211');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST211', N'Kho test vị trí');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST211', 'TST211', N'Khu một', N'Khô'),
               ('TST212', 'TST211', N'Khu hai', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST211', 'TST211', N'Vị trí có tồn', 5, N'Lưu trữ'),
               ('TST212', 'TST211', N'Vị trí trống', 5, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, TrangThai, NgayHoanTat)
        VALUES ('TST211', 'TST211', 'TST211', N'DA_HOAN_THANH', SYSUTCDATETIME());
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST211', 'TST211', 3, 1.0000);
    INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, SoLuongNhap)
        VALUES ('TST211', 'TST211', 'TST211', 3);
    INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
        VALUES ('TST211', 'TST211', 3);
    COMMIT TRANSACTION;

    BEGIN TRY
        UPDATE dbo.VI_TRI_KHO SET SucChua = 1
        WHERE MaViTri IN ('TST211', 'TST212');
        THROW 52102, N'Giảm sức chứa nhiều dòng được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 52101 THROW;
    END CATCH;
    IF (SELECT COUNT(*) FROM dbo.VI_TRI_KHO
        WHERE MaViTri IN ('TST211', 'TST212') AND SucChua = 5) <> 2
        THROW 52103, N'Update nhiều dòng không rollback nguyên tử.', 1;

    BEGIN TRY
        UPDATE dbo.VI_TRI_KHO
        SET MaKhuVuc = 'TST212', LoaiViTri = N'Hư hỏng'
        WHERE MaViTri = 'TST211';
        THROW 52104, N'Vị trí có tồn được chuyển khu/loại.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 52101 THROW;
    END CATCH;
    IF (SELECT MaKhuVuc FROM dbo.VI_TRI_KHO WHERE MaViTri = 'TST211') <> 'TST211'
        THROW 52105, N'Vị trí có tồn bị đổi khu.', 1;

    UPDATE dbo.VI_TRI_KHO SET TenViTri = CONCAT(TenViTri, N' mới')
    WHERE MaViTri IN ('TST211', 'TST212');
    IF (SELECT COUNT(*) FROM dbo.VI_TRI_KHO
        WHERE MaViTri IN ('TST211', 'TST212') AND TenViTri LIKE N'%mới') <> 2
        THROW 52106, N'Trigger cản cập nhật tên hợp lệ.', 1;

    EXEC sp_executesql @CleanupSql;
    PRINT N'Position stock guard passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    EXEC sp_executesql @CleanupSql;
    THROW;
END CATCH;
