CREATE OR ALTER TRIGGER dbo.trg_TonKho_BaoVeViTri
ON dbo.TON_KHO
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(MaViTri) OR UPDATE(MaLo) OR UPDATE(SoLuongTon))
        RETURN;

    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT MaViTri FROM inserted) affected
        JOIN dbo.VI_TRI_KHO position WITH (UPDLOCK, HOLDLOCK)
            ON position.MaViTri = affected.MaViTri
        JOIN dbo.TON_KHO stock ON stock.MaViTri = affected.MaViTri
        GROUP BY affected.MaViTri, position.SucChua
        HAVING SUM(CONVERT(BIGINT, stock.SoLuongTon)) > position.SucChua
    )
        THROW 51822, N'Tổng tồn vượt sức chứa của vị trí.', 1;

    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT MaViTri FROM inserted) affected
        JOIN dbo.TON_KHO stock ON stock.MaViTri = affected.MaViTri
        JOIN dbo.LO_HANG lot ON lot.MaLo = stock.MaLo
        JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
        WHERE stock.SoLuongTon > 0
        GROUP BY affected.MaViTri
        HAVING COUNT(DISTINCT product.MaDVT) > 1
    )
        THROW 51823, N'Một vị trí không được trộn đơn vị tính của tồn dương.', 1;
END;
GO
