CREATE OR ALTER VIEW dbo.vw_BienDongTonKhoChiTiet
AS
SELECT bd.MaBienDong, bd.LoaiNghiepVu, bd.MaChungTu, bd.NgayGhiSo,
       bd.MaViTri, vt.TenViTri, kv.MaKhuVuc, kho.MaKho, kho.TenKho,
       bd.MaLo, lo.MaSP, sp.TenSP, sp.MaDVT, bd.SoLuongThayDoi,
       ct.DonGiaNhap,
       CAST(bd.SoLuongThayDoi * ct.DonGiaNhap AS DECIMAL(38,4)) AS GiaTriThayDoi
FROM dbo.BIEN_DONG_TON_KHO bd
JOIN dbo.VI_TRI_KHO vt ON vt.MaViTri = bd.MaViTri
JOIN dbo.KHU_VUC kv ON kv.MaKhuVuc = vt.MaKhuVuc
JOIN dbo.KHO kho ON kho.MaKho = kv.MaKho
JOIN dbo.LO_HANG lo ON lo.MaLo = bd.MaLo
JOIN dbo.SAN_PHAM sp ON sp.MaSP = lo.MaSP
JOIN dbo.CT_PHIEU_NHAP ct ON ct.MaPN = lo.MaPN AND ct.MaSP = lo.MaSP;
GO
