SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @CleanupSql NVARCHAR(MAX) = N'
    DELETE FROM dbo.LICH_SU_THAO_TAC WHERE MaTK = ''TST121'';
    DELETE FROM dbo.BIEN_DONG_TON_KHO WHERE MaChungTu = ''TST121'';
    DELETE FROM dbo.CT_PHIEU_XUAT WHERE MaPX IN (''TST121'', ''TST122'', ''TST123'');
    DELETE FROM dbo.PHIEU_XUAT WHERE MaPX IN (''TST121'', ''TST122'', ''TST123'');
    DELETE ton FROM dbo.TON_KHO ton JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo
        WHERE lo.MaPN = ''TST121'';
    DELETE FROM dbo.LO_HANG WHERE MaPN = ''TST121'';
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = ''TST121'';
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN = ''TST121'';
    DELETE FROM dbo.DOI_TAC_SAN_PHAM WHERE MaDTNH = ''TST121'';
    DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = ''TST121'';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP = ''TST121'';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = ''TST121'';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = ''TST121'';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri = ''TST121'';
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = ''TST121'';
    DELETE FROM dbo.KHO WHERE MaKho = ''TST121'';
    DELETE FROM dbo.DOI_TAC_NHAN_HANG WHERE MaDTNH IN (''TST121'', ''TST122'');
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = ''TST121'';
    DELETE FROM dbo.TAI_KHOAN WHERE MaTK = ''TST121'';
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = ''TST121'';
';

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST121', N'Nhân viên test hoàn tất xuất', '2026-01-01');
    INSERT INTO dbo.TAI_KHOAN (MaTK, MaNV, MaRole, TenTK, MatKhauHash)
        VALUES ('TST121', 'TST121', 'QLKHO', N'test.outbound.audit',
            '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST121', N'Nhà cung cấp test hoàn tất xuất');
    INSERT INTO dbo.DOI_TAC_NHAN_HANG (MaDTNH, TenDoiTac, LoaiDoiTac)
        VALUES ('TST121', N'Đối tác test hoàn tất xuất', N'Khách hàng'),
               ('TST122', N'Đối tác thiếu mapping', N'Khách hàng');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
        VALUES ('TST121', N'Loại test hoàn tất xuất', N'Khô');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST121', N'Đơn vị test hoàn tất xuất');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST121', N'Sản phẩm test hoàn tất xuất', 'TST121', 'TST121');
    INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP)
        VALUES ('TST121', 'TST121');
    INSERT INTO dbo.DOI_TAC_SAN_PHAM (MaDTNH, MaSP)
        VALUES ('TST121', 'TST121');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST121', N'Kho test hoàn tất xuất');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST121', 'TST121', N'Khu test hoàn tất xuất', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST121', 'TST121', N'Kệ test hoàn tất xuất', 10, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV)
        VALUES ('TST121', 'TST121', 'TST121');
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST121', 'TST121', 10, 10.1234);
    COMMIT TRANSACTION;

    EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST121',
        @PhanBoJson = N'[{"maSanPham":"TST121","maViTri":"TST121","soLuong":4,"hanSuDung":"2026-11-01"},{"maSanPham":"TST121","maViTri":"TST121","soLuong":6,"hanSuDung":"2026-12-01"}]';

    DECLARE @LoSom CHAR(6) = (
        SELECT MaLo FROM dbo.LO_HANG WHERE MaPN = 'TST121' AND HanSuDung = '2026-11-01'
    );
    DECLARE @LoMuon CHAR(6) = (
        SELECT MaLo FROM dbo.LO_HANG WHERE MaPN = 'TST121' AND HanSuDung = '2026-12-01'
    );
    IF @LoSom IS NULL OR @LoMuon IS NULL
        THROW 51940, N'Không tạo đủ hai lô để kiểm thử FEFO.', 1;

    INSERT INTO dbo.PHIEU_XUAT (MaPX, MaDTNH, MaNV)
        VALUES ('TST121', 'TST121', 'TST121'),
               ('TST122', 'TST121', 'TST121'),
               ('TST123', 'TST122', 'TST121');
    INSERT INTO dbo.CT_PHIEU_XUAT (MaPX, MaLo, MaViTri, SoLuong, DonGiaXuat)
        VALUES ('TST121', @LoMuon, 'TST121', 2, 20.0000);

    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuXuat @MaPX = 'TST121', @NgayNghiepVu = '2026-10-07';
        THROW 51941, N'Xuất lô muộn trước lô sớm được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51209 THROW;
    END CATCH;
    IF (SELECT SoLuongTon FROM dbo.TON_KHO WHERE MaViTri = 'TST121' AND MaLo = @LoMuon) <> 6
        THROW 51942, N'Lỗi FEFO đã thay đổi tồn.', 1;

    INSERT INTO dbo.CT_PHIEU_XUAT (MaPX, MaLo, MaViTri, SoLuong, DonGiaXuat)
        VALUES ('TST121', @LoSom, 'TST121', 4, 20.0000);
    EXEC dbo.sp_HoanTatPhieuXuat @MaPX = 'TST121', @NgayNghiepVu = '2026-10-07',
        @MaTK = 'TST121';
    IF (SELECT SoLuongTon FROM dbo.TON_KHO WHERE MaViTri = 'TST121' AND MaLo = @LoSom) <> 0
        THROW 51943, N'Lô sớm không được trừ hết.', 1;
    IF (SELECT SoLuongTon FROM dbo.TON_KHO WHERE MaViTri = 'TST121' AND MaLo = @LoMuon) <> 4
        THROW 51944, N'Lô muộn không được trừ đúng.', 1;
    IF (SELECT SUM(SoLuongThayDoi) FROM dbo.BIEN_DONG_TON_KHO
        WHERE MaChungTu = 'TST121' AND LoaiNghiepVu = N'XUAT') <> -6
        THROW 51949, N'Xuất chưa ghi đúng biến động tồn.', 1;
    IF (SELECT COUNT(*) FROM dbo.LICH_SU_THAO_TAC
        WHERE MaTK = 'TST121' AND TenBang = N'PHIEU_XUAT'
          AND MaBanGhi = 'TST121' AND HanhDong = N'COMPLETE') <> 1
        THROW 52041, N'Hoàn tất xuất chưa ghi actor audit.', 1;
    IF (SELECT SUM(GiaTriThayDoi) FROM dbo.vw_BienDongTonKhoChiTiet
        WHERE MaKho = 'TST121' AND MaSP = 'TST121') <> 40.4936
        THROW 51951, N'View báo cáo không dùng đúng giá nhập thực tế.', 1;
    IF EXISTS (SELECT 1 FROM dbo.vw_BienDongTonKhoChiTiet
        WHERE MaKho = 'TST121' AND MaSP = 'TST121'
          AND (NgayGhiSo IS NULL OR DonGiaNhap <> 10.1234))
        THROW 51952, N'View báo cáo thiếu thời điểm hoặc đơn giá.', 1;
    DECLARE @TuNgayUtc DATETIME2(3) =
        (SELECT NgayHoanTat FROM dbo.PHIEU_NHAP WHERE MaPN = 'TST121');
    DECLARE @DenNgayUtc DATETIME2(3) = DATEADD(MILLISECOND, 1,
        (SELECT NgayHoanTat FROM dbo.PHIEU_XUAT WHERE MaPX = 'TST121'));
    DECLARE @DauKy BIGINT, @Nhap BIGINT, @Xuat BIGINT, @CuoiKy BIGINT;
    SELECT @DauKy = SUM(CASE WHEN NgayGhiSo < @TuNgayUtc
                   THEN CONVERT(BIGINT, SoLuongThayDoi) ELSE CONVERT(BIGINT, 0) END),
           @Nhap = SUM(CASE WHEN NgayGhiSo >= @TuNgayUtc AND LoaiNghiepVu = N'NHAP'
                   THEN CONVERT(BIGINT, SoLuongThayDoi) ELSE CONVERT(BIGINT, 0) END),
           @Xuat = -SUM(CASE WHEN NgayGhiSo >= @TuNgayUtc AND LoaiNghiepVu = N'XUAT'
                   THEN CONVERT(BIGINT, SoLuongThayDoi) ELSE CONVERT(BIGINT, 0) END),
           @CuoiKy = SUM(CONVERT(BIGINT, SoLuongThayDoi))
    FROM dbo.vw_BienDongTonKhoChiTiet
    WHERE NgayGhiSo < @DenNgayUtc AND MaKho = 'TST121' AND MaSP = 'TST121';
    IF @DauKy <> 0 OR @Nhap <> 10 OR @Xuat <> 6 OR @CuoiKy <> 4
        THROW 51953, N'Báo cáo nhập-xuất-tồn sai số lượng hoặc boundary.', 1;

    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuXuat @MaPX = 'TST121', @NgayNghiepVu = '2026-10-07';
        THROW 51945, N'Phiếu xuất được hoàn tất hai lần.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51202 THROW;
    END CATCH;

    INSERT INTO dbo.CT_PHIEU_XUAT (MaPX, MaLo, MaViTri, SoLuong, DonGiaXuat)
        VALUES ('TST122', @LoMuon, 'TST121', 5, 20.0000),
               ('TST123', @LoMuon, 'TST121', 1, 20.0000);
    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuXuat @MaPX = 'TST122', @NgayNghiepVu = '2026-10-07';
        THROW 51946, N'Xuất vượt tồn được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51208 THROW;
    END CATCH;
    BEGIN TRY
        EXEC dbo.sp_HoanTatPhieuXuat @MaPX = 'TST123', @NgayNghiepVu = '2026-10-07';
        THROW 51947, N'Đối tác thiếu mapping được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51207 THROW;
    END CATCH;
    IF (SELECT SoLuongTon FROM dbo.TON_KHO WHERE MaViTri = 'TST121' AND MaLo = @LoMuon) <> 4
        THROW 51948, N'Phiếu thất bại đã thay đổi tồn.', 1;
    IF EXISTS (SELECT 1 FROM dbo.BIEN_DONG_TON_KHO
        WHERE MaChungTu IN ('TST122', 'TST123') AND LoaiNghiepVu = N'XUAT')
        THROW 51950, N'Phiếu xuất thất bại đã ghi biến động.', 1;

    EXEC sp_executesql @CleanupSql;
    PRINT N'Outbound completion and FEFO passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    EXEC sp_executesql @CleanupSql;
    THROW;
END CATCH;
