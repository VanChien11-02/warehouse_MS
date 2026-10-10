:ON ERROR EXIT
IF OBJECT_ID(N'dbo.BIEN_DONG_TON_KHO', N'U') IS NULL
    THROW 51710, N'Apply stock movement schema before posting procedures.', 1;
GO
:r database/programmability/procedures/inbound/sp_HoanTatPhieuNhap.sql
:r database/programmability/procedures/outbound/sp_HoanTatPhieuXuat.sql
