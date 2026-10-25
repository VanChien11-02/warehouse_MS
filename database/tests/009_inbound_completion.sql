SET NOCOUNT ON;
SET XACT_ABORT OFF;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST901', N'Nhân viên test hoàn tất nhập', '2026-01-01');
    INSERT INTO dbo.TAI_KHOAN (MaTK, MaNV, MaRole, TenTK, MatKhauHash)
        VALUES ('TST901', 'TST901', 'QLKHO', N'test.inbound.audit',
            '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST901', N'Nhà cung cấp test hoàn tất nhập'),
               ('TST902', N'Nhà cung cấp thiếu mapping');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
        VALUES ('TST901', N'Loại test hoàn tất nhập', N'Khô');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST901', N'Đơn vị test hoàn tất nhập'), ('TST902', N'Đơn vị khác test nhập');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST901', N'Sản phẩm test hoàn tất nhập', 'TST901', 'TST901'),
               ('TST902', N'Sản phẩm khác đơn vị test nhập', 'TST901', 'TST902');
    INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP)
        VALUES ('TST901', 'TST901'), ('TST901', 'TST902');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST901', N'Kho test hoàn tất nhập');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST901', 'TST901', N'Khu khô test hoàn tất nhập', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST901', 'TST901', N'Kệ test hoàn tất nhập', 10, N'Lưu trữ'),
               ('TST902', 'TST901', N'Kệ test rollback trigger', 100, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV)
        VALUES ('TST901', 'TST901', 'TST901'),
               ('TST902', 'TST901', 'TST901'),
               ('TST903', 'TST902', 'TST901'),
               ('TST904', 'TST901', 'TST901'),
               ('TST905', 'TST901', 'TST901'),
               ('TST906', 'TST901', 'TST901');
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST901', 'TST901', 6, 10.1234),
               ('TST902', 'TST901', 5, 10.1234),
               ('TST903', 'TST901', 1, 10.1234),
               ('TST904', 'TST901', 2, 10.1234),
               ('TST905', 'TST901', 10, 10.1234),
               ('TST906', 'TST901', 6, 10.1234),
               ('TST906', 'TST902', 4, 10.1234);
    COMMIT TRANSACTION;

    IF EXISTS (SELECT 1 FROM dbo.vw_LichSuNhapKho WHERE MaPN IN ('TST901', 'TST905'))
        THROW 51920, N'Phiếu nháp xuất hiện trong lịch sử nhập.', 1;
    EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST901',
        @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST901","soLuong":6,"ngaySanXuat":"2026-01-01","hanSuDung":"2026-12-31"}]',
        @MaTK = 'TST901';

    IF (SELECT TrangThai FROM dbo.PHIEU_NHAP WHERE MaPN = 'TST901') <> N'DA_HOAN_THANH'
        THROW 51901, N'Phiếu nhập không hoàn tất.', 1;
    IF (SELECT COUNT(*) FROM dbo.LO_HANG WHERE MaPN = 'TST901') <> 1
        THROW 51902, N'Số lô tạo không đúng.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.vw_LichSuNhapKho WHERE MaPN = 'TST901'
        AND SoLuongNhap = 6 AND DonGiaNhap = 10.1234 AND GiaTriNhap = 60.7404)
        THROW 51921, N'Lịch sử không phản ánh lượng/giá nhập đã hoàn tất.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaPN = 'TST901'
        AND NgaySanXuat = '2026-01-01' AND HanSuDung = '2026-12-31')
        THROW 51914, N'Ngày lô không được giữ đúng sau chuyển đổi.', 1;
    IF (SELECT SUM(ton.SoLuongTon) FROM dbo.TON_KHO ton
        JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo WHERE lo.MaPN = 'TST901') <> 6
        THROW 51903, N'Tồn sau nhập không đúng.', 1;
    IF (SELECT COUNT(*) FROM dbo.BIEN_DONG_TON_KHO
        WHERE MaChungTu = 'TST901' AND LoaiNghiepVu = N'NHAP'
          AND SoLuongThayDoi = 6) <> 1
        THROW 51910, N'Nhập chưa ghi một biến động tồn.', 1;
    IF (SELECT COUNT(*) FROM dbo.LICH_SU_THAO_TAC
        WHERE MaTK = 'TST901' AND TenBang = N'PHIEU_NHAP'
          AND MaBanGhi = 'TST901' AND HanhDong = N'COMPLETE') <> 1
        THROW 52040, N'Hoàn tất nhập chưa ghi actor audit.', 1;

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

    -- Ngày không đọc được và hạn trước ngày sản xuất vẫn bị chặn tại procedure.
    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST904',
            @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST902","soLuong":2,"ngaySanXuat":"sai-ngay"}]';
        THROW 51915, N'Cho phép ngày lô không đọc được.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51104 THROW;
    END CATCH;
    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST904',
            @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST902","soLuong":2,"ngaySanXuat":"2026-12-01","hanSuDung":"2026-01-01"}]';
        THROW 51919, N'Cho phép hạn trước ngày sản xuất.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51104 THROW;
    END CATCH;

    -- Kiểm tra gộp đơn vị: giữa hai hàng sắp nhập và giữa hàng mới với tồn cũ.
    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST906',
            @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST902","soLuong":6},{"maSanPham":"TST902","maViTri":"TST902","soLuong":4}]';
        THROW 51916, N'Cho phép hai hàng mới khác đơn vị cùng vị trí.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51111 THROW;
    END CATCH;
    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST906',
            @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST902","soLuong":6},{"maSanPham":"TST902","maViTri":"TST901","soLuong":4}]';
        THROW 51917, N'Cho phép hàng mới khác đơn vị với tồn cũ.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51111 THROW;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaPN IN ('TST904', 'TST906'))
        THROW 51918, N'Lỗi ngày/đơn vị vẫn để lại lô.', 1;
    -- Real completion reaches the LO_HANG trigger: no artificial testing endpoint.
    -- The first allocation creates a lot, stock and ledger row; the second
    -- exceeds 10, and the entire procedure must roll back those earlier writes.
    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST905',
            @PhanBoJson = N'[{"maSanPham":"TST901","maViTri":"TST902","soLuong":6},{"maSanPham":"TST901","maViTri":"TST902","soLuong":5}]',
            @MaTK = 'TST901';
        THROW 51912, N'Hoàn tất cho phép lô vượt dòng nhập.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51820
            OR ERROR_PROCEDURE() <> N'trg_LoHang_GioiHanPhanBo' THROW;
    END CATCH;
    IF EXISTS (SELECT 1 FROM dbo.LO_HANG WHERE MaPN = 'TST905')
        OR EXISTS (SELECT 1 FROM dbo.vw_LichSuNhapKho WHERE MaPN = 'TST905')
        OR EXISTS (SELECT 1 FROM dbo.TON_KHO WHERE MaViTri = 'TST902')
        OR EXISTS (SELECT 1 FROM dbo.LICH_SU_THAO_TAC
            WHERE TenBang = N'PHIEU_NHAP' AND MaBanGhi = 'TST905' AND HanhDong = N'COMPLETE')
        OR NOT EXISTS (SELECT 1 FROM dbo.PHIEU_NHAP WHERE MaPN = 'TST905'
            AND TrangThai = N'NHAP' AND NgayHoanTat IS NULL)
        THROW 51913, N'Lỗi trigger không rollback toàn bộ nghiệp vụ nhập.', 1;

    IF EXISTS (SELECT 1 FROM dbo.BIEN_DONG_TON_KHO
        WHERE MaChungTu IN ('TST902', 'TST903', 'TST904', 'TST905', 'TST906'))
        THROW 51911, N'Phiếu nhập thất bại đã ghi biến động.', 1;

    BEGIN TRANSACTION;
    DELETE ton FROM dbo.TON_KHO ton JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo
        WHERE lo.MaPN IN ('TST901', 'TST902', 'TST903', 'TST904', 'TST905', 'TST906');
    DELETE FROM dbo.BIEN_DONG_TON_KHO WHERE MaChungTu IN ('TST901', 'TST902', 'TST903', 'TST904', 'TST905', 'TST906');
    DELETE FROM dbo.LO_HANG WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904', 'TST905', 'TST906');
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904', 'TST905', 'TST906');
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904', 'TST905', 'TST906');
    DELETE FROM dbo.LICH_SU_THAO_TAC WHERE MaTK = 'TST901';
    DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = 'TST901';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP IN ('TST901', 'TST902');
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'TST901';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT IN ('TST901', 'TST902');
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri IN ('TST901', 'TST902');
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = 'TST901';
    DELETE FROM dbo.KHO WHERE MaKho = 'TST901';
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC IN ('TST901', 'TST902');
    DELETE FROM dbo.TAI_KHOAN WHERE MaTK = 'TST901';
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = 'TST901';
    COMMIT TRANSACTION;
    PRINT N'Inbound completion passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    BEGIN TRANSACTION;
    DELETE ton FROM dbo.TON_KHO ton JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo
        WHERE lo.MaPN IN ('TST901', 'TST902', 'TST903', 'TST904', 'TST905', 'TST906');
    DELETE FROM dbo.BIEN_DONG_TON_KHO WHERE MaChungTu IN ('TST901', 'TST902', 'TST903', 'TST904', 'TST905', 'TST906');
    DELETE FROM dbo.LO_HANG WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904', 'TST905', 'TST906');
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904', 'TST905', 'TST906');
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN IN ('TST901', 'TST902', 'TST903', 'TST904', 'TST905', 'TST906');
    DELETE FROM dbo.LICH_SU_THAO_TAC WHERE MaTK = 'TST901';
    DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = 'TST901';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP IN ('TST901', 'TST902');
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = 'TST901';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT IN ('TST901', 'TST902');
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri IN ('TST901', 'TST902');
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = 'TST901';
    DELETE FROM dbo.KHO WHERE MaKho = 'TST901';
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC IN ('TST901', 'TST902');
    DELETE FROM dbo.TAI_KHOAN WHERE MaTK = 'TST901';
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = 'TST901';
    COMMIT TRANSACTION;
    THROW;
END CATCH;
