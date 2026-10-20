CREATE OR ALTER FUNCTION dbo.fn_GiaTriTonKho(@MaKho CHAR(6))
RETURNS DECIMAL(38,4)
AS
BEGIN
    DECLARE @GiaTri DECIMAL(38,4);
    SELECT @GiaTri = COALESCE(SUM(CONVERT(DECIMAL(38,4),
        stock.SoLuongTon * stock.DonGiaNhap)), 0)
    FROM dbo.vw_TonKhoChiTiet stock
    WHERE stock.MaKho = @MaKho;
    RETURN @GiaTri;
END;
GO
