-- Các functions được gom theo loại; giữ nguyên tên và nội dung SQL.

-- fn_TonTheoSanPham: Tổng số lượng tồn của một sản phẩm trên tất cả lô và vị trí.
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

-- fn_TonTheoLo: Tổng số lượng tồn của một lô trên tất cả vị trí.
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

-- fn_TonKhaDungTaiViTri: Số tồn có thể xuất của một lô tại vị trí: loại hàng hư hỏng và lô hết hạn.
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

-- fn_GiaTriTonKho: Tính giá trị tồn của một kho theo số lượng và đơn giá nhập từ view chi tiết.
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

-- fn_LoSapHetHan: Danh sách tồn còn hạn sắp hết hạn trong số ngày truyền vào, loại hàng hư hỏng.
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
