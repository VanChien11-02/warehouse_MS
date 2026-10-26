-- DEMO HÀNH VI THẬT, không tạo lại object và không tra sys.*.
-- Chạy 00_tv1_chuan_bi_demo.sql trước, sau đó bôi đen từng mục theo thứ tự.
-- CATCH chỉ giúp hiện mã lỗi/nguồn lỗi và tiếp tục demo, không sinh lỗi thay trigger.

-- 1. INDEX: bật Ctrl+M (Actual Execution Plan), bôi đen SELECT rồi F5.
-- Object: IX_PHIEU_NHAP_NGAY_MA; Ordered=True; thường không cần Sort.
SELECT NgayNhap, MaPN, MaNCC, TrangThai
FROM dbo.PHIEU_NHAP
ORDER BY NgayNhap DESC, MaPN DESC;
GO

-- 2. TRIGGER LÔ: dòng nhập 10, thêm cùng lúc 6+5. Phải lỗi 51820.
-- Muốn hiện lỗi đỏ nguyên bản, chỉ bôi đen câu INSERT và F5.
BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM dbo.CT_PHIEU_NHAP WHERE MaPN = 'HS0001' AND MaSP = 'HS0001')
        THROW 52903, N'Chưa có dòng nhập demo. Chạy toàn file 00_tv1_chuan_bi_demo.sql trước.', 1;
    INSERT dbo.LO_HANG (MaLo, MaPN, MaSP, SoLuongNhap)
    VALUES ('HS0001', 'HS0001', 'HS0001', 6),
           ('HS0002', 'HS0001', 'HS0001', 5);
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51820 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_PROCEDURE() AS NoiBaoLoi, ERROR_MESSAGE() AS ThongBao;
END CATCH;
SELECT * FROM dbo.LO_HANG WHERE MaPN = 'HS0001'; -- 0 dòng
GO

-- 3A. PROCEDURE: kệ HS0002 chứa tối đa 5, nhập 10 phải lỗi 51112 từ procedure.
-- Cần phân bổ đúng tổng 10 để không bị lỗi thiếu lượng trước khi kiểm tra sức chứa.
SELECT MaViTri, SucChua FROM dbo.VI_TRI_KHO WHERE MaViTri = 'HS0002';
BEGIN TRY
    EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'HS0001', @PhanBoJson = N'[
      {"maSanPham":"HS0001","maViTri":"HS0002","soLuong":10}]';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51112 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_PROCEDURE() AS NoiBaoLoi, ERROR_MESSAGE() AS ThongBao;
END CATCH;
SELECT TrangThai, NgayHoanTat FROM dbo.PHIEU_NHAP WHERE MaPN = 'HS0001'; -- NHAP
SELECT * FROM dbo.LO_HANG WHERE MaPN = 'HS0001'; -- 0 dòng
SELECT * FROM dbo.TON_KHO WHERE MaViTri = 'HS0002'; -- 0 dòng
GO

-- 3B. TRANSACTION ROLLBACK: 6 đã tạo lô/tồn/sổ, đến lô 5 bị trigger chặn.
-- Phải lỗi 51820 từ trigger, phiếu NHAP, không còn lô/tồn/sổ của phần 6.
BEGIN TRY
    EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'HS0001', @PhanBoJson = N'[
      {"maSanPham":"HS0001","maViTri":"HS0001","soLuong":6},
      {"maSanPham":"HS0001","maViTri":"HS0001","soLuong":5}]';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51820 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_PROCEDURE() AS NoiBaoLoi, ERROR_MESSAGE() AS ThongBao;
END CATCH;

SELECT TrangThai, NgayHoanTat FROM dbo.PHIEU_NHAP WHERE MaPN = 'HS0001';
SELECT * FROM dbo.LO_HANG WHERE MaPN = 'HS0001';
SELECT * FROM dbo.TON_KHO WHERE MaViTri IN ('HS0001', 'HS0002');
SELECT * FROM dbo.BIEN_DONG_TON_KHO WHERE LoaiNghiepVu = N'NHAP' AND MaChungTu = 'HS0001';
GO

-- 4. VIEW TRƯỚC COMMIT: chưa có phiếu hoàn tất nên 0 dòng.
SELECT * FROM dbo.vw_LichSuNhapKho WHERE MaPN = 'HS0001';
GO

-- 5. PROCEDURE + COMMIT: sửa 5 thành 4. Phiếu hoàn tất, hai lô, tổng tồn 10.
EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'HS0001', @PhanBoJson = N'[
  {"maSanPham":"HS0001","maViTri":"HS0001","soLuong":6},
  {"maSanPham":"HS0001","maViTri":"HS0001","soLuong":4}]';

SELECT TrangThai, NgayHoanTat FROM dbo.PHIEU_NHAP WHERE MaPN = 'HS0001';
SELECT * FROM dbo.LO_HANG WHERE MaPN = 'HS0001';
SELECT * FROM dbo.TON_KHO WHERE MaViTri = 'HS0001';
SELECT * FROM dbo.BIEN_DONG_TON_KHO WHERE LoaiNghiepVu = N'NHAP' AND MaChungTu = 'HS0001';
GO

-- 6. VIEW SAU COMMIT: 2 dòng, lượng 6/4, giá trị 75000/50000.
SELECT MaPN, MaSP, MaLo, SoLuongNhap, DonGiaNhap, GiaTriNhap
FROM dbo.vw_LichSuNhapKho WHERE MaPN = 'HS0001' ORDER BY MaLo;
GO

-- 7. FUNCTION: mã lô do procedure cấp, không đoán trước LOxxxx.
SELECT MaLo, dbo.fn_TonTheoLo(MaLo) AS TonTheoLo
FROM dbo.LO_HANG WHERE MaPN = 'HS0001' ORDER BY MaLo; -- 6 và 4
GO

-- 8. TRIGGER BẢO QUẢN: loại đã có lô, đổi Khô -> Mát phải lỗi 51825.
BEGIN TRY
    UPDATE dbo.LOAI_SAN_PHAM SET YeuCauBaoQuan = N'Mát' WHERE MaLoai = 'HS0001';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51825 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_PROCEDURE() AS NoiBaoLoi, ERROR_MESSAGE() AS ThongBao;
END CATCH;
SELECT MaLoai, YeuCauBaoQuan FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'HS0001'; -- vẫn Khô
GO

-- 9. CHỐNG GHI SỔ LẶP: gọi hoàn tất lại phải lỗi 51102; tồn vẫn 6+4.
BEGIN TRY
    EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'HS0001', @PhanBoJson = N'[
      {"maSanPham":"HS0001","maViTri":"HS0001","soLuong":10}]';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51102 THROW;
    SELECT ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ThongBao;
END CATCH;
SELECT MaLo, SoLuongTon FROM dbo.TON_KHO WHERE MaViTri = 'HS0001';
GO
