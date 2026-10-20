SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @CleanupSql NVARCHAR(MAX) = N'
    DELETE FROM dbo.BIEN_DONG_TON_KHO
        WHERE LoaiNghiepVu = N''XUAT'' AND MaChungTu IN (''CNC001'', ''CNC002'');
    DELETE FROM dbo.CT_PHIEU_XUAT WHERE MaPX IN (''CNC001'', ''CNC002'');
    DELETE FROM dbo.PHIEU_XUAT WHERE MaPX IN (''CNC001'', ''CNC002'');
    DELETE FROM dbo.TON_KHO WHERE MaViTri = ''CNC001'' AND MaLo = ''CNC001'';
    DELETE FROM dbo.LO_HANG WHERE MaLo = ''CNC001'';
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = ''CNC001'';
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN = ''CNC001'';
    DELETE FROM dbo.DOI_TAC_SAN_PHAM WHERE MaDTNH = ''CNC001'';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri = ''CNC001'';
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = ''CNC001'';
    DELETE FROM dbo.KHO WHERE MaKho = ''CNC001'';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP = ''CNC001'';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = ''CNC001'';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = ''CNC001'';
    DELETE FROM dbo.DOI_TAC_NHAN_HANG WHERE MaDTNH = ''CNC001'';
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = ''CNC001'';
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = ''CNC001'';
';

BEGIN TRY
    IF (SELECT COUNT(*) FROM dbo.PHIEU_XUAT
        WHERE MaPX IN ('CNC001', 'CNC002') AND TrangThai = N'DA_HOAN_THANH') <> 1
        THROW 52131, N'Hai phiên phải chốt đúng một phiếu.', 1;
    IF (SELECT COUNT(*) FROM dbo.PHIEU_XUAT
        WHERE MaPX IN ('CNC001', 'CNC002') AND TrangThai = N'NHAP') <> 1
        THROW 52132, N'Phiếu thất bại phải còn nháp.', 1;
    IF (SELECT SoLuongTon FROM dbo.TON_KHO
        WHERE MaViTri = 'CNC001' AND MaLo = 'CNC001') <> 2
        THROW 52133, N'Tồn sau hai phiên không bằng 2.', 1;
    IF (SELECT COUNT(*) FROM dbo.BIEN_DONG_TON_KHO
        WHERE LoaiNghiepVu = N'XUAT' AND MaChungTu IN ('CNC001', 'CNC002')) <> 1
        THROW 52134, N'Sổ xuất không đúng một biến động.', 1;
    IF (SELECT SUM(SoLuongThayDoi) FROM dbo.BIEN_DONG_TON_KHO
        WHERE LoaiNghiepVu = N'XUAT' AND MaChungTu IN ('CNC001', 'CNC002')) <> -4
        THROW 52135, N'Biến động tồn sau hai phiên sai.', 1;

    EXEC sp_executesql @CleanupSql;
    PRINT N'Concurrent outbound posting passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    EXEC sp_executesql @CleanupSql;
    THROW;
END CATCH;
