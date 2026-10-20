CREATE OR ALTER VIEW dbo.vw_TonKhoTheoSanPham
AS
SELECT MaKho, TenKho, MaSP, TenSP, MaDVT,
       SUM(CONVERT(BIGINT, SoLuongTon)) AS SoLuongTon,
       SUM(CONVERT(DECIMAL(38,4), SoLuongTon * DonGiaNhap)) AS GiaTriTon
FROM dbo.vw_TonKhoChiTiet
WHERE SoLuongTon > 0
GROUP BY MaKho, TenKho, MaSP, TenSP, MaDVT;
GO
