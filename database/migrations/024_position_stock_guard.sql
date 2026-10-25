-- Migration giữ nguyên SQL trước khi gom file; nội dung :r đã được đưa trực tiếp vào đây.
:ON ERROR EXIT
CREATE OR ALTER TRIGGER dbo.trg_ViTriKho_BaoVeTon
ON dbo.VI_TRI_KHO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(SucChua) OR UPDATE(MaKhuVuc) OR UPDATE(LoaiViTri))
        RETURN;

    IF EXISTS (
        SELECT 1
        FROM inserted currentPosition
        JOIN deleted previousPosition
            ON previousPosition.MaViTri = currentPosition.MaViTri
        OUTER APPLY (
            SELECT COALESCE(SUM(CONVERT(BIGINT, stock.SoLuongTon)), 0) AS SoLuongTon
            FROM dbo.TON_KHO stock
            WHERE stock.MaViTri = currentPosition.MaViTri
        ) inventory
        WHERE currentPosition.SucChua < inventory.SoLuongTon
           OR (inventory.SoLuongTon > 0
               AND (currentPosition.MaKhuVuc <> previousPosition.MaKhuVuc
                    OR currentPosition.LoaiViTri <> previousPosition.LoaiViTri))
    )
        THROW 52101, N'Vị trí có tồn không thể giảm sức chứa dưới tồn hoặc đổi khu vực/loại.', 1;
END;
GO
