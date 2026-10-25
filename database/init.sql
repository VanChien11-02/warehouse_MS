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
:r database/schema/016_phieu_xuat.sql
:r database/schema/017_ct_phieu_xuat.sql
:r database/schema/019_bien_dong_ton_kho.sql
:r database/schema/020_phieu_chuyen_kho.sql
:r database/schema/021_ct_phieu_chuyen_kho.sql
:r database/schema/023_phieu_kiem_ke.sql
:r database/schema/024_ct_kiem_ke.sql
:r database/schema/026_phieu_tra_hang.sql
:r database/schema/027_ct_phieu_tra_hang.sql
:r database/schema/029_lich_su_thao_tac.sql
:r database/schema/030_doi_soat_gia_tri.sql

-- Áp dụng ràng buộc sau khi mọi bảng đã tồn tại, trước khi commit schema.
:r database/constraints/constraints.sql
:r database/schema/015_sequences.sql
COMMIT TRANSACTION;
GO

-- views.sql nạp functions.sql sau view tồn chi tiết và trước view cảnh báo hạn.
:r database/views/views.sql
:r database/procedures/procedures.sql
:r database/triggers/triggers.sql
:r database/security/001_application_roles.sql
:r database/indexes/001_inventory_lookup.sql
