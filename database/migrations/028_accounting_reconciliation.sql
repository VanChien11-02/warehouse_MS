-- Migration giữ nguyên SQL trước khi gom file; nội dung :r đã được đưa trực tiếp vào đây.
:ON ERROR EXIT
USE BlueStock;
GO
IF OBJECT_ID(N'dbo.DOI_SOAT_GIA_TRI', N'U') IS NULL
BEGIN
CREATE TABLE dbo.DOI_SOAT_GIA_TRI (
    LoaiChungTu VARCHAR(4) NOT NULL,
    MaChungTu CHAR(6) NOT NULL,
    GiaTriChungTu DECIMAL(19,4) NOT NULL,
    GiaTriDoiSoat DECIMAL(19,4) NOT NULL,
    TrangThai VARCHAR(12) NOT NULL,
    GhiChu NVARCHAR(1000) NULL,
    MaTKKeToan CHAR(6) NOT NULL,
    ThoiGian DATETIME2(3) NOT NULL
        CONSTRAINT DF_DOI_SOAT_GIA_TRI_THOI_GIAN DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_DOI_SOAT_GIA_TRI PRIMARY KEY (LoaiChungTu, MaChungTu),
    CONSTRAINT FK_DOI_SOAT_GIA_TRI_TAI_KHOAN FOREIGN KEY (MaTKKeToan)
        REFERENCES dbo.TAI_KHOAN (MaTK),
    CONSTRAINT CK_DOI_SOAT_GIA_TRI_LOAI CHECK (LoaiChungTu IN ('NHAP', 'XUAT')),
    CONSTRAINT CK_DOI_SOAT_GIA_TRI_TRANG_THAI CHECK (TrangThai IN ('KHOP', 'CHENH_LECH')),
    CONSTRAINT CK_DOI_SOAT_GIA_TRI_GIA_TRI CHECK (GiaTriChungTu >= 0 AND GiaTriDoiSoat >= 0),
    CONSTRAINT CK_DOI_SOAT_GIA_TRI_KET_QUA CHECK (
        (TrangThai = 'KHOP' AND GiaTriChungTu = GiaTriDoiSoat)
        OR (TrangThai = 'CHENH_LECH' AND GiaTriChungTu <> GiaTriDoiSoat
            AND NULLIF(LTRIM(RTRIM(GhiChu)), N'') IS NOT NULL)
    )
);
CREATE INDEX IX_DOI_SOAT_GIA_TRI_THOI_GIAN
    ON dbo.DOI_SOAT_GIA_TRI (ThoiGian DESC, MaTKKeToan);
