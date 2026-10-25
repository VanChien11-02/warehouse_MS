-- Migration giữ nguyên SQL trước khi gom file; nội dung :r đã được đưa trực tiếp vào đây.
:ON ERROR EXIT
IF DATABASE_PRINCIPAL_ID(N'wms_admin') IS NULL CREATE ROLE wms_admin;
IF DATABASE_PRINCIPAL_ID(N'wms_manager') IS NULL CREATE ROLE wms_manager;
IF DATABASE_PRINCIPAL_ID(N'wms_staff') IS NULL CREATE ROLE wms_staff;
IF DATABASE_PRINCIPAL_ID(N'wms_accountant') IS NULL CREATE ROLE wms_accountant;
GO

GRANT SELECT ON dbo.LOAI_SAN_PHAM TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.DON_VI_TINH TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.SAN_PHAM TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.NHA_CUNG_CAP TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.DOI_TAC_NHAN_HANG TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.KHO TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.KHU_VUC TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.VI_TRI_KHO TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.PHIEU_NHAP TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.CT_PHIEU_NHAP TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.PHIEU_XUAT TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.CT_PHIEU_XUAT TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.PHIEU_CHUYEN_KHO TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.CT_PHIEU_CHUYEN_KHO TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.PHIEU_KIEM_KE TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.CT_KIEM_KE TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.PHIEU_TRA_HANG TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.CT_PHIEU_TRA_HANG TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.vw_TonKhoChiTiet TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.vw_TonKhoTheoSanPham TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT SELECT ON dbo.vw_LoSapHetHan TO wms_admin, wms_manager, wms_staff;

GRANT SELECT ON dbo.vw_BienDongTonKhoChiTiet TO wms_admin, wms_manager, wms_accountant;
GRANT SELECT ON dbo.vw_LichSuNhapKho TO wms_admin, wms_manager, wms_accountant;
GRANT SELECT ON dbo.vw_LichSuXuatKho TO wms_admin, wms_manager, wms_accountant;
GRANT SELECT ON dbo.vw_ChenhLechKiemKe TO wms_admin, wms_manager, wms_accountant;
GRANT SELECT ON dbo.LICH_SU_THAO_TAC TO wms_admin;
GRANT SELECT ON dbo.NHAN_VIEN TO wms_admin;
GRANT SELECT ON OBJECT::dbo.TAI_KHOAN (MaTK, MaNV, MaRole, TenTK, TrangThai) TO wms_admin;

GRANT INSERT, UPDATE, DELETE ON dbo.LOAI_SAN_PHAM TO wms_admin, wms_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.DON_VI_TINH TO wms_admin, wms_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.SAN_PHAM TO wms_admin, wms_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.NHA_CUNG_CAP TO wms_admin, wms_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.DOI_TAC_NHAN_HANG TO wms_admin, wms_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.KHO TO wms_admin, wms_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.KHU_VUC TO wms_admin, wms_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.VI_TRI_KHO TO wms_admin, wms_manager;
GRANT INSERT, UPDATE ON dbo.PHIEU_NHAP TO wms_manager, wms_staff;
GRANT INSERT, UPDATE ON dbo.CT_PHIEU_NHAP TO wms_manager, wms_staff;
GRANT INSERT, UPDATE ON dbo.PHIEU_XUAT TO wms_manager, wms_staff;
GRANT INSERT, UPDATE ON dbo.CT_PHIEU_XUAT TO wms_manager, wms_staff;
GRANT INSERT, UPDATE ON dbo.PHIEU_CHUYEN_KHO TO wms_manager, wms_staff;
GRANT INSERT, UPDATE ON dbo.CT_PHIEU_CHUYEN_KHO TO wms_manager, wms_staff;
GRANT INSERT, UPDATE ON dbo.PHIEU_KIEM_KE TO wms_manager, wms_staff;
GRANT INSERT, UPDATE ON dbo.CT_KIEM_KE TO wms_manager, wms_staff;
GRANT INSERT, UPDATE ON dbo.PHIEU_TRA_HANG TO wms_manager, wms_staff;
GRANT INSERT, UPDATE ON dbo.CT_PHIEU_TRA_HANG TO wms_manager, wms_staff;
GRANT INSERT, UPDATE ON dbo.NHAN_VIEN TO wms_admin;
GRANT INSERT, UPDATE ON dbo.TAI_KHOAN TO wms_admin;

GRANT EXECUTE ON dbo.sp_HoanTatPhieuNhap TO wms_manager;
GRANT EXECUTE ON dbo.sp_HoanTatPhieuXuat TO wms_manager;
GRANT EXECUTE ON dbo.sp_HoanTatChuyenKho TO wms_manager;
GRANT EXECUTE ON dbo.sp_HoanTatKiemKe TO wms_manager;
GRANT EXECUTE ON dbo.sp_HoanTatTraHang TO wms_manager;
GRANT SELECT ON dbo.fn_LoSapHetHan TO wms_admin, wms_manager, wms_staff;
GRANT EXECUTE ON dbo.fn_TonTheoSanPham TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT EXECUTE ON dbo.fn_TonTheoLo TO wms_admin, wms_manager, wms_staff, wms_accountant;
GRANT EXECUTE ON dbo.fn_TonKhaDungTaiViTri TO wms_admin, wms_manager, wms_staff;
GRANT EXECUTE ON dbo.fn_GiaTriTonKho TO wms_admin, wms_manager, wms_accountant;

DENY SELECT ON dbo.LICH_SU_THAO_TAC TO wms_manager, wms_staff, wms_accountant;
DENY INSERT, UPDATE, DELETE ON dbo.LICH_SU_THAO_TAC
    TO wms_admin, wms_manager, wms_staff, wms_accountant;
DENY SELECT ON dbo.TAI_KHOAN TO wms_manager, wms_staff, wms_accountant;
DENY EXECUTE ON dbo.sp_HoanTatPhieuNhap TO wms_staff, wms_accountant;
DENY EXECUTE ON dbo.sp_HoanTatPhieuXuat TO wms_staff, wms_accountant;
DENY EXECUTE ON dbo.sp_HoanTatChuyenKho TO wms_staff, wms_accountant;
DENY EXECUTE ON dbo.sp_HoanTatKiemKe TO wms_staff, wms_accountant;
DENY EXECUTE ON dbo.sp_HoanTatTraHang TO wms_staff, wms_accountant;
GO
