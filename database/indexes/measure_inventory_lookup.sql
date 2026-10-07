SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Today DATE = CONVERT(DATE, SYSUTCDATETIME());

    INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
        VALUES ('PER001', N'Nhân viên đo index', '2026-01-01');
    INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC)
        VALUES ('PER001', N'Nhà cung cấp đo index');
    INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai)
        VALUES ('PER001', N'Loại đo index');
    INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT)
        VALUES ('PER001', N'Đơn vị đo index');

    ;WITH numbers AS (
        SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY object_id) AS n
        FROM sys.all_objects
    )
    INSERT INTO dbo.SAN_PHAM (MaSP, TenSP, MaLoai, MaDVT)
    SELECT 'S' + RIGHT('00000' + CONVERT(VARCHAR(5), n), 5),
           CONCAT(N'Sản phẩm đo index ', n), 'PER001', 'PER001'
    FROM numbers;

    INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, TrangThai, NgayHoanTat)
        VALUES ('PER001', 'PER001', 'PER001', N'DA_HOAN_THANH', SYSUTCDATETIME());
    INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
    SELECT 'PER001', MaSP, 100, 1.0000 FROM dbo.SAN_PHAM
    WHERE MaLoai = 'PER001';

    ;WITH numbers AS (
        SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY object_id) AS n
        FROM sys.all_objects
    ), lots AS (
        SELECT product.MaSP, numbers.n,
               ROW_NUMBER() OVER (ORDER BY product.MaSP, numbers.n) AS lotNumber
        FROM dbo.SAN_PHAM product CROSS JOIN numbers
        WHERE product.MaLoai = 'PER001'
    )
    INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, HanSuDung, SoLuongNhap)
    SELECT 'P' + RIGHT('00000' + CONVERT(VARCHAR(5), lotNumber), 5),
           'PER001', MaSP, DATEADD(DAY, n % 60, @Today), 1
    FROM lots;

    PRINT N'Baseline: clustered scan trên 10.000 lô, lọc một sản phẩm.';
    SET STATISTICS IO ON;
    SET STATISTICS TIME ON;
    SELECT COUNT_BIG(*) AS SoLo
    FROM dbo.LO_HANG WITH (INDEX(0))
    WHERE MaSP = 'S00042' AND HanSuDung >= @Today;

    PRINT N'Indexed: IX_LO_HANG_SAN_PHAM_HAN trên cùng dữ liệu và predicate.';
    SELECT COUNT_BIG(*) AS SoLo
    FROM dbo.LO_HANG WITH (INDEX(IX_LO_HANG_SAN_PHAM_HAN))
    WHERE MaSP = 'S00042' AND HanSuDung >= @Today;
    SET STATISTICS TIME OFF;
    SET STATISTICS IO OFF;

    ROLLBACK TRANSACTION;
    PRINT N'Đã rollback toàn bộ dữ liệu đo.';
END TRY
BEGIN CATCH
    SET STATISTICS TIME OFF;
    SET STATISTICS IO OFF;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
