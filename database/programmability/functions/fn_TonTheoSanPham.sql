CREATE OR ALTER FUNCTION dbo.fn_TonTheoSanPham(@MaSP CHAR(6))
RETURNS BIGINT
AS
BEGIN
    DECLARE @SoLuong BIGINT;
    SELECT @SoLuong = COALESCE(SUM(CONVERT(BIGINT, ton.SoLuongTon)), 0)
    FROM dbo.TON_KHO ton
    JOIN dbo.LO_HANG lot ON lot.MaLo = ton.MaLo
    WHERE lot.MaSP = @MaSP;
    RETURN @SoLuong;
END;
GO
