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
