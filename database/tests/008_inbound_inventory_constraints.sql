SET NOCOUNT ON;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;

BEGIN TRY
    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('TST801', N'Nhân viên kiểm thử nhập', '2026-01-01');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('TST801', N'Nhà cung cấp kiểm thử nhập');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai)
        VALUES ('TST801', N'Loại kiểm thử nhập');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('TST801', N'Đơn vị kiểm thử nhập');
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
        VALUES ('TST801', N'Sản phẩm kiểm thử nhập', 'TST801', 'TST801');
    INSERT INTO dbo.KHO (MaKho, TenKho)
        VALUES ('TST801', N'Kho kiểm thử nhập');
    INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
        VALUES ('TST801', 'TST801', N'Khu kiểm thử nhập', N'Khô');
    INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
        VALUES ('TST801', 'TST801', N'Vị trí kiểm thử nhập', 100, N'Lưu trữ');
    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV)
        VALUES ('TST801', 'TST801', 'TST801');
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
        VALUES ('TST801', 'TST801', 10, 12.3456);
    INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, NgaySanXuat, HanSuDung, SoLuongNhap)
        VALUES ('TST801', 'TST801', 'TST801', '2026-01-01', '2026-12-31', 10);
    INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
        VALUES ('TST801', 'TST801', 10);

    IF (SELECT DonGiaNhap FROM dbo.CT_PHIEU_NHAP
        WHERE MaPN = 'TST801' AND MaSP = 'TST801') <> 12.3456
        THROW 51801, N'Đơn giá nhập không giữ bốn chữ số thập phân.', 1;

    BEGIN TRY
        UPDATE dbo.CT_PHIEU_NHAP SET SoLuong = 0
            WHERE MaPN = 'TST801' AND MaSP = 'TST801';
        THROW 51802, N'Số lượng dòng nhập 0 được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, NgaySanXuat, HanSuDung, SoLuongNhap)
            VALUES ('TST802', 'TST801', 'TST801', '2026-12-31', '2026-01-01', 1);
        THROW 51803, N'Hạn dùng trước ngày sản xuất được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        UPDATE dbo.TON_KHO SET SoLuongTon = -1
        WHERE MaViTri = 'TST801' AND MaLo = 'TST801';
        THROW 51804, N'Tồn âm được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    BEGIN TRY
        UPDATE dbo.PHIEU_NHAP SET TrangThai = N'DA_HOAN_THANH' WHERE MaPN = 'TST801';
        THROW 51805, N'Phiếu hoàn tất không có thời điểm được chấp nhận.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;

    ROLLBACK TRANSACTION;
    PRINT N'Inbound inventory constraints passed.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
