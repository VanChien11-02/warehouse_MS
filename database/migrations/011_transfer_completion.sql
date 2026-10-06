:ON ERROR EXIT
IF OBJECT_ID(N'dbo.PHIEU_CHUYEN_KHO', N'U') IS NULL
    OR OBJECT_ID(N'dbo.BIEN_DONG_TON_KHO', N'U') IS NULL
    THROW 51713, N'Apply transfer and movement schema before completion procedure.', 1;
GO
:r database/programmability/procedures/transfer/sp_HoanTatChuyenKho.sql
