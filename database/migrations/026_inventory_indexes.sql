-- Migration giữ nguyên SQL trước khi gom file; nội dung :r đã được đưa trực tiếp vào đây.
:ON ERROR EXIT
IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.LO_HANG') AND name = N'IX_LO_HANG_SAN_PHAM_HAN')
    CREATE INDEX IX_LO_HANG_SAN_PHAM_HAN
        ON dbo.LO_HANG (MaSP, HanSuDung, MaLo)
        INCLUDE (MaPN);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.TON_KHO') AND name = N'IX_TON_KHO_LO_VI_TRI')
    CREATE INDEX IX_TON_KHO_LO_VI_TRI
        ON dbo.TON_KHO (MaLo, MaViTri)
        INCLUDE (SoLuongTon);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.PHIEU_NHAP') AND name = N'IX_PHIEU_NHAP_NGAY_MA')
    CREATE INDEX IX_PHIEU_NHAP_NGAY_MA
        ON dbo.PHIEU_NHAP (NgayNhap DESC, MaPN DESC)
        INCLUDE (MaNCC, TrangThai);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.PHIEU_XUAT') AND name = N'IX_PHIEU_XUAT_NGAY_MA')
    CREATE INDEX IX_PHIEU_XUAT_NGAY_MA
        ON dbo.PHIEU_XUAT (NgayXuat DESC, MaPX DESC)
        INCLUDE (MaDTNH, TrangThai);
GO
