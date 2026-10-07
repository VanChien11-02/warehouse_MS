SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @CleanupSql NVARCHAR(MAX) = N'
    DELETE FROM dbo.LICH_SU_THAO_TAC WHERE MaTK = ''TST181'';
    DELETE FROM dbo.BIEN_DONG_TON_KHO WHERE MaChungTu IN (''TST181'', ''TST182'', ''TST183'', ''TST184'', ''TST185'');
    DELETE FROM dbo.CT_PHIEU_TRA_HANG WHERE MaPTH IN (''TST181'', ''TST182'', ''TST183'', ''TST184'', ''TST185'');
    DELETE FROM dbo.PHIEU_TRA_HANG WHERE MaPTH IN (''TST181'', ''TST182'', ''TST183'', ''TST184'', ''TST185'');
    DELETE FROM dbo.CT_PHIEU_XUAT WHERE MaPX = ''TST181'';
    DELETE FROM dbo.PHIEU_XUAT WHERE MaPX = ''TST181'';
    DELETE ton FROM dbo.TON_KHO ton JOIN dbo.LO_HANG lot ON lot.MaLo = ton.MaLo WHERE lot.MaPN = ''TST181'';
    DELETE FROM dbo.LO_HANG WHERE MaPN = ''TST181'';
    DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = ''TST181'';
    DELETE FROM dbo.PHIEU_NHAP WHERE MaPN = ''TST181'';
    DELETE FROM dbo.DOI_TAC_SAN_PHAM WHERE MaDTNH = ''TST181'';
    DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = ''TST181'';
    DELETE FROM dbo.SAN_PHAM WHERE MaSP = ''TST181'';
    DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = ''TST181'';
    DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = ''TST181'';
    DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri IN (''TST181'', ''TST182'');
    DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = ''TST181'';
    DELETE FROM dbo.KHO WHERE MaKho = ''TST181'';
    DELETE FROM dbo.DOI_TAC_NHAN_HANG WHERE MaDTNH = ''TST181'';
    DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = ''TST181'';
    DELETE FROM dbo.TAI_KHOAN WHERE MaTK = ''TST181'';
    DELETE FROM dbo.NHAN_VIEN WHERE MaNV = ''TST181'';
