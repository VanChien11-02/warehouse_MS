CREATE OR ALTER VIEW dbo.vw_TonKhoChiTiet
AS
SELECT ton.MaViTri, vt.TenViTri, vt.LoaiViTri,
       kv.MaKhuVuc, kv.TenKhuVuc, kv.LoaiKhuVuc,
       kho.MaKho, kho.TenKho,
       ton.MaLo, lo.MaSP, sp.TenSP, sp.MaDVT,
       ton.SoLuongTon, lo.NgaySanXuat, lo.HanSuDung,
       lo.MaPN, pn.NgayHoanTat, ct.DonGiaNhap
FROM dbo.TON_KHO ton
JOIN dbo.VI_TRI_KHO vt ON vt.MaViTri = ton.MaViTri
JOIN dbo.KHU_VUC kv ON kv.MaKhuVuc = vt.MaKhuVuc
JOIN dbo.KHO kho ON kho.MaKho = kv.MaKho
JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo
JOIN dbo.SAN_PHAM sp ON sp.MaSP = lo.MaSP
JOIN dbo.PHIEU_NHAP pn ON pn.MaPN = lo.MaPN
JOIN dbo.CT_PHIEU_NHAP ct ON ct.MaPN = lo.MaPN AND ct.MaSP = lo.MaSP
WHERE pn.TrangThai = N'DA_HOAN_THANH';
GO
