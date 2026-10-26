:ON ERROR EXIT
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST261', N'Nhân viên test phân bổ nháp', '2026-01-01');
    INSERT dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST261', N'Nhà cung cấp test phân bổ nháp');
    INSERT dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, PhanBoNhapJson)
        VALUES ('TST261', 'TST261', 'TST261',
            N'[{"maSanPham":"SP0001","maViTri":"VT0001","soLuong":"6"},
                {"maSanPham":"SP0001","maViTri":"VT0002","soLuong":"4"}]');
    IF (SELECT COUNT(*) FROM OPENJSON((SELECT PhanBoNhapJson FROM dbo.PHIEU_NHAP
        WHERE MaPN = 'TST261'))) <> 2
        THROW 51961, N'Phân bổ nháp không giữ đủ hai dòng.', 1;
    IF EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaPN = 'TST261')
        OR EXISTS (SELECT 1 FROM dbo.BIEN_DONG_TON_KHO WHERE MaChungTu = 'TST261')
        THROW 51962, N'Lưu phân bổ nháp không được ghi sổ.', 1;
    ROLLBACK TRANSACTION;
    PRINT N'Inbound draft allocations passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
