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
COMMIT TRANSACTION;
GO
