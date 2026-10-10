CREATE OR ALTER VIEW dbo.vw_LoSapHetHan
AS
SELECT MaKho, TenKho, MaViTri, TenViTri, MaLo, MaSP, TenSP,
       SoLuongTon, HanSuDung, SoNgayConLai
FROM dbo.fn_LoSapHetHan(30);
GO
