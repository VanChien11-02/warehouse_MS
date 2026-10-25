-- Migration giữ nguyên SQL trước khi gom file; nội dung :r đã được đưa trực tiếp vào đây.
:ON ERROR EXIT
IF OBJECT_ID(N'dbo.BIEN_DONG_TON_KHO', N'U') IS NOT NULL
    THROW 51707, N'Stock movements have already been migrated.', 1;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;
CREATE TABLE dbo.BIEN_DONG_TON_KHO (
    MaBienDong BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_BIEN_DONG_TON_KHO PRIMARY KEY,
    LoaiNghiepVu NVARCHAR(20) NOT NULL,
    MaChungTu CHAR(6) NOT NULL,
    MaViTri CHAR(6) NOT NULL,
    MaLo CHAR(6) NOT NULL,
    SoLuongThayDoi INT NOT NULL,
    NgayGhiSo DATETIME2(3) NOT NULL,
    CONSTRAINT FK_BIEN_DONG_TON_KHO_VI_TRI FOREIGN KEY (MaViTri)
        REFERENCES dbo.VI_TRI_KHO (MaViTri),
    CONSTRAINT FK_BIEN_DONG_TON_KHO_LO FOREIGN KEY (MaLo)
        REFERENCES dbo.LO_HANG (MaLo),
    CONSTRAINT CK_BIEN_DONG_TON_KHO_LOAI CHECK
        (LoaiNghiepVu IN (N'NHAP', N'XUAT', N'CHUYEN', N'KIEM_KE', N'TRA_HANG')),
    CONSTRAINT CK_BIEN_DONG_TON_KHO_SO_LUONG CHECK (SoLuongThayDoi <> 0),
    CONSTRAINT UQ_BIEN_DONG_TON_KHO_NGHIEP_VU UNIQUE
        (LoaiNghiepVu, MaChungTu, MaViTri, MaLo)
);
CREATE INDEX IX_BIEN_DONG_TON_KHO_NGAY
    ON dbo.BIEN_DONG_TON_KHO (NgayGhiSo, MaViTri, MaLo)
    INCLUDE (SoLuongThayDoi, LoaiNghiepVu);

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
