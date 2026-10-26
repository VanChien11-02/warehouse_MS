-- CHỈ DỌN fixture của 00_tv1_chuan_bi_demo.sql sau khi học xong.
-- Đây không phải chức năng xóa chứng từ hoàn tất của ứng dụng.
-- Kiểm tra marker và các quan hệ sở hữu trước khi xóa đúng bộ dữ liệu học.
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRAN;
    IF NOT EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP WITH (UPDLOCK, HOLDLOCK)
                   WHERE MaPN = 'HS0001' AND GhiChu = N'DEMO_SSMS_TV1_20261025'
                     AND MaNCC = 'HS0001' AND MaNV = 'HS0001')
        THROW 52900, N'Không tìm thấy đúng phiếu demo; không xóa dữ liệu.', 1;
    IF EXISTS (SELECT 1 FROM dbo.CT_PHIEU_NHAP WHERE MaPN = 'HS0001' AND MaSP <> 'HS0001')
        OR EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaSP = 'HS0001' AND MaPN <> 'HS0001')
        OR EXISTS (SELECT 1 FROM dbo.TON_KHO ton JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo
                   WHERE ton.MaViTri IN ('HS0001', 'HS0002') AND lo.MaPN <> 'HS0001')
        THROW 52901, N'Dữ liệu học đã có liên kết ngoài fixture; không xóa.', 1;

    DELETE FROM dbo.BIEN_DONG_TON_KHO WHERE LoaiNghiepVu = N'NHAP' AND MaChungTu = 'HS0001';
    DELETE ton FROM dbo.TON_KHO ton JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo WHERE lo.MaPN = 'HS0001';
    DELETE FROM dbo.LO_HANG WHERE MaPN = 'HS0001';
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = 'HS0001';
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN = 'HS0001';
    DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = 'HS0001' AND MaSP = 'HS0001';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP = 'HS0001';
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = 'HS0001';
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = 'HS0001';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'HS0001';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = 'HS0001';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri IN ('HS0001', 'HS0002');
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = 'HS0001';
    DELETE FROM dbo.KHO WHERE MaKho = 'HS0001';
    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    THROW;
END CATCH;