';

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST181', N'Nhân viên trả', '2026-01-01');
    INSERT INTO dbo.TAI_KHOAN (MaTK, MaNV, MaRole, TenTK, MatKhauHash)
        VALUES ('TST181', 'TST181', 'QLKHO', N'test.return.audit',
            '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST181', N'Nhà cung cấp trả');
    INSERT INTO dbo.DOI_TAC_NHAN_HANG (MaDTNH, TenDoiTac, LoaiDoiTac)
        VALUES ('TST181', N'Đối tác trả', N'Khách hàng');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, YeuCauBaoQuan)
        VALUES ('TST181', N'Loại trả', N'Khô');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST181', N'Đơn vị trả');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST181', N'Sản phẩm trả', 'TST181', 'TST181');
    INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP)
        VALUES ('TST181', 'TST181');
    INSERT INTO dbo.DOI_TAC_SAN_PHAM (MaDTNH, MaSP)
        VALUES ('TST181', 'TST181');
    INSERT INTO dbo.KHO (MaKho, TenKho) VALUES ('TST181', N'Kho trả');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST181', 'TST181', N'Khu trả', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST181', 'TST181', N'Vị trí tốt', 8, N'Lưu trữ'),
               ('TST182', 'TST181', N'Vị trí hư hỏng', 4, N'Hư hỏng');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV)
        VALUES ('TST181', 'TST181', 'TST181');
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST181', 'TST181', 6, 8.2500);
    COMMIT TRANSACTION;

    EXEC dbo.sp_HoanTatPhieuNhap @MaPN = 'TST181',
        @PhanBoJson = N'[{"maSanPham":"TST181","maViTri":"TST181","soLuong":6}]';
    DECLARE @MaLo CHAR(6) = (SELECT MaLo FROM dbo.LO_HANG WHERE MaPN = 'TST181');
    IF @MaLo IS NULL THROW 52020, N'Không tạo được lô trả.', 1;
    INSERT INTO dbo.PHIEU_XUAT (MaPX, MaDTNH, MaNV)
        VALUES ('TST181', 'TST181', 'TST181');
    INSERT INTO dbo.CT_PHIEU_XUAT (MaPX, MaLo, MaViTri, SoLuong, DonGiaXuat)
        VALUES ('TST181', @MaLo, 'TST181', 4, 12.0000);
    EXEC dbo.sp_HoanTatPhieuXuat @MaPX = 'TST181', @NgayNghiepVu = '2026-10-07';

    INSERT INTO dbo.PHIEU_TRA_HANG (MaPTH, MaPX, MaNV)
        VALUES ('TST181', 'TST181', 'TST181'),
               ('TST182', 'TST181', 'TST181'),
               ('TST183', 'TST181', 'TST181'),
               ('TST184', 'TST181', 'TST181');
    INSERT INTO dbo.CT_PHIEU_TRA_HANG (MaPTH, MaLo, MaViTri, SoLuong, TinhTrang)
        VALUES ('TST181', @MaLo, 'TST181', 2, N'Tốt'),
               ('TST182', @MaLo, 'TST182', 1, N'Hư hỏng'),
               ('TST183', @MaLo, 'TST181', 3, N'Tốt'),
               ('TST184', @MaLo, 'TST182', 1, N'Tốt');

    EXEC dbo.sp_HoanTatTraHang @MaPTH = 'TST181', @MaTK = 'TST181';
    EXEC dbo.sp_HoanTatTraHang @MaPTH = 'TST182';
    IF (SELECT COUNT(*) FROM dbo.LICH_SU_THAO_TAC
        WHERE MaTK = 'TST181' AND TenBang = N'PHIEU_TRA_HANG'
          AND MaBanGhi = 'TST181' AND HanhDong = N'COMPLETE') <> 1
        THROW 52044, N'Hoàn tất trả hàng chưa ghi actor audit.', 1;
    IF (SELECT SoLuongTon FROM dbo.TON_KHO WHERE MaViTri = 'TST181' AND MaLo = @MaLo) <> 4
        OR (SELECT SoLuongTon FROM dbo.TON_KHO WHERE MaViTri = 'TST182' AND MaLo = @MaLo) <> 1
        THROW 52021, N'Tồn sau trả tốt/hỏng sai.', 1;
    IF (SELECT SUM(SoLuongThayDoi) FROM dbo.BIEN_DONG_TON_KHO
        WHERE LoaiNghiepVu = N'TRA_HANG' AND MaChungTu IN ('TST181', 'TST182')) <> 3
        THROW 52022, N'Sổ biến động trả hàng sai.', 1;
    IF EXISTS (SELECT 1 FROM dbo.vw_TonKhoChiTiet
        WHERE MaViTri = 'TST182' AND MaLo = @MaLo AND LoaiViTri <> N'Hư hỏng')
        THROW 52023, N'Hàng hỏng vẫn ở tồn khả dụng.', 1;

    BEGIN TRY
        EXEC dbo.sp_HoanTatTraHang @MaPTH = 'TST181';
        THROW 52024, N'Phiếu trả được hoàn tất hai lần.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51502 THROW;
    END CATCH;
    BEGIN TRY
        EXEC dbo.sp_HoanTatTraHang @MaPTH = 'TST183';
        THROW 52025, N'Trả vượt lượng xuất được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51505 THROW;
    END CATCH;
    BEGIN TRY
        EXEC dbo.sp_HoanTatTraHang @MaPTH = 'TST184';
        THROW 52026, N'Hàng tốt vào vị trí hỏng được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 51506 THROW;
    END CATCH;

    INSERT INTO dbo.PHIEU_TRA_HANG (MaPTH, MaPX, MaNV)
        VALUES ('TST185', 'TST181', 'TST181');
    INSERT INTO dbo.CT_PHIEU_TRA_HANG (MaPTH, MaLo, MaViTri, SoLuong, TinhTrang)
        VALUES ('TST185', @MaLo, 'TST181', 1, N'Tốt');
    INSERT INTO dbo.BIEN_DONG_TON_KHO
        (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
        VALUES (N'TRA_HANG', 'TST185', 'TST181', @MaLo, 1, SYSUTCDATETIME());
    BEGIN TRY
        EXEC dbo.sp_HoanTatTraHang @MaPTH = 'TST185';
        THROW 52027, N'Lỗi ghi sổ không rollback tồn trả.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601, 2627) THROW;
    END CATCH;
    IF (SELECT SoLuongTon FROM dbo.TON_KHO WHERE MaViTri = 'TST181' AND MaLo = @MaLo) <> 4
        OR (SELECT TrangThai FROM dbo.PHIEU_TRA_HANG WHERE MaPTH = 'TST185') <> N'NHAP'
        THROW 52028, N'Lỗi ghi sổ để tồn trả dở dang.', 1;

    EXEC sp_executesql @CleanupSql;
    PRINT N'Return completion passed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    EXEC sp_executesql @CleanupSql;
    THROW;
END CATCH;
