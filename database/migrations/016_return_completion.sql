-- Migration giữ nguyên SQL trước khi gom file; nội dung :r đã được đưa trực tiếp vào đây.
:ON ERROR EXIT
CREATE OR ALTER PROCEDURE dbo.sp_HoanTatTraHang
    @MaPTH CHAR(6),
    @MaTK CHAR(6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TrangThai NVARCHAR(20);
        DECLARE @MaPX CHAR(6);
        SELECT @TrangThai = TrangThai, @MaPX = MaPX
        FROM dbo.PHIEU_TRA_HANG WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPTH = @MaPTH;
        IF @TrangThai IS NULL
            THROW 51501, N'Phiếu trả không tồn tại.', 1;
        IF @TrangThai <> N'NHAP'
            THROW 51502, N'Phiếu trả không còn là nháp.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.CT_PHIEU_TRA_HANG WHERE MaPTH = @MaPTH)
            THROW 51503, N'Phiếu trả chưa có dòng.', 1;

        DECLARE @TrangThaiXuat NVARCHAR(20);
        SELECT @TrangThaiXuat = TrangThai
        FROM dbo.PHIEU_XUAT WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPX = @MaPX;
        IF @TrangThaiXuat <> N'DA_HOAN_THANH'
            THROW 51504, N'Phiếu xuất gốc chưa hoàn tất.', 1;

        IF EXISTS (
            SELECT 1 FROM dbo.CT_PHIEU_TRA_HANG line
            OUTER APPLY (
                SELECT SUM(CONVERT(BIGINT, SoLuong)) AS SoLuongXuat
                FROM dbo.CT_PHIEU_XUAT
                WHERE MaPX = @MaPX AND MaLo = line.MaLo
            ) exported
            OUTER APPLY (
                SELECT SUM(CONVERT(BIGINT, previousLine.SoLuong)) AS SoLuongDaTra
                FROM dbo.PHIEU_TRA_HANG previousDoc
                JOIN dbo.CT_PHIEU_TRA_HANG previousLine
                    ON previousLine.MaPTH = previousDoc.MaPTH
                WHERE previousDoc.MaPX = @MaPX
                  AND previousDoc.TrangThai = N'DA_HOAN_THANH'
                  AND previousLine.MaLo = line.MaLo
            ) returned
            WHERE line.MaPTH = @MaPTH
              AND (exported.SoLuongXuat IS NULL
                   OR ISNULL(returned.SoLuongDaTra, 0) + line.SoLuong > exported.SoLuongXuat)
        )
            THROW 51505, N'Lô chưa xuất hoặc số trả cộng dồn vượt lượng xuất.', 1;

        DECLARE @MaViTri CHAR(6);
        DECLARE @LoaiViTri NVARCHAR(20);
        DECLARE positions CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT MaViTri FROM dbo.CT_PHIEU_TRA_HANG
            WHERE MaPTH = @MaPTH ORDER BY MaViTri;
        OPEN positions;
        FETCH NEXT FROM positions INTO @MaViTri;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @LoaiViTri = LoaiViTri
            FROM dbo.VI_TRI_KHO WITH (UPDLOCK, HOLDLOCK)
            WHERE MaViTri = @MaViTri;
            FETCH NEXT FROM positions INTO @MaViTri;
        END;
        CLOSE positions;
        DEALLOCATE positions;

        DECLARE @SoDongTon INT;
        SELECT @SoDongTon = COUNT(*) FROM dbo.TON_KHO WITH (UPDLOCK, HOLDLOCK)
        WHERE MaViTri IN (
            SELECT MaViTri FROM dbo.CT_PHIEU_TRA_HANG WHERE MaPTH = @MaPTH
        );

        IF EXISTS (
            SELECT 1 FROM dbo.CT_PHIEU_TRA_HANG line
            JOIN dbo.VI_TRI_KHO position ON position.MaViTri = line.MaViTri
            JOIN dbo.KHU_VUC area ON area.MaKhuVuc = position.MaKhuVuc
            JOIN dbo.LO_HANG lot ON lot.MaLo = line.MaLo
            JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
            JOIN dbo.LOAI_SAN_PHAM category ON category.MaLoai = product.MaLoai
            WHERE line.MaPTH = @MaPTH
              AND ((line.TinhTrang = N'Hư hỏng' AND position.LoaiViTri <> N'Hư hỏng')
                   OR (line.TinhTrang = N'Tốt' AND position.LoaiViTri = N'Hư hỏng')
                   OR (category.YeuCauBaoQuan IS NOT NULL
                       AND category.YeuCauBaoQuan <> area.LoaiKhuVuc))
        )
            THROW 51506, N'Tình trạng hàng hoặc bảo quản không phù hợp vị trí.', 1;

        SELECT line.MaViTri, line.MaLo, CONVERT(BIGINT, line.SoLuong) AS Delta
        INTO #Delta FROM dbo.CT_PHIEU_TRA_HANG line WHERE line.MaPTH = @MaPTH;
        SELECT pairs.MaViTri, pairs.MaLo,
               ISNULL(CONVERT(BIGINT, ton.SoLuongTon), 0) + ISNULL(delta.Delta, 0) AS SoLuongCuoi
        INTO #Final
        FROM (
            SELECT MaViTri, MaLo FROM dbo.TON_KHO
            WHERE MaViTri IN (SELECT MaViTri FROM #Delta)
            UNION
            SELECT MaViTri, MaLo FROM #Delta
        ) pairs
        LEFT JOIN dbo.TON_KHO ton
            ON ton.MaViTri = pairs.MaViTri AND ton.MaLo = pairs.MaLo
        LEFT JOIN #Delta delta
            ON delta.MaViTri = pairs.MaViTri AND delta.MaLo = pairs.MaLo;

        IF EXISTS (
            SELECT 1 FROM #Final final
            JOIN dbo.VI_TRI_KHO position ON position.MaViTri = final.MaViTri
            GROUP BY final.MaViTri, position.SucChua
            HAVING SUM(final.SoLuongCuoi) > position.SucChua
        )
            THROW 51507, N'Sức chứa vị trí trả không đủ.', 1;
        IF EXISTS (
            SELECT 1 FROM #Final final
            JOIN dbo.LO_HANG lot ON lot.MaLo = final.MaLo
            JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
            WHERE final.SoLuongCuoi > 0
            GROUP BY final.MaViTri
            HAVING COUNT(DISTINCT product.MaDVT) > 1
        )
            THROW 51508, N'Vị trí trả không được trộn đơn vị tính.', 1;

        UPDATE ton SET SoLuongTon = CONVERT(INT, final.SoLuongCuoi)
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
        SELECT N'TRA_HANG', @MaPTH, MaViTri, MaLo, CONVERT(INT, Delta), @NgayHoanTat
        FROM #Delta;
        UPDATE dbo.PHIEU_TRA_HANG
        SET TrangThai = N'DA_HOAN_THANH', NgayHoanTat = @NgayHoanTat
        WHERE MaPTH = @MaPTH;

        IF @MaTK IS NOT NULL
            INSERT INTO dbo.LICH_SU_THAO_TAC
                (MaTK, HanhDong, TenBang, MaBanGhi, DuLieuCu, DuLieuMoi)
            VALUES (@MaTK, N'COMPLETE', N'PHIEU_TRA_HANG', @MaPTH,
                N'{"trangThai":"NHAP"}', N'{"trangThai":"DA_HOAN_THANH"}');

        COMMIT TRANSACTION;
        SELECT RTRIM(@MaPTH) AS maPhieuTraHang, N'DA_HOAN_THANH' AS trangThai,
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