END
GO
-- Quyết định vai trò 2026-10-22: Admin chỉ quản trị định danh;
-- nhân viên kho chỉ lập phiếu nhập/xuất và tra cứu tồn.
REVOKE SELECT ON dbo.LOAI_SAN_PHAM FROM wms_admin;
REVOKE SELECT ON dbo.DON_VI_TINH FROM wms_admin;
REVOKE SELECT ON dbo.SAN_PHAM FROM wms_admin;
REVOKE SELECT ON dbo.NHA_CUNG_CAP FROM wms_admin;
REVOKE SELECT ON dbo.DOI_TAC_NHAN_HANG FROM wms_admin;
REVOKE SELECT ON dbo.KHO FROM wms_admin;
REVOKE SELECT ON dbo.KHU_VUC FROM wms_admin;
REVOKE SELECT ON dbo.VI_TRI_KHO FROM wms_admin;
REVOKE SELECT ON dbo.PHIEU_NHAP FROM wms_admin;
REVOKE SELECT ON dbo.CT_PHIEU_NHAP FROM wms_admin;
REVOKE SELECT ON dbo.PHIEU_XUAT FROM wms_admin;
REVOKE SELECT ON dbo.CT_PHIEU_XUAT FROM wms_admin;
REVOKE SELECT ON dbo.PHIEU_CHUYEN_KHO FROM wms_admin, wms_staff;
REVOKE SELECT ON dbo.CT_PHIEU_CHUYEN_KHO FROM wms_admin, wms_staff;
REVOKE SELECT ON dbo.PHIEU_KIEM_KE FROM wms_admin, wms_staff;
REVOKE SELECT ON dbo.CT_KIEM_KE FROM wms_admin, wms_staff;
REVOKE SELECT ON dbo.PHIEU_TRA_HANG FROM wms_admin, wms_staff;
REVOKE SELECT ON dbo.CT_PHIEU_TRA_HANG FROM wms_admin, wms_staff;
REVOKE SELECT ON dbo.vw_TonKhoChiTiet FROM wms_admin;
REVOKE SELECT ON dbo.vw_TonKhoTheoSanPham FROM wms_admin;
REVOKE SELECT ON dbo.vw_LoSapHetHan FROM wms_admin, wms_staff;
REVOKE SELECT ON dbo.vw_BienDongTonKhoChiTiet FROM wms_admin;
REVOKE SELECT ON dbo.vw_LichSuNhapKho FROM wms_admin;
REVOKE SELECT ON dbo.vw_LichSuXuatKho FROM wms_admin;
REVOKE SELECT ON dbo.vw_ChenhLechKiemKe FROM wms_admin;
REVOKE SELECT ON dbo.LICH_SU_THAO_TAC FROM wms_admin;

REVOKE INSERT, UPDATE, DELETE ON dbo.LOAI_SAN_PHAM FROM wms_admin;
REVOKE INSERT, UPDATE, DELETE ON dbo.DON_VI_TINH FROM wms_admin;
REVOKE INSERT, UPDATE, DELETE ON dbo.SAN_PHAM FROM wms_admin;
REVOKE INSERT, UPDATE, DELETE ON dbo.NHA_CUNG_CAP FROM wms_admin;
REVOKE INSERT, UPDATE, DELETE ON dbo.DOI_TAC_NHAN_HANG FROM wms_admin;
REVOKE INSERT, UPDATE, DELETE ON dbo.KHO FROM wms_admin;
REVOKE INSERT, UPDATE, DELETE ON dbo.KHU_VUC FROM wms_admin;
REVOKE INSERT, UPDATE, DELETE ON dbo.VI_TRI_KHO FROM wms_admin;
REVOKE INSERT, UPDATE ON dbo.PHIEU_CHUYEN_KHO FROM wms_staff;
REVOKE INSERT, UPDATE ON dbo.CT_PHIEU_CHUYEN_KHO FROM wms_staff;
REVOKE INSERT, UPDATE ON dbo.PHIEU_KIEM_KE FROM wms_staff;
REVOKE INSERT, UPDATE ON dbo.CT_KIEM_KE FROM wms_staff;
REVOKE INSERT, UPDATE ON dbo.PHIEU_TRA_HANG FROM wms_staff;
REVOKE INSERT, UPDATE ON dbo.CT_PHIEU_TRA_HANG FROM wms_staff;

REVOKE SELECT ON dbo.fn_LoSapHetHan FROM wms_admin, wms_staff;
REVOKE EXECUTE ON dbo.fn_TonTheoSanPham FROM wms_admin;
REVOKE EXECUTE ON dbo.fn_TonTheoLo FROM wms_admin;
REVOKE EXECUTE ON dbo.fn_TonKhaDungTaiViTri FROM wms_admin;
REVOKE EXECUTE ON dbo.fn_GiaTriTonKho FROM wms_admin;

GRANT SELECT ON dbo.DOI_SOAT_GIA_TRI TO wms_manager, wms_accountant;
GRANT INSERT ON dbo.DOI_SOAT_GIA_TRI TO wms_accountant;
DENY UPDATE, DELETE ON dbo.DOI_SOAT_GIA_TRI TO wms_admin, wms_manager, wms_staff, wms_accountant;
GO
