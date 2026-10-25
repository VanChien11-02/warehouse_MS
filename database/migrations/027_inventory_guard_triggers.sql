-- Migration giữ nguyên SQL trước khi gom file; nội dung :r đã được đưa trực tiếp vào đây.
:ON ERROR EXIT
USE BlueStock;
GO
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
CREATE OR ALTER TRIGGER dbo.trg_BienDongTonKho_DungChieu
ON dbo.BIEN_DONG_TON_KHO
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(LoaiNghiepVu) OR UPDATE(SoLuongThayDoi))
        RETURN;

    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE (LoaiNghiepVu IN (N'NHAP', N'TRA_HANG') AND SoLuongThayDoi < 0)
           OR (LoaiNghiepVu = N'XUAT' AND SoLuongThayDoi > 0)
    )
        THROW 51824, N'Chiều biến động tồn không phù hợp loại nghiệp vụ.', 1;
END;
GO
