CREATE OR ALTER PROCEDURE dbo.sp_HoanTatKiemKe
    @MaPKK CHAR(6)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TrangThai NVARCHAR(20);
        DECLARE @MaViTri CHAR(6);
        SELECT @TrangThai = TrangThai, @MaViTri = MaViTri
        FROM dbo.PHIEU_KIEM_KE WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPKK = @MaPKK;

        IF @TrangThai IS NULL
            THROW 51401, N'Phiếu kiểm kê không tồn tại.', 1;
        IF @TrangThai <> N'NHAP'
            THROW 51402, N'Phiếu kiểm kê không còn ở trạng thái nháp.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.CT_KIEM_KE WHERE MaPKK = @MaPKK)
            THROW 51403, N'Phiếu kiểm kê chưa có dòng.', 1;

        DECLARE @SucChua INT;
        DECLARE @MaKhuVuc CHAR(6);
        SELECT @SucChua = SucChua, @MaKhuVuc = MaKhuVuc
        FROM dbo.VI_TRI_KHO WITH (UPDLOCK, HOLDLOCK)
        WHERE MaViTri = @MaViTri;

        DECLARE @SoDongTon INT;
        SELECT @SoDongTon = COUNT(*) FROM dbo.TON_KHO WITH (UPDLOCK, HOLDLOCK)
        WHERE MaViTri = @MaViTri;

        IF EXISTS (SELECT 1 FROM dbo.CT_KIEM_KE
                   WHERE MaPKK = @MaPKK AND SoLuongThucTe IS NULL)
            THROW 51404, N'Mọi dòng kiểm kê cần số lượng thực tế.', 1;
        IF EXISTS (SELECT 1 FROM dbo.CT_KIEM_KE
                   WHERE MaPKK = @MaPKK AND SoLuongThucTe <> SoLuongHeThong
                     AND NULLIF(LTRIM(RTRIM(LyDoChenhLech)), N'') IS NULL)
            THROW 51405, N'Dòng chênh lệch cần lý do.', 1;

        IF EXISTS (
            SELECT 1 FROM dbo.CT_KIEM_KE ct
            LEFT JOIN dbo.TON_KHO ton ON ton.MaViTri = @MaViTri AND ton.MaLo = ct.MaLo
            WHERE ct.MaPKK = @MaPKK
              AND ct.SoLuongHeThong <> ISNULL(ton.SoLuongTon, 0)
        ) OR EXISTS (
            SELECT 1 FROM dbo.TON_KHO ton
            WHERE ton.MaViTri = @MaViTri AND ton.SoLuongTon > 0
              AND NOT EXISTS (SELECT 1 FROM dbo.CT_KIEM_KE ct
                  WHERE ct.MaPKK = @MaPKK AND ct.MaLo = ton.MaLo)
        )
            THROW 51406, N'Tồn đã thay đổi sau snapshot; cần lập phiếu mới.', 1;

        IF (SELECT SUM(CONVERT(BIGINT, SoLuongThucTe))
            FROM dbo.CT_KIEM_KE WHERE MaPKK = @MaPKK) > @SucChua
            THROW 51407, N'Số đếm vượt sức chứa vị trí.', 1;
        IF EXISTS (
            SELECT 1 FROM dbo.CT_KIEM_KE ct
            JOIN dbo.LO_HANG lot ON lot.MaLo = ct.MaLo
            JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
            JOIN dbo.LOAI_SAN_PHAM category ON category.MaLoai = product.MaLoai
            JOIN dbo.KHU_VUC area ON area.MaKhuVuc = @MaKhuVuc
            WHERE ct.MaPKK = @MaPKK AND ct.SoLuongThucTe > 0
              AND category.YeuCauBaoQuan IS NOT NULL
              AND category.YeuCauBaoQuan <> area.LoaiKhuVuc
        )
            THROW 51408, N'Lô không phù hợp loại bảo quản của vị trí.', 1;
        IF (SELECT COUNT(DISTINCT product.MaDVT)
            FROM dbo.CT_KIEM_KE ct
            JOIN dbo.LO_HANG lot ON lot.MaLo = ct.MaLo
            JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
            WHERE ct.MaPKK = @MaPKK AND ct.SoLuongThucTe > 0) > 1
            THROW 51409, N'Vị trí không được trộn đơn vị tính.', 1;

        UPDATE ton SET SoLuongTon = ct.SoLuongThucTe
        FROM dbo.TON_KHO ton
        JOIN dbo.CT_KIEM_KE ct ON ct.MaLo = ton.MaLo AND ct.MaPKK = @MaPKK
        WHERE ton.MaViTri = @MaViTri;
        INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
        SELECT @MaViTri, ct.MaLo, ct.SoLuongThucTe
        FROM dbo.CT_KIEM_KE ct
        WHERE ct.MaPKK = @MaPKK AND ct.SoLuongThucTe > 0
          AND NOT EXISTS (SELECT 1 FROM dbo.TON_KHO ton
              WHERE ton.MaViTri = @MaViTri AND ton.MaLo = ct.MaLo);

        DECLARE @NgayHoanTat DATETIME2(3) = SYSUTCDATETIME();
        INSERT INTO dbo.BIEN_DONG_TON_KHO
            (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
        SELECT N'KIEM_KE', @MaPKK, @MaViTri, ct.MaLo,
               ct.SoLuongThucTe - ct.SoLuongHeThong, @NgayHoanTat
        FROM dbo.CT_KIEM_KE ct
        WHERE ct.MaPKK = @MaPKK AND ct.SoLuongThucTe <> ct.SoLuongHeThong;

        UPDATE dbo.PHIEU_KIEM_KE
        SET TrangThai = N'DA_HOAN_THANH', NgayHoanTat = @NgayHoanTat
        WHERE MaPKK = @MaPKK;

        COMMIT TRANSACTION;
        SELECT RTRIM(@MaPKK) AS maPhieuKiemKe, N'DA_HOAN_THANH' AS trangThai,
               @NgayHoanTat AS ngayHoanTat;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
