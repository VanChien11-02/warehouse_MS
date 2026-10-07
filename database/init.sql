:ON ERROR EXIT
IF DB_ID(N'BlueStock') IS NOT NULL
    THROW 51000, N'Database BlueStock already exists.', 1;
GO

CREATE DATABASE BlueStock;
GO
USE BlueStock;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r database/schema/auth/001_role.sql
:r database/schema/auth/002_nhan_vien.sql
:r database/schema/auth/003_tai_khoan.sql
:r database/schema/001_loai_san_pham.sql
:r database/schema/002_don_vi_tinh.sql
:r database/schema/003_san_pham.sql
:r database/schema/004_kho.sql
:r database/schema/005_khu_vuc.sql
:r database/schema/006_vi_tri_kho.sql
:r database/schema/007_nha_cung_cap.sql
:r database/schema/008_doi_tac_nhan_hang.sql
:r database/schema/009_nha_cung_cap_san_pham.sql
:r database/schema/010_doi_tac_san_pham.sql
:r database/schema/011_phieu_nhap.sql
:r database/schema/012_ct_phieu_nhap.sql
:r database/schema/013_lo_hang.sql
:r database/schema/014_ton_kho.sql
:r database/schema/015_sequences.sql
:r database/schema/016_phieu_xuat.sql
:r database/schema/017_ct_phieu_xuat.sql
:r database/schema/018_outbound_sequence.sql
:r database/schema/019_bien_dong_ton_kho.sql
:r database/schema/020_phieu_chuyen_kho.sql
:r database/schema/021_ct_phieu_chuyen_kho.sql
:r database/schema/022_transfer_sequence.sql
:r database/schema/023_phieu_kiem_ke.sql
:r database/schema/024_ct_kiem_ke.sql
:r database/schema/025_count_sequence.sql
:r database/schema/026_phieu_tra_hang.sql
:r database/schema/027_ct_phieu_tra_hang.sql
:r database/schema/028_return_sequence.sql
:r database/schema/029_lich_su_thao_tac.sql
COMMIT TRANSACTION;
GO
:r database/programmability/procedures/inbound/sp_HoanTatPhieuNhap.sql
:r database/programmability/views/vw_TonKhoChiTiet.sql
:r database/programmability/procedures/outbound/sp_HoanTatPhieuXuat.sql
:r database/programmability/views/vw_BienDongTonKhoChiTiet.sql
:r database/programmability/procedures/transfer/sp_HoanTatChuyenKho.sql
:r database/programmability/procedures/count/sp_HoanTatKiemKe.sql
:r database/programmability/views/vw_ChenhLechKiemKe.sql
:r database/programmability/procedures/returning/sp_HoanTatTraHang.sql

:r database/programmability/functions/fn_TonTheoSanPham.sql
:r database/programmability/functions/fn_TonTheoLo.sql
:r database/programmability/functions/fn_TonKhaDungTaiViTri.sql
:r database/programmability/functions/fn_GiaTriTonKho.sql
:r database/programmability/functions/fn_LoSapHetHan.sql
:r database/programmability/views/vw_TonKhoTheoSanPham.sql
:r database/programmability/views/vw_LichSuNhapKho.sql
:r database/programmability/views/vw_LichSuXuatKho.sql
:r database/programmability/views/vw_LoSapHetHan.sql
