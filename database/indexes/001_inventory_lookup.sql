-- Toàn bộ index tường minh; PK và UNIQUE nằm trong constraints.sql.

-- IX_BIEN_DONG_TON_KHO_NGAY: Lọc biến động theo thời gian, vị trí và lô khi lập báo cáo nhập–xuất–tồn.
CREATE INDEX IX_BIEN_DONG_TON_KHO_NGAY
    ON dbo.BIEN_DONG_TON_KHO (NgayGhiSo, MaViTri, MaLo)
    INCLUDE (SoLuongThayDoi, LoaiNghiepVu);

-- IX_PHIEU_TRA_HANG_PX: Tra phiếu trả theo phiếu xuất gốc và trạng thái để kiểm tra lượng trả cộng dồn.
CREATE INDEX IX_PHIEU_TRA_HANG_PX ON dbo.PHIEU_TRA_HANG (MaPX, TrangThai);

-- IX_LICH_SU_THAO_TAC_THOI_GIAN: Tra audit mới nhất theo thời gian, tài khoản; kèm hành động, bảng và mã bản ghi.
CREATE INDEX IX_LICH_SU_THAO_TAC_THOI_GIAN
    ON dbo.LICH_SU_THAO_TAC (ThoiGian DESC, MaTK)
    INCLUDE (HanhDong, TenBang, MaBanGhi);

-- IX_DOI_SOAT_GIA_TRI_THOI_GIAN: Tra lịch sử đối soát mới nhất theo thời gian và tài khoản Kế toán.
CREATE INDEX IX_DOI_SOAT_GIA_TRI_THOI_GIAN
    ON dbo.DOI_SOAT_GIA_TRI (ThoiGian DESC, MaTKKeToan);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.LO_HANG') AND name = N'IX_LO_HANG_SAN_PHAM_HAN')
    -- IX_LO_HANG_SAN_PHAM_HAN: Lọc lô theo sản phẩm, hạn dùng và mã lô để gợi ý FEFO, báo cáo hạn.
    CREATE INDEX IX_LO_HANG_SAN_PHAM_HAN
        ON dbo.LO_HANG (MaSP, HanSuDung, MaLo)
        INCLUDE (MaPN);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.TON_KHO') AND name = N'IX_TON_KHO_LO_VI_TRI')
    -- IX_TON_KHO_LO_VI_TRI: Tra tồn từ lô sang vị trí; kèm số lượng để cộng tồn theo lô.
    CREATE INDEX IX_TON_KHO_LO_VI_TRI
        ON dbo.TON_KHO (MaLo, MaViTri)
        INCLUDE (SoLuongTon);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.PHIEU_NHAP') AND name = N'IX_PHIEU_NHAP_NGAY_MA')
    -- IX_PHIEU_NHAP_NGAY_MA: Phân trang phiếu nhập mới nhất theo ngày và mã; kèm nhà cung cấp, trạng thái.
    CREATE INDEX IX_PHIEU_NHAP_NGAY_MA
        ON dbo.PHIEU_NHAP (NgayNhap DESC, MaPN DESC)
        INCLUDE (MaNCC, TrangThai);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.PHIEU_XUAT') AND name = N'IX_PHIEU_XUAT_NGAY_MA')
    -- IX_PHIEU_XUAT_NGAY_MA: Phân trang phiếu xuất mới nhất theo ngày và mã; kèm đối tác nhận, trạng thái.
    CREATE INDEX IX_PHIEU_XUAT_NGAY_MA
        ON dbo.PHIEU_XUAT (NgayXuat DESC, MaPX DESC)
        INCLUDE (MaDTNH, TrangThai);
GO
