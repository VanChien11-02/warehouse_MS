CREATE OR ALTER TRIGGER dbo.trg_CtPhieuNhap_GioiHanLo
ON dbo.CT_PHIEU_NHAP
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(SoLuong)
        RETURN;

    IF EXISTS (
        SELECT 1
        FROM inserted line
        JOIN dbo.LO_HANG lot
            ON lot.MaPN = line.MaPN AND lot.MaSP = line.MaSP
        GROUP BY line.MaPN, line.MaSP, line.SoLuong
        HAVING SUM(CONVERT(BIGINT, lot.SoLuongNhap)) > line.SoLuong
    )
        THROW 51821, N'Số lượng dòng nhập nhỏ hơn tổng số lượng lô đã tạo.', 1;
END;
GO
