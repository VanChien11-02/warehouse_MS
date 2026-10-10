CREATE OR ALTER PROCEDURE dbo.sp_HoanTatPhieuXuat
    @MaPX CHAR(6),
    @NgayNghiepVu DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TrangThai NVARCHAR(20);
        DECLARE @MaDTNH CHAR(6);
        SELECT @TrangThai = TrangThai, @MaDTNH = MaDTNH
        FROM dbo.PHIEU_XUAT WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPX = @MaPX;

        IF @TrangThai IS NULL
            THROW 51201, N'Phiếu xuất không tồn tại.', 1;
        IF @TrangThai <> N'NHAP'
            THROW 51202, N'Phiếu xuất không còn ở trạng thái nháp.', 1;
        IF @NgayNghiepVu IS NULL
            THROW 51203, N'Thiếu ngày nghiệp vụ.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.CT_PHIEU_XUAT WHERE MaPX = @MaPX)
            THROW 51204, N'Phiếu xuất chưa có dòng.', 1;

        DECLARE @SoViTri INT = (
            SELECT COUNT(DISTINCT MaViTri) FROM dbo.CT_PHIEU_XUAT WHERE MaPX = @MaPX
        );
        DECLARE @SoViTriKhoa INT;
        SELECT @SoViTriKhoa = COUNT(*)
        FROM dbo.VI_TRI_KHO WITH (UPDLOCK, HOLDLOCK)
        WHERE MaViTri IN (SELECT MaViTri FROM dbo.CT_PHIEU_XUAT WHERE MaPX = @MaPX);
        IF @SoViTriKhoa <> @SoViTri
            THROW 51205, N'Vị trí xuất không tồn tại.', 1;

        IF EXISTS (
            SELECT 1 FROM dbo.CT_PHIEU_XUAT ct
            JOIN dbo.LO_HANG lo ON lo.MaLo = ct.MaLo
            JOIN dbo.PHIEU_NHAP pn ON pn.MaPN = lo.MaPN
            JOIN dbo.VI_TRI_KHO vt ON vt.MaViTri = ct.MaViTri
            WHERE ct.MaPX = @MaPX
              AND (pn.TrangThai <> N'DA_HOAN_THANH'
                   OR vt.LoaiViTri = N'Hư hỏng'
                   OR (lo.HanSuDung IS NOT NULL AND lo.HanSuDung < @NgayNghiepVu))
        )
            THROW 51206, N'Lô hết hạn hoặc không thuộc tồn khả dụng.', 1;

        IF EXISTS (
            SELECT 1 FROM dbo.CT_PHIEU_XUAT ct
            JOIN dbo.LO_HANG lo ON lo.MaLo = ct.MaLo
            LEFT JOIN dbo.DOI_TAC_SAN_PHAM map
                ON map.MaDTNH = @MaDTNH AND map.MaSP = lo.MaSP
            WHERE ct.MaPX = @MaPX AND map.MaSP IS NULL
        )
            THROW 51207, N'Đối tác chưa liên kết với mọi sản phẩm.', 1;

        DECLARE @SoDong INT = (SELECT COUNT(*) FROM dbo.CT_PHIEU_XUAT WHERE MaPX = @MaPX);
        DECLARE @SoDongTon INT;
        SELECT @SoDongTon = COUNT(*)
        FROM dbo.CT_PHIEU_XUAT ct
        JOIN dbo.TON_KHO ton WITH (UPDLOCK, HOLDLOCK)
            ON ton.MaViTri = ct.MaViTri AND ton.MaLo = ct.MaLo
        WHERE ct.MaPX = @MaPX AND ton.SoLuongTon >= ct.SoLuong;
        IF @SoDongTon <> @SoDong
            THROW 51208, N'Tồn kho không đủ cho mọi dòng xuất.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.CT_PHIEU_XUAT selected
            JOIN dbo.LO_HANG selectedLot ON selectedLot.MaLo = selected.MaLo
            JOIN dbo.TON_KHO earlierStock WITH (UPDLOCK, HOLDLOCK) ON earlierStock.SoLuongTon > 0
            JOIN dbo.LO_HANG earlierLot ON earlierLot.MaLo = earlierStock.MaLo
                AND earlierLot.MaSP = selectedLot.MaSP
            JOIN dbo.PHIEU_NHAP earlierInbound ON earlierInbound.MaPN = earlierLot.MaPN
            JOIN dbo.VI_TRI_KHO earlierPosition ON earlierPosition.MaViTri = earlierStock.MaViTri
            LEFT JOIN dbo.CT_PHIEU_XUAT earlierAllocation
                ON earlierAllocation.MaPX = @MaPX
               AND earlierAllocation.MaLo = earlierStock.MaLo
               AND earlierAllocation.MaViTri = earlierStock.MaViTri
            WHERE selected.MaPX = @MaPX
              AND earlierInbound.TrangThai = N'DA_HOAN_THANH'
              AND earlierPosition.LoaiViTri <> N'Hư hỏng'
              AND (earlierLot.HanSuDung IS NULL OR earlierLot.HanSuDung >= @NgayNghiepVu)
              AND earlierStock.SoLuongTon > ISNULL(earlierAllocation.SoLuong, 0)
              AND (
                  (selectedLot.HanSuDung IS NULL AND earlierLot.HanSuDung IS NOT NULL)
                  OR (selectedLot.HanSuDung IS NOT NULL
                      AND earlierLot.HanSuDung < selectedLot.HanSuDung)
              )
        )
            THROW 51209, N'Phân bổ xuất không theo FEFO.', 1;

        UPDATE ton
        SET ton.SoLuongTon = ton.SoLuongTon - ct.SoLuong
        FROM dbo.TON_KHO ton
        JOIN dbo.CT_PHIEU_XUAT ct ON ct.MaViTri = ton.MaViTri AND ct.MaLo = ton.MaLo
        WHERE ct.MaPX = @MaPX AND ton.SoLuongTon >= ct.SoLuong;
        IF @@ROWCOUNT <> @SoDong
            THROW 51208, N'Tồn kho thay đổi trước khi ghi sổ.', 1;

        DECLARE @NgayHoanTat DATETIME2(3) = SYSUTCDATETIME();
        INSERT INTO dbo.BIEN_DONG_TON_KHO
            (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
        SELECT N'XUAT', @MaPX, ct.MaViTri, ct.MaLo, -ct.SoLuong, @NgayHoanTat
        FROM dbo.CT_PHIEU_XUAT ct WHERE ct.MaPX = @MaPX;
        UPDATE dbo.PHIEU_XUAT
        SET TrangThai = N'DA_HOAN_THANH', NgayHoanTat = @NgayHoanTat
        WHERE MaPX = @MaPX;

        COMMIT TRANSACTION;
        SELECT RTRIM(@MaPX) AS maPhieuXuat, N'DA_HOAN_THANH' AS trangThai,
            @NgayHoanTat AS ngayHoanTat;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
