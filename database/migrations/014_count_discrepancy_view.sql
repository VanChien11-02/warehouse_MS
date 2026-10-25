-- Migration giữ nguyên SQL trước khi gom file; nội dung :r đã được đưa trực tiếp vào đây.
:ON ERROR EXIT
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
