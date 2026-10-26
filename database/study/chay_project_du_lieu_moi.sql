-- Dựa trên Query/chay_project.sql; chạy cả file trong SSMS trên đúng server BlueStock.
-- Chọn Include Actual Execution Plan (Ctrl+M) để xem index ở mục 1.
-- Fixture QT9001/QT9002 chỉ phục vụ test và được dọn sau khi chạy.
USE [BlueStock];
GO
SET NOCOUNT ON;
SET XACT_ABORT OFF;

BEGIN TRY
    -- 0. Tạo một phiếu nháp 10 hộp, kệ thường chứa 100 và kệ nhỏ chứa 5.
    -- Dùng NV0001 vì mã này có trong cả BlueStock Docker và SQL Server local.
    IF NOT EXISTS (SELECT 1 FROM dbo.NHAN_VIEN WHERE MaNV = 'NV0001')
        THROW 52901, N'Thiếu NV0001; hãy kiểm tra đúng server/database.', 1;
    IF EXISTS (SELECT 1 FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'QT9001')
        OR EXISTS (SELECT 1 FROM dbo.DON_VI_TINH WHERE MaDVT = 'QT9001')
        OR EXISTS (SELECT 1 FROM dbo.SAN_PHAM WHERE MaSP = 'QT9001')
        OR EXISTS (SELECT 1 FROM dbo.NHA_CUNG_CAP WHERE MaNCC = 'QT9001')
        OR EXISTS (SELECT 1 FROM dbo.KHO WHERE MaKho = 'QT9001')
        OR EXISTS (SELECT 1 FROM dbo.KHU_VUC WHERE MaKhuVuc = 'QT9001')
        OR EXISTS (SELECT 1 FROM dbo.VI_TRI_KHO WHERE MaViTri IN ('QT9001', 'QT9002'))
        OR EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP WHERE MaPN = 'QT9001')
        OR EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaLo IN ('QT9001', 'QT9002'))
        THROW 52902, N'Mã QT9001/QT9002 đã có; dừng để không đụng dữ liệu sẵn có.', 1;

    BEGIN TRANSACTION;
    INSERT dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('QT9001', N'Nhà cung cấp test chay_project');
    INSERT dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
        VALUES ('QT9001', N'Loại test chay_project', N'Khô');
    INSERT dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('QT9001', N'Hộp test chay_project');
    INSERT dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('QT9001', N'Sản phẩm test chay_project', 'QT9001', 'QT9001');
    INSERT dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP)
        VALUES ('QT9001', 'QT9001');
    INSERT dbo.KHO (MaKho, TenKho)
        VALUES ('QT9001', N'Kho test chay_project');
    INSERT dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('QT9001', 'QT9001', N'Khu khô test chay_project', N'Khô');
    INSERT dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('QT9001', 'QT9001', N'Kệ thường test', 100, N'Lưu trữ'),
               ('QT9002', 'QT9001', N'Kệ nhỏ test', 5, N'Lưu trữ');
    INSERT dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, GhiChu)
        VALUES ('QT9001', 'QT9001', 'NV0001', N'TEST_CHAY_PROJECT_QT9001');
    INSERT dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('QT9001', 'QT9001', 10, 12500);
    COMMIT TRANSACTION;

    -- 1. INDEX: xem Actual Execution Plan; hint bảo đảm dùng đúng index cần học.
    -- Trên 6 phiếu thật, optimizer có thể chọn scan nếu bỏ hint; đó không phải lỗi.
    SELECT MaPN, MaNCC, NgayNhap, TrangThai
    FROM dbo.PHIEU_NHAP WITH (INDEX(IX_PHIEU_NHAP_NGAY_MA))
    ORDER BY NgayNhap DESC, MaPN DESC;

    -- 2. TRIGGER trg_LoHang_GioiHanPhanBo: 6+5 > dòng nhập 10.
    -- Cặp (MaPN, MaSP) đã có nên phải gặp lỗi trigger 51820, không phải FK 547.
    SELECT MaPN, MaSP, SoLuong FROM dbo.CT_PHIEU_NHAP WHERE MaPN = 'QT9001';
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT dbo.LO_HANG (MaLo, MaPN, MaSP, SoLuongNhap)
            VALUES ('QT9001', 'QT9001', 'QT9001', 6),
                   ('QT9002', 'QT9001', 'QT9001', 5);
        ROLLBACK TRANSACTION;
        THROW 52903, N'Trigger lô không chặn tổng 11 > 10.', 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() <> 51820 THROW;
        SELECT ERROR_NUMBER() AS MaLoiTriggerLo, ERROR_PROCEDURE() AS NoiBaoLoi;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaPN = 'QT9001')
        THROW 52904, N'INSERT lỗi nhưng vẫn còn lô test.', 1;

    -- 3. PROCEDURE: kệ QT9002 chỉ chứa 5, nên nhập 10 phải lỗi 51112.
    SELECT MaViTri, SucChua FROM dbo.VI_TRI_KHO WHERE MaViTri = 'QT9002';
    BEGIN TRY
        BEGIN TRANSACTION;
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'QT9001',
            @PhanBoJson = N'[{"maSanPham":"QT9001","maViTri":"QT9002","soLuong":10}]';
        ROLLBACK TRANSACTION;
        THROW 52905, N'Procedure không chặn vượt sức chứa.', 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() <> 51112 THROW;
        SELECT ERROR_NUMBER() AS MaLoiSucChua, ERROR_PROCEDURE() AS NoiBaoLoi;
    END CATCH;

    -- 4. ROLLBACK: lô 6 được tạo trước, lô 5 khiến trigger lỗi 51820;
    -- procedure phải hủy cả lô đầu, tồn và sổ biến động.
    BEGIN TRY
        BEGIN TRANSACTION;
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'QT9001',
            @PhanBoJson = N'[{"maSanPham":"QT9001","maViTri":"QT9001","soLuong":6},
                            {"maSanPham":"QT9001","maViTri":"QT9001","soLuong":5}]';
        ROLLBACK TRANSACTION;
        THROW 52906, N'Procedure không chặn phân bổ 6+5.', 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() <> 51820 THROW;
        SELECT ERROR_NUMBER() AS MaLoiRollback, ERROR_PROCEDURE() AS NoiBaoLoi;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaPN = 'QT9001')
        OR EXISTS (SELECT 1 FROM dbo.TON_KHO WHERE MaViTri IN ('QT9001', 'QT9002'))
        OR EXISTS (SELECT 1 FROM dbo.BIEN_DONG_TON_KHO WHERE MaChungTu = 'QT9001')
        OR NOT EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP
                       WHERE MaPN = 'QT9001' AND TrangThai = N'NHAP')
        THROW 52907, N'Rollback không sạch dữ liệu nhập test.', 1;

    -- 5. VIEW trước hoàn tất: 0 dòng vì phiếu còn NHAP.
    SELECT MaPN, MaSP, MaLo, SoLuongNhap, GiaTriNhap
    FROM dbo.vw_LichSuNhapKho WHERE MaPN = 'QT9001';

    -- 6. PROCEDURE thành công 6+4 trong transaction ngoài.
    -- Đọc view/function trước ROLLBACK; không để lại chứng từ hoàn tất sau bài test.
    BEGIN TRANSACTION;
    EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'QT9001',
        @PhanBoJson = N'[{"maSanPham":"QT9001","maViTri":"QT9001","soLuong":6},
                        {"maSanPham":"QT9001","maViTri":"QT9001","soLuong":4}]';

    -- 7. FUNCTION và VIEW với mã lô do procedure tự sinh (không đoán LOxxxx).
    SELECT MaLo, SoLuongNhap, dbo.fn_TonTheoLo(MaLo) AS TonTheoLo
    FROM dbo.LO_HANG WHERE MaPN = 'QT9001' ORDER BY MaLo;
    SELECT MaPN, MaSP, MaLo, SoLuongNhap, DonGiaNhap, GiaTriNhap
    FROM dbo.vw_LichSuNhapKho WHERE MaPN = 'QT9001' ORDER BY MaLo;
    IF (SELECT COUNT(*) FROM dbo.LO_HANG WHERE MaPN = 'QT9001') <> 2
        OR (SELECT SUM(SoLuongTon) FROM dbo.TON_KHO WHERE MaViTri = 'QT9001') <> 10
        OR (SELECT COUNT(*) FROM dbo.vw_LichSuNhapKho WHERE MaPN = 'QT9001') <> 2
        THROW 52908, N'Hoàn tất 6+4 thiếu lô, tồn hoặc lịch sử.', 1;

    -- 8. TRIGGER trg_LoaiSanPham_BaoVeBaoQuan: loại đã có lô không đổi Khô -> Mát.
    -- Lỗi trigger cũng rollback transaction ngoài, nên phiếu quay về NHAP.
    BEGIN TRY
        UPDATE dbo.LOAI_SAN_PHAM SET YeuCauBaoQuan = N'Mát'
        WHERE MaLoai = 'QT9001';
        ROLLBACK TRANSACTION;
        THROW 52909, N'Trigger bảo quản không chặn loại đã có lô.', 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() <> 51825 THROW;
        SELECT ERROR_NUMBER() AS MaLoiBaoQuan, ERROR_PROCEDURE() AS NoiBaoLoi;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaPN = 'QT9001')
        OR NOT EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP WHERE MaPN = 'QT9001' AND TrangThai = N'NHAP')
        OR NOT EXISTS (SELECT 1 FROM dbo.LOAI_SAN_PHAM
                       WHERE MaLoai = 'QT9001' AND YeuCauBaoQuan = N'Khô')
        THROW 52910, N'Trigger bảo quản không rollback đúng.', 1;

    -- 9. Chỉ xóa fixture nháp do script tạo; dữ liệu thật không bị đổi.
    BEGIN TRANSACTION;
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = 'QT9001';
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN = 'QT9001' AND TrangThai = N'NHAP';
    DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = 'QT9001';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP = 'QT9001';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'QT9001';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = 'QT9001';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri IN ('QT9001', 'QT9002');
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = 'QT9001';
    DELETE FROM dbo.KHO WHERE MaKho = 'QT9001';
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = 'QT9001';
    COMMIT TRANSACTION;
    PRINT N'PASS: index, hai trigger, procedure, rollback, function, view; fixture đã dọn.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    -- Nếu có lỗi bất ngờ, chỉ dọn khi phiếu test vẫn là nháp.
    IF EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP WHERE MaPN = 'QT9001' AND TrangThai = N'NHAP')
    BEGIN
        DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = 'QT9001';
        DELETE FROM dbo.PHIEU_NHAP WHERE MaPN = 'QT9001';
        DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = 'QT9001';
        DELETE FROM dbo.SAN_PHAM WHERE MaSP = 'QT9001';
        DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'QT9001';
        DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = 'QT9001';
        DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri IN ('QT9001', 'QT9002');
        DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = 'QT9001';
        DELETE FROM dbo.KHO WHERE MaKho = 'QT9001';
        DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = 'QT9001';
    END;
    THROW;
END CATCH;
