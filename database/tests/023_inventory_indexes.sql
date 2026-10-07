SET NOCOUNT ON;

IF (SELECT COUNT(*) FROM sys.indexes
    WHERE (object_id = OBJECT_ID(N'dbo.LO_HANG') AND name = N'IX_LO_HANG_SAN_PHAM_HAN')
       OR (object_id = OBJECT_ID(N'dbo.TON_KHO') AND name = N'IX_TON_KHO_LO_VI_TRI')
       OR (object_id = OBJECT_ID(N'dbo.PHIEU_NHAP') AND name = N'IX_PHIEU_NHAP_NGAY_MA')
       OR (object_id = OBJECT_ID(N'dbo.PHIEU_XUAT') AND name = N'IX_PHIEU_XUAT_NGAY_MA')) <> 4
    THROW 52120, N'Thiếu index tra cứu tồn/chứng từ.', 1;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes idx
    JOIN sys.index_columns col
        ON col.object_id = idx.object_id AND col.index_id = idx.index_id
    JOIN sys.columns columnInfo
        ON columnInfo.object_id = col.object_id AND columnInfo.column_id = col.column_id
    WHERE idx.object_id = OBJECT_ID(N'dbo.LO_HANG')
      AND idx.name = N'IX_LO_HANG_SAN_PHAM_HAN'
      AND columnInfo.name = N'MaSP' AND col.key_ordinal = 1
) OR NOT EXISTS (
    SELECT 1 FROM sys.indexes idx
    JOIN sys.index_columns col
        ON col.object_id = idx.object_id AND col.index_id = idx.index_id
    JOIN sys.columns columnInfo
        ON columnInfo.object_id = col.object_id AND columnInfo.column_id = col.column_id
    WHERE idx.object_id = OBJECT_ID(N'dbo.TON_KHO')
      AND idx.name = N'IX_TON_KHO_LO_VI_TRI'
      AND columnInfo.name = N'MaLo' AND col.key_ordinal = 1
)
    THROW 52121, N'Khóa đầu của index lô/tồn sai.', 1;

DECLARE @MaLo CHAR(6);
SELECT TOP (1) @MaLo = MaLo FROM dbo.LO_HANG
    WITH (INDEX(IX_LO_HANG_SAN_PHAM_HAN))
    WHERE MaSP = 'TST999' ORDER BY HanSuDung, MaLo;
SELECT TOP (1) @MaLo = MaLo FROM dbo.TON_KHO
    WITH (INDEX(IX_TON_KHO_LO_VI_TRI))
    WHERE MaLo = 'TST999';
SELECT TOP (1) @MaLo = MaPN FROM dbo.PHIEU_NHAP
    WITH (INDEX(IX_PHIEU_NHAP_NGAY_MA))
    ORDER BY NgayNhap DESC, MaPN DESC;
SELECT TOP (1) @MaLo = MaPX FROM dbo.PHIEU_XUAT
    WITH (INDEX(IX_PHIEU_XUAT_NGAY_MA))
    ORDER BY NgayXuat DESC, MaPX DESC;

PRINT N'Inventory indexes passed.';
