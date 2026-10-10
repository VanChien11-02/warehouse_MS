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
