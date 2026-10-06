SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST131', N'Nhân viên test chuyển', '2026-01-01');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST131', N'Nhà cung cấp test chuyển');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai)
        VALUES ('TST131', N'Loại test chuyển');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST131', N'Đơn vị test chuyển');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST131', N'Sản phẩm test chuyển', 'TST131', 'TST131');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST131', N'Kho test chuyển');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST131', 'TST131', N'Khu test chuyển', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST131', 'TST131', N'Vị trí nguồn', 10, N'Lưu trữ'),
               ('TST132', 'TST131', N'Vị trí đích', 10, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, TrangThai, NgayHoanTat)
        VALUES ('TST131', 'TST131', 'TST131', N'DA_HOAN_THANH', SYSUTCDATETIME());
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST131', 'TST131', 5, 1.2345);
    INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, SoLuongNhap)
        VALUES ('TST131', 'TST131', 'TST131', 5);
    INSERT INTO dbo.PHIEU_CHUYEN_KHO (MaPCK, MaNV)
        VALUES ('TST131', 'TST131');
    INSERT INTO dbo.CT_PHIEU_CHUYEN_KHO
        (MaPCK, MaLo, MaViTriNguon, MaViTriDich, SoLuong)
        VALUES ('TST131', 'TST131', 'TST131', 'TST132', 2);

    BEGIN TRY
        INSERT INTO dbo.CT_PHIEU_CHUYEN_KHO
            (MaPCK, MaLo, MaViTriNguon, MaViTriDich, SoLuong)
            VALUES ('TST131', 'TST131', 'TST131', 'TST131', 1);
        THROW 51961, N'Chuyển cùng vị trí được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        UPDATE dbo.CT_PHIEU_CHUYEN_KHO SET SoLuong = 0 WHERE MaPCK = 'TST131';
        THROW 51962, N'Số lượng chuyển 0 được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        UPDATE dbo.PHIEU_CHUYEN_KHO SET TrangThai = N'DA_HOAN_THANH'
            WHERE MaPCK = 'TST131';
        THROW 51963, N'Phiếu chuyển hoàn tất thiếu thời điểm được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    ROLLBACK TRANSACTION;
    PRINT N'Transfer constraints passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
