CREATE OR ALTER PROCEDURE dbo.sp_HoanTatChuyenKho
    @MaPCK CHAR(6)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TrangThai NVARCHAR(20);
        SELECT @TrangThai = TrangThai
        FROM dbo.PHIEU_CHUYEN_KHO WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPCK = @MaPCK;

        IF @TrangThai IS NULL
            THROW 51301, N'Phiếu chuyển không tồn tại.', 1;
        IF @TrangThai <> N'NHAP'
            THROW 51302, N'Phiếu chuyển không còn ở trạng thái nháp.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.CT_PHIEU_CHUYEN_KHO WHERE MaPCK = @MaPCK)
            THROW 51303, N'Phiếu chuyển chưa có dòng.', 1;

        DECLARE @MaViTri CHAR(6);
        DECLARE @SucChua INT;
        DECLARE positions CURSOR LOCAL FAST_FORWARD FOR
            SELECT MaViTri FROM (
                SELECT MaViTriNguon AS MaViTri FROM dbo.CT_PHIEU_CHUYEN_KHO WHERE MaPCK = @MaPCK
                UNION
                SELECT MaViTriDich FROM dbo.CT_PHIEU_CHUYEN_KHO WHERE MaPCK = @MaPCK
            ) affected ORDER BY MaViTri;
        OPEN positions;
        FETCH NEXT FROM positions INTO @MaViTri;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SucChua = NULL;
            SELECT @SucChua = SucChua FROM dbo.VI_TRI_KHO WITH (UPDLOCK, HOLDLOCK)
                WHERE MaViTri = @MaViTri;
            IF @SucChua IS NULL
                THROW 51304, N'Vị trí chuyển không tồn tại.', 1;
            FETCH NEXT FROM positions INTO @MaViTri;
        END;
        CLOSE positions;
        DEALLOCATE positions;

        DECLARE @SoDongTon INT;
        SELECT @SoDongTon = COUNT(*) FROM dbo.TON_KHO WITH (UPDLOCK, HOLDLOCK)
        WHERE MaViTri IN (
            SELECT MaViTriNguon FROM dbo.CT_PHIEU_CHUYEN_KHO WHERE MaPCK = @MaPCK
            UNION
            SELECT MaViTriDich FROM dbo.CT_PHIEU_CHUYEN_KHO WHERE MaPCK = @MaPCK
        );

        IF EXISTS (
            SELECT 1 FROM dbo.CT_PHIEU_CHUYEN_KHO ct
            JOIN dbo.VI_TRI_KHO sourcePosition ON sourcePosition.MaViTri = ct.MaViTriNguon
            JOIN dbo.VI_TRI_KHO destinationPosition ON destinationPosition.MaViTri = ct.MaViTriDich
            JOIN dbo.KHU_VUC area ON area.MaKhuVuc = destinationPosition.MaKhuVuc
            JOIN dbo.LO_HANG lot ON lot.MaLo = ct.MaLo
            JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
            JOIN dbo.LOAI_SAN_PHAM category ON category.MaLoai = product.MaLoai
            WHERE ct.MaPCK = @MaPCK
              AND (sourcePosition.LoaiViTri = N'Hư hỏng'
                   OR destinationPosition.LoaiViTri = N'Hư hỏng'
                   OR (category.YeuCauBaoQuan IS NOT NULL
                       AND category.YeuCauBaoQuan <> area.LoaiKhuVuc))
        )
            THROW 51305, N'Vị trí nguồn/đích không phù hợp để chuyển lô.', 1;

        IF EXISTS (
            SELECT 1 FROM (
                SELECT MaViTriNguon, MaLo, SUM(CONVERT(BIGINT, SoLuong)) AS SoLuongCan
                FROM dbo.CT_PHIEU_CHUYEN_KHO WHERE MaPCK = @MaPCK
                GROUP BY MaViTriNguon, MaLo
            ) required
            LEFT JOIN dbo.TON_KHO ton ON ton.MaViTri = required.MaViTriNguon
                AND ton.MaLo = required.MaLo
            WHERE ton.MaLo IS NULL OR ton.SoLuongTon < required.SoLuongCan
        )
            THROW 51306, N'Tồn nguồn không đủ cho mọi dòng chuyển.', 1;

        SELECT MaViTri, MaLo, SUM(Delta) AS Delta
        INTO #Delta
        FROM (
            SELECT MaViTriNguon AS MaViTri, MaLo,
                   -CONVERT(BIGINT, SoLuong) AS Delta
            FROM dbo.CT_PHIEU_CHUYEN_KHO WHERE MaPCK = @MaPCK
            UNION ALL
            SELECT MaViTriDich, MaLo, CONVERT(BIGINT, SoLuong)
            FROM dbo.CT_PHIEU_CHUYEN_KHO WHERE MaPCK = @MaPCK
        ) movements
        GROUP BY MaViTri, MaLo;

        SELECT pairs.MaViTri, pairs.MaLo,
               ISNULL(CONVERT(BIGINT, ton.SoLuongTon), 0) + ISNULL(delta.Delta, 0) AS SoLuongCuoi
        INTO #Final
        FROM (
            SELECT MaViTri, MaLo FROM dbo.TON_KHO
            WHERE MaViTri IN (SELECT MaViTri FROM #Delta)
            UNION
            SELECT MaViTri, MaLo FROM #Delta
        ) pairs
        LEFT JOIN dbo.TON_KHO ton ON ton.MaViTri = pairs.MaViTri AND ton.MaLo = pairs.MaLo
        LEFT JOIN #Delta delta ON delta.MaViTri = pairs.MaViTri AND delta.MaLo = pairs.MaLo;

        IF EXISTS (SELECT 1 FROM #Final WHERE SoLuongCuoi < 0)
            THROW 51306, N'Tồn nguồn thay đổi trước khi ghi sổ.', 1;
        IF EXISTS (
            SELECT 1 FROM #Final final
            JOIN dbo.VI_TRI_KHO position ON position.MaViTri = final.MaViTri
            GROUP BY final.MaViTri, position.SucChua
            HAVING SUM(final.SoLuongCuoi) > position.SucChua
        )
            THROW 51307, N'Sức chứa vị trí đích không đủ.', 1;
        IF EXISTS (
            SELECT 1 FROM #Final final
            JOIN dbo.LO_HANG lot ON lot.MaLo = final.MaLo
            JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
            WHERE final.SoLuongCuoi > 0
            GROUP BY final.MaViTri
            HAVING COUNT(DISTINCT product.MaDVT) > 1
        )
            THROW 51308, N'Vị trí đích không được trộn đơn vị tính.', 1;

        UPDATE ton SET ton.SoLuongTon = CONVERT(INT, final.SoLuongCuoi)
        FROM dbo.TON_KHO ton
        JOIN #Final final ON final.MaViTri = ton.MaViTri AND final.MaLo = ton.MaLo;
        INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
        SELECT final.MaViTri, final.MaLo, CONVERT(INT, final.SoLuongCuoi)
        FROM #Final final
        WHERE final.SoLuongCuoi > 0
          AND NOT EXISTS (SELECT 1 FROM dbo.TON_KHO ton
              WHERE ton.MaViTri = final.MaViTri AND ton.MaLo = final.MaLo);

        DECLARE @NgayHoanTat DATETIME2(3) = SYSUTCDATETIME();
        INSERT INTO dbo.BIEN_DONG_TON_KHO
            (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
        SELECT N'CHUYEN', @MaPCK, delta.MaViTri, delta.MaLo,
               CONVERT(INT, delta.Delta), @NgayHoanTat
        FROM #Delta delta WHERE delta.Delta <> 0;

        UPDATE dbo.PHIEU_CHUYEN_KHO
        SET TrangThai = N'DA_HOAN_THANH', NgayHoanTat = @NgayHoanTat
        WHERE MaPCK = @MaPCK;

        COMMIT TRANSACTION;
        SELECT RTRIM(@MaPCK) AS maPhieuChuyen, N'DA_HOAN_THANH' AS trangThai,
            @NgayHoanTat AS ngayHoanTat;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'positions') >= 0 CLOSE positions;
        IF CURSOR_STATUS('local', 'positions') >= -1 DEALLOCATE positions;
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
