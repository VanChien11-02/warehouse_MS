:ON ERROR EXIT
IF OBJECT_ID(N'dbo.BIEN_DONG_TON_KHO', N'U') IS NOT NULL
    THROW 51707, N'Stock movements have already been migrated.', 1;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r database/schema/019_bien_dong_ton_kho.sql

IF EXISTS (
    SELECT 1 FROM dbo.LO_HANG lo
    JOIN dbo.PHIEU_NHAP pn ON pn.MaPN = lo.MaPN AND pn.TrangThai = N'DA_HOAN_THANH'
    LEFT JOIN dbo.TON_KHO ton ON ton.MaLo = lo.MaLo
    GROUP BY lo.MaLo
    HAVING COUNT(ton.MaViTri) <> 1
)
    THROW 51708, N'Cannot infer a unique original position for an existing lot.', 1;

INSERT INTO dbo.BIEN_DONG_TON_KHO
    (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
SELECT N'NHAP', lo.MaPN, ton.MaViTri, lo.MaLo, lo.SoLuongNhap, pn.NgayHoanTat
FROM dbo.LO_HANG lo
JOIN dbo.PHIEU_NHAP pn ON pn.MaPN = lo.MaPN AND pn.TrangThai = N'DA_HOAN_THANH'
JOIN dbo.TON_KHO ton ON ton.MaLo = lo.MaLo;

INSERT INTO dbo.BIEN_DONG_TON_KHO
    (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
SELECT N'XUAT', px.MaPX, ct.MaViTri, ct.MaLo, -ct.SoLuong, px.NgayHoanTat
FROM dbo.CT_PHIEU_XUAT ct
JOIN dbo.PHIEU_XUAT px ON px.MaPX = ct.MaPX AND px.TrangThai = N'DA_HOAN_THANH';

IF EXISTS (
    SELECT MaViTri, MaLo, SUM(CONVERT(BIGINT, SoLuongThayDoi)) AS SoLuong
    FROM dbo.BIEN_DONG_TON_KHO
    GROUP BY MaViTri, MaLo
    EXCEPT
    SELECT MaViTri, MaLo, CONVERT(BIGINT, SoLuongTon)
    FROM dbo.TON_KHO
)
    OR EXISTS (
    SELECT MaViTri, MaLo, CONVERT(BIGINT, SoLuongTon)
    FROM dbo.TON_KHO
    EXCEPT
    SELECT MaViTri, MaLo, SUM(CONVERT(BIGINT, SoLuongThayDoi))
    FROM dbo.BIEN_DONG_TON_KHO
    GROUP BY MaViTri, MaLo
)
    THROW 51709, N'Existing stock does not reconcile with posted documents.', 1;

COMMIT TRANSACTION;
GO
