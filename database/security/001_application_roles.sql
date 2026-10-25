-- Tạo role và quyền nền; phần cuối áp dụng điều chỉnh quyền ngày 2026-10-22.
-- Giữ nguyên thứ tự GRANT, DENY, REVOKE để bảo toàn quyền hiệu lực.
-- wms_admin: quản trị nhân viên và tài khoản theo quyền hiệu lực sau phần REVOKE cuối file.
IF DATABASE_PRINCIPAL_ID(N'wms_admin') IS NULL CREATE ROLE wms_admin;
-- wms_manager: quản lý danh mục, kho, chứng từ và thực thi các procedure hoàn tất.
IF DATABASE_PRINCIPAL_ID(N'wms_manager') IS NULL CREATE ROLE wms_manager;
-- wms_staff: tra cứu tồn và lập phiếu nhập/xuất nháp, không được tự hoàn tất chứng từ.
IF DATABASE_PRINCIPAL_ID(N'wms_staff') IS NULL CREATE ROLE wms_staff;
-- wms_accountant: đọc chứng từ, tồn, báo cáo và ghi kết quả đối soát giá trị.
IF DATABASE_PRINCIPAL_ID(N'wms_accountant') IS NULL CREATE ROLE wms_accountant;
GO

-- Quyền đọc nền; phần REVOKE cuối file thu hẹp lại theo chính sách ngày 2026-10-22.
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

-- Quyền ghi danh mục, phiếu nháp và định danh trước khi áp dụng điều chỉnh vai trò.
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

-- Chỉ Quản lý kho được ghi sổ qua năm procedure hoàn tất; function phục vụ tra cứu.
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

-- Chặn truy cập audit, thông tin tài khoản và hoàn tất chứng từ ở các role bị giới hạn.
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

-- Đồng bộ quyền hiện hành và cấp quyền đối soát cho Kế toán.
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
