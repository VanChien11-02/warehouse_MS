-- Migration giữ nguyên SQL trước khi gom file; nội dung :r đã được đưa trực tiếp vào đây.
:ON ERROR EXIT
CREATE OR ALTER FUNCTION dbo.fn_TonTheoSanPham(@MaSP CHAR(6))
RETURNS BIGINT
AS
BEGIN
    DECLARE @SoLuong BIGINT;
    SELECT @SoLuong = COALESCE(SUM(CONVERT(BIGINT, ton.SoLuongTon)), 0)
    FROM dbo.TON_KHO ton
    JOIN dbo.LO_HANG lot ON lot.MaLo = ton.MaLo
    WHERE lot.MaSP = @MaSP;
    RETURN @SoLuong;
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_TonTheoLo(@MaLo CHAR(6))
RETURNS BIGINT
AS
BEGIN
    DECLARE @SoLuong BIGINT;
    SELECT @SoLuong = COALESCE(SUM(CONVERT(BIGINT, SoLuongTon)), 0)
    FROM dbo.TON_KHO WHERE MaLo = @MaLo;
    RETURN @SoLuong;
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_TonKhaDungTaiViTri(@MaLo CHAR(6), @MaViTri CHAR(6))
RETURNS INT
AS
BEGIN
    DECLARE @SoLuong INT = 0;
    DECLARE @NgayNghiepVu DATE = CONVERT(DATE,
        SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time');
    SELECT @SoLuong = ton.SoLuongTon
    FROM dbo.TON_KHO ton
    JOIN dbo.VI_TRI_KHO position ON position.MaViTri = ton.MaViTri
    JOIN dbo.LO_HANG lot ON lot.MaLo = ton.MaLo
    WHERE ton.MaLo = @MaLo AND ton.MaViTri = @MaViTri
      AND position.LoaiViTri <> N'Hư hỏng'
      AND (lot.HanSuDung IS NULL OR lot.HanSuDung >= @NgayNghiepVu);
    RETURN @SoLuong;
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_GiaTriTonKho(@MaKho CHAR(6))
RETURNS DECIMAL(38,4)
AS
BEGIN
    DECLARE @GiaTri DECIMAL(38,4);
    SELECT @GiaTri = COALESCE(SUM(CONVERT(DECIMAL(38,4),
        stock.SoLuongTon * stock.DonGiaNhap)), 0)
    FROM dbo.vw_TonKhoChiTiet stock
    WHERE stock.MaKho = @MaKho;
    RETURN @GiaTri;
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_LoSapHetHan(@SoNgay INT)
RETURNS TABLE
AS
RETURN
(
    SELECT stock.MaKho, stock.TenKho, stock.MaViTri, stock.TenViTri,
           stock.MaLo, stock.MaSP, stock.TenSP, stock.SoLuongTon,
           stock.HanSuDung,
           DATEDIFF(DAY, today.NgayNghiepVu, stock.HanSuDung) AS SoNgayConLai
    FROM dbo.vw_TonKhoChiTiet stock
    CROSS APPLY (VALUES (CONVERT(DATE,
        SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time'))) today(NgayNghiepVu)
    WHERE @SoNgay BETWEEN 0 AND 3650
      AND stock.SoLuongTon > 0
      AND stock.LoaiViTri <> N'Hư hỏng'
      AND stock.HanSuDung >= today.NgayNghiepVu
      AND stock.HanSuDung <= DATEADD(DAY, @SoNgay, today.NgayNghiepVu)
);
GO
CREATE OR ALTER VIEW dbo.vw_TonKhoTheoSanPham
AS
SELECT MaKho, TenKho, MaSP, TenSP, MaDVT,
       SUM(CONVERT(BIGINT, SoLuongTon)) AS SoLuongTon,
       SUM(CONVERT(DECIMAL(38,4), SoLuongTon * DonGiaNhap)) AS GiaTriTon
FROM dbo.vw_TonKhoChiTiet
WHERE SoLuongTon > 0
GROUP BY MaKho, TenKho, MaSP, TenSP, MaDVT;
GO
CREATE OR ALTER VIEW dbo.vw_LichSuNhapKho
AS
SELECT receipt.MaPN, receipt.NgayHoanTat, receipt.MaNCC,
       line.MaSP, product.TenSP, product.MaDVT,
       lot.MaLo, lot.NgaySanXuat, lot.HanSuDung,
       lot.SoLuongNhap, line.DonGiaNhap,
       CONVERT(DECIMAL(38,4), lot.SoLuongNhap * line.DonGiaNhap) AS GiaTriNhap
FROM dbo.PHIEU_NHAP receipt
JOIN dbo.CT_PHIEU_NHAP line ON line.MaPN = receipt.MaPN
JOIN dbo.SAN_PHAM product ON product.MaSP = line.MaSP
JOIN dbo.LO_HANG lot ON lot.MaPN = line.MaPN AND lot.MaSP = line.MaSP
WHERE receipt.TrangThai = N'DA_HOAN_THANH';
GO
CREATE OR ALTER VIEW dbo.vw_LichSuXuatKho
AS
SELECT dispatch.MaPX, dispatch.NgayHoanTat, dispatch.MaDTNH,
       line.MaLo, lot.MaSP, product.TenSP, product.MaDVT,
       line.MaViTri, line.SoLuong, line.DonGiaXuat,
       CONVERT(DECIMAL(38,4), line.SoLuong * line.DonGiaXuat) AS GiaTriXuat
FROM dbo.PHIEU_XUAT dispatch
JOIN dbo.CT_PHIEU_XUAT line ON line.MaPX = dispatch.MaPX
JOIN dbo.LO_HANG lot ON lot.MaLo = line.MaLo
JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
WHERE dispatch.TrangThai = N'DA_HOAN_THANH';
GO
CREATE OR ALTER VIEW dbo.vw_LoSapHetHan
AS
SELECT MaKho, TenKho, MaViTri, TenViTri, MaLo, MaSP, TenSP,
       SoLuongTon, HanSuDung, SoNgayConLai
FROM dbo.fn_LoSapHetHan(30);
GO
