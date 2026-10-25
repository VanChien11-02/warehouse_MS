-- Các triggers được gom theo loại; giữ nguyên tên và nội dung SQL.

-- trg_ViTriKho_BaoVeTon: Chặn giảm sức chứa dưới tồn hoặc đổi khu vực, loại vị trí đang có tồn.
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

-- trg_LoHang_GioiHanPhanBo: Chặn tổng lượng lô của cùng dòng nhập vượt số lượng chi tiết phiếu nhập.
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

-- trg_LoaiSanPham_BaoVeBaoQuan: Giữ yêu cầu bảo quản của loại đã có lô để không đổi nghĩa hàng đã nhập.
CREATE OR ALTER TRIGGER dbo.trg_LoaiSanPham_BaoVeBaoQuan
ON dbo.LOAI_SAN_PHAM
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(YeuCauBaoQuan)
        RETURN;

    IF EXISTS (
        SELECT 1
        FROM inserted currentCategory
        JOIN deleted previousCategory ON previousCategory.MaLoai = currentCategory.MaLoai
        JOIN dbo.SAN_PHAM product ON product.MaLoai = currentCategory.MaLoai
        JOIN dbo.LO_HANG lot ON lot.MaSP = product.MaSP
        WHERE COALESCE(currentCategory.YeuCauBaoQuan, N'')
           <> COALESCE(previousCategory.YeuCauBaoQuan, N'')
    )
        THROW 51825, N'Không thể đổi yêu cầu bảo quản của loại sản phẩm đã phát sinh lô hàng.', 1;
END;
GO

-- trg_TonKho_BaoVeViTri: Chặn tồn vượt sức chứa và tồn dương khác đơn vị tính tại cùng vị trí.
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

-- trg_BienDongTonKho_DungChieu: Bảo đảm nhập, trả hàng tăng tồn và xuất giảm tồn; chuyển, kiểm kê cho phép hai chiều.
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
