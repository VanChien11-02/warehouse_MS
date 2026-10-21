CREATE OR ALTER TRIGGER dbo.trg_LoHang_GioiHanPhanBo
ON dbo.LO_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(MaPN) OR UPDATE(MaSP) OR UPDATE(SoLuongNhap))
        RETURN;

    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT MaPN, MaSP FROM inserted) affected
        JOIN dbo.CT_PHIEU_NHAP line
            ON line.MaPN = affected.MaPN AND line.MaSP = affected.MaSP
        JOIN dbo.LO_HANG lot
            ON lot.MaPN = affected.MaPN AND lot.MaSP = affected.MaSP
        GROUP BY affected.MaPN, affected.MaSP, line.SoLuong
        HAVING SUM(CONVERT(BIGINT, lot.SoLuongNhap)) > line.SoLuong
    )
        THROW 51820, N'Tổng số lượng lô vượt số lượng của dòng nhập.', 1;
END;
GO
