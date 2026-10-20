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
