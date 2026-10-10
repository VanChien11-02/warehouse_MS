:ON ERROR EXIT
IF OBJECT_ID(N'dbo.BIEN_DONG_TON_KHO', N'U') IS NULL
    THROW 51711, N'Apply stock movement schema before reporting view.', 1;
GO
:r database/programmability/views/vw_BienDongTonKhoChiTiet.sql
