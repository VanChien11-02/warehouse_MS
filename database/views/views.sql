-- Các views được gom theo loại; giữ nguyên tên và nội dung SQL.

-- vw_TonKhoChiTiet: Tra cứu tồn theo kho, khu vực, vị trí, sản phẩm và lô từ phiếu nhập đã hoàn tất.
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

-- vw_BienDongTonKhoChiTiet: Chi tiết sổ biến động kèm kho, sản phẩm và giá trị theo đơn giá nhập để báo cáo.
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

-- vw_ChenhLechKiemKe: Các dòng có chênh lệch số lượng trong phiếu kiểm kê đã hoàn tất.
CREATE OR ALTER VIEW dbo.vw_ChenhLechKiemKe
AS
SELECT countDoc.MaPKK, area.MaKho, countDoc.MaViTri,
       line.MaLo, lot.MaSP, product.TenSP,
       line.SoLuongHeThong, line.SoLuongThucTe,
       CONVERT(BIGINT, line.SoLuongThucTe) - line.SoLuongHeThong AS ChenhLech,
       line.LyDoChenhLech, countDoc.NgayHoanTat
FROM dbo.PHIEU_KIEM_KE countDoc
JOIN dbo.CT_KIEM_KE line ON line.MaPKK = countDoc.MaPKK
JOIN dbo.VI_TRI_KHO position ON position.MaViTri = countDoc.MaViTri
JOIN dbo.KHU_VUC area ON area.MaKhuVuc = position.MaKhuVuc
JOIN dbo.LO_HANG lot ON lot.MaLo = line.MaLo
JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
WHERE countDoc.TrangThai = N'DA_HOAN_THANH'
  AND line.SoLuongThucTe <> line.SoLuongHeThong;
GO

-- vw_TonKhoTheoSanPham: Tổng hợp tồn dương và giá trị tồn theo từng kho, sản phẩm và đơn vị tính.
CREATE OR ALTER VIEW dbo.vw_TonKhoTheoSanPham
AS
SELECT MaKho, TenKho, MaSP, TenSP, MaDVT,
       SUM(CONVERT(BIGINT, SoLuongTon)) AS SoLuongTon,
       SUM(CONVERT(DECIMAL(38,4), SoLuongTon * DonGiaNhap)) AS GiaTriTon
FROM dbo.vw_TonKhoChiTiet
WHERE SoLuongTon > 0
GROUP BY MaKho, TenKho, MaSP, TenSP, MaDVT;
GO

-- vw_LichSuNhapKho: Lịch sử lô nhập đã hoàn tất, số lượng và giá trị theo đơn giá nhập.
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

-- vw_LichSuXuatKho: Lịch sử dòng xuất đã hoàn tất, vị trí lấy hàng, số lượng và giá trị xuất.
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

-- Function cần vw_TonKhoChiTiet; view cảnh báo bên dưới cần fn_LoSapHetHan.
:r database/functions/functions.sql

-- vw_LoSapHetHan: Cảnh báo tồn sắp hết hạn trong 30 ngày, sử dụng fn_LoSapHetHan.
CREATE OR ALTER VIEW dbo.vw_LoSapHetHan
AS
SELECT MaKho, TenKho, MaViTri, TenViTri, MaLo, MaSP, TenSP,
       SoLuongTon, HanSuDung, SoNgayConLai
FROM dbo.fn_LoSapHetHan(30);
GO
