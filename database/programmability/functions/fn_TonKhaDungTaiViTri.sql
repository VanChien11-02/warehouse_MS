CREATE OR ALTER FUNCTION dbo.fn_TonKhaDungTaiViTri(@MaLo CHAR(6), @MaViTri CHAR(6))
RETURNS INT
AS
BEGIN
    DECLARE @SoLuong INT = 0;
    DECLARE @NgayNghiepVu DATE = CONVERT(DATE,
        SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time');
    SELECT @SoLuong = ton.SoLuongTon
    FROM dbo.TON_KHO ton
    JOIN dbo.VI_TRI_KHO position ON position.MaViTri = ton.MaViTri
    JOIN dbo.LO_HANG lot ON lot.MaLo = ton.MaLo
    WHERE ton.MaLo = @MaLo AND ton.MaViTri = @MaViTri
      AND position.LoaiViTri <> N'Hư hỏng'
      AND (lot.HanSuDung IS NULL OR lot.HanSuDung >= @NgayNghiepVu);
    RETURN @SoLuong;
END;
GO
