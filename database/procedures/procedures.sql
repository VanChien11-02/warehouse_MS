-- sp_HoanTatPhieuNhap: Hoàn tất nhập: kiểm tra phiếu, tạo lô, phân bổ vị trí và tăng tồn trong một transaction.
CREATE OR ALTER PROCEDURE dbo.sp_HoanTatPhieuNhap
    @MaPN CHAR(6),
    @PhanBoJson NVARCHAR(MAX),
    @MaTK CHAR(6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PhanBo TABLE (
        ThuTu INT NOT NULL PRIMARY KEY,
        MaSP NVARCHAR(4000) NULL,
        MaViTri NVARCHAR(4000) NULL,
        SoLuong INT NULL,
        NgaySanXuatText NVARCHAR(4000) NULL,
        HanSuDungText NVARCHAR(4000) NULL
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TrangThai NVARCHAR(20);
        DECLARE @MaNCC CHAR(6);
        SELECT @TrangThai = TrangThai, @MaNCC = MaNCC
        FROM dbo.PHIEU_NHAP WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPN = @MaPN;

        IF @TrangThai IS NULL
            THROW 51101, N'Phiếu nhập không tồn tại.', 1;
        IF @TrangThai <> N'NHAP'
            THROW 51102, N'Phiếu nhập không còn ở trạng thái nháp.', 1;

        IF @PhanBoJson IS NULL OR ISJSON(@PhanBoJson) <> 1
            OR LEFT(LTRIM(@PhanBoJson), 1) <> N'['
            THROW 51103, N'Phân bổ lô phải là JSON array.', 1;

        INSERT INTO @PhanBo (ThuTu, MaSP, MaViTri, SoLuong, NgaySanXuatText, HanSuDungText)
        SELECT CONVERT(INT, j.[key]),
               UPPER(LTRIM(RTRIM(JSON_VALUE(j.value, '$.maSanPham')))),
               UPPER(LTRIM(RTRIM(JSON_VALUE(j.value, '$.maViTri')))),
               TRY_CONVERT(INT, JSON_VALUE(j.value, '$.soLuong')),
               JSON_VALUE(j.value, '$.ngaySanXuat'),
               JSON_VALUE(j.value, '$.hanSuDung')
        FROM OPENJSON(@PhanBoJson) j;

        IF NOT EXISTS (SELECT 1 FROM @PhanBo)
            THROW 51103, N'Phân bổ lô không được rỗng.', 1;
        IF EXISTS (SELECT 1 FROM @PhanBo
                   WHERE MaSP IS NULL OR LEN(MaSP) NOT BETWEEN 1 AND 6
                      OR MaViTri IS NULL OR LEN(MaViTri) NOT BETWEEN 1 AND 6
                      OR SoLuong IS NULL OR SoLuong <= 0
                      OR (NgaySanXuatText IS NOT NULL
                          AND TRY_CONVERT(DATE, NgaySanXuatText, 23) IS NULL)
                      OR (HanSuDungText IS NOT NULL
                          AND TRY_CONVERT(DATE, HanSuDungText, 23) IS NULL)
                      OR (NgaySanXuatText IS NOT NULL AND HanSuDungText IS NOT NULL
                          AND TRY_CONVERT(DATE, HanSuDungText, 23)
                              < TRY_CONVERT(DATE, NgaySanXuatText, 23)))
            THROW 51104, N'Dữ liệu phân bổ lô không hợp lệ.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.CT_PHIEU_NHAP WHERE MaPN = @MaPN)
            THROW 51105, N'Phiếu nhập chưa có dòng sản phẩm.', 1;
        IF EXISTS (
            SELECT 1 FROM dbo.CT_PHIEU_NHAP ct
            LEFT JOIN dbo.NHA_CUNG_CAP_SAN_PHAM map
                ON map.MaNCC = @MaNCC AND map.MaSP = ct.MaSP
            WHERE ct.MaPN = @MaPN AND map.MaSP IS NULL
        )
            THROW 51106, N'Nhà cung cấp chưa liên kết với mọi sản phẩm.', 1;
        IF EXISTS (
            SELECT 1 FROM @PhanBo p
            LEFT JOIN dbo.CT_PHIEU_NHAP ct ON ct.MaPN = @MaPN AND ct.MaSP = p.MaSP
            WHERE ct.MaSP IS NULL
        )
            THROW 51107, N'Phân bổ có sản phẩm không thuộc phiếu nhập.', 1;
        IF EXISTS (
            SELECT 1 FROM dbo.CT_PHIEU_NHAP ct
            LEFT JOIN (
                SELECT MaSP, SUM(CONVERT(BIGINT, SoLuong)) AS TongSoLuong
                FROM @PhanBo GROUP BY MaSP
            ) p ON p.MaSP = ct.MaSP
            WHERE ct.MaPN = @MaPN AND ISNULL(p.TongSoLuong, 0) <> ct.SoLuong
        )
            THROW 51108, N'Tổng phân bổ lô phải bằng số lượng từng dòng nhập.', 1;

        DECLARE @SoViTri INT = (SELECT COUNT(DISTINCT MaViTri) FROM @PhanBo);
        DECLARE @SoViTriKhoa INT;
        SELECT @SoViTriKhoa = COUNT(*)
        FROM dbo.VI_TRI_KHO WITH (UPDLOCK, HOLDLOCK)
        WHERE MaViTri IN (SELECT MaViTri FROM @PhanBo);
        IF @SoViTriKhoa <> @SoViTri
            THROW 51109, N'Vị trí nhận hàng không tồn tại.', 1;

        IF EXISTS (
            SELECT 1 FROM @PhanBo p
            JOIN dbo.VI_TRI_KHO vt ON vt.MaViTri = p.MaViTri
            JOIN dbo.KHU_VUC kv ON kv.MaKhuVuc = vt.MaKhuVuc
            JOIN dbo.SAN_PHAM sp ON sp.MaSP = p.MaSP
            JOIN dbo.LOAI_SAN_PHAM loai ON loai.MaLoai = sp.MaLoai
            WHERE vt.LoaiViTri = N'Hư hỏng'
               OR (loai.YeuCauBaoQuan IS NOT NULL
                   AND loai.YeuCauBaoQuan <> kv.LoaiKhuVuc)
        )
            THROW 51110, N'Vị trí không phù hợp loại bảo quản hoặc hàng nhập.', 1;

        IF EXISTS (
            SELECT 1 FROM @PhanBo p
            JOIN dbo.SAN_PHAM sp ON sp.MaSP = p.MaSP
            GROUP BY p.MaViTri
            HAVING COUNT(DISTINCT sp.MaDVT) > 1
        )
            THROW 51111, N'Một vị trí không được trộn đơn vị tính.', 1;
        IF EXISTS (
            SELECT 1 FROM @PhanBo p
            JOIN dbo.SAN_PHAM incoming ON incoming.MaSP = p.MaSP
            JOIN dbo.TON_KHO ton WITH (UPDLOCK, HOLDLOCK)
                ON ton.MaViTri = p.MaViTri AND ton.SoLuongTon > 0
            JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo
            JOIN dbo.SAN_PHAM existing ON existing.MaSP = lo.MaSP
            WHERE incoming.MaDVT <> existing.MaDVT
        )
            THROW 51111, N'Một vị trí không được trộn đơn vị tính.', 1;

        IF EXISTS (
            SELECT 1 FROM (
                SELECT MaViTri, SUM(CONVERT(BIGINT, SoLuong)) AS SoLuongNhap
                FROM @PhanBo GROUP BY MaViTri
            ) p
            JOIN dbo.VI_TRI_KHO vt ON vt.MaViTri = p.MaViTri
            OUTER APPLY (
                SELECT ISNULL(SUM(CONVERT(BIGINT, ton.SoLuongTon)), 0) AS SoLuongHienCo
                FROM dbo.TON_KHO ton WITH (UPDLOCK, HOLDLOCK)
                WHERE ton.MaViTri = p.MaViTri
            ) ton
            WHERE p.SoLuongNhap + ton.SoLuongHienCo > vt.SucChua
        )
            THROW 51112, N'Sức chứa vị trí không đủ.', 1;

        DECLARE @ThuTu INT = -1;
        DECLARE @MaSP CHAR(6);
        DECLARE @MaViTri CHAR(6);
        DECLARE @SoLuong INT;
        DECLARE @NgaySanXuat DATE;
        DECLARE @HanSuDung DATE;
        DECLARE @SoTiepTheo INT;
        DECLARE @MaLo CHAR(6);
        DECLARE @NgayHoanTat DATETIME2(3) = SYSUTCDATETIME();

        WHILE EXISTS (SELECT 1 FROM @PhanBo WHERE ThuTu > @ThuTu)
        BEGIN
            SELECT TOP (1) @ThuTu = ThuTu, @MaSP = MaSP, @MaViTri = MaViTri,
                @SoLuong = SoLuong,
                @NgaySanXuat = TRY_CONVERT(DATE, NgaySanXuatText, 23),
                @HanSuDung = TRY_CONVERT(DATE, HanSuDungText, 23)
            FROM @PhanBo WHERE ThuTu > @ThuTu ORDER BY ThuTu;

            SELECT @SoTiepTheo = NEXT VALUE FOR dbo.SEQ_LO_HANG;
            IF @SoTiepTheo > 9999
                THROW 51113, N'Đã hết mã lô sáu ký tự.', 1;
            SET @MaLo = 'LO' + RIGHT('0000' + CONVERT(VARCHAR(10), @SoTiepTheo), 4);

            INSERT INTO dbo.LO_HANG
                (MaLo, MaPN, MaSP, NgaySanXuat, HanSuDung, SoLuongNhap)
            VALUES (@MaLo, @MaPN, @MaSP, @NgaySanXuat, @HanSuDung, @SoLuong);
            INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
            VALUES (@MaViTri, @MaLo, @SoLuong);
            INSERT INTO dbo.BIEN_DONG_TON_KHO
                (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
            VALUES (N'NHAP', @MaPN, @MaViTri, @MaLo, @SoLuong, @NgayHoanTat);
        END;

        UPDATE dbo.PHIEU_NHAP
        SET TrangThai = N'DA_HOAN_THANH', NgayHoanTat = @NgayHoanTat
        WHERE MaPN = @MaPN;

        IF @MaTK IS NOT NULL
            INSERT INTO dbo.LICH_SU_THAO_TAC
                (MaTK, HanhDong, TenBang, MaBanGhi, DuLieuCu, DuLieuMoi)
            VALUES (@MaTK, N'COMPLETE', N'PHIEU_NHAP', @MaPN,
                N'{"trangThai":"NHAP"}', N'{"trangThai":"DA_HOAN_THANH"}');

        COMMIT TRANSACTION;
        SELECT RTRIM(@MaPN) AS maPhieuNhap, N'DA_HOAN_THANH' AS trangThai,
            @NgayHoanTat AS ngayHoanTat;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- sp_HoanTatPhieuXuat: Hoàn tất xuất: kiểm tra FEFO, đủ tồn và trừ tồn; chặn ghi sổ lặp.
CREATE OR ALTER PROCEDURE dbo.sp_HoanTatPhieuXuat
    @MaPX CHAR(6),
    @NgayNghiepVu DATE,
    @MaTK CHAR(6) = NULL
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

        IF @MaTK IS NOT NULL
            INSERT INTO dbo.LICH_SU_THAO_TAC
                (MaTK, HanhDong, TenBang, MaBanGhi, DuLieuCu, DuLieuMoi)
            VALUES (@MaTK, N'COMPLETE', N'PHIEU_XUAT', @MaPX,
                N'{"trangThai":"NHAP"}', N'{"trangThai":"DA_HOAN_THANH"}');

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

-- sp_HoanTatChuyenKho: Hoàn tất chuyển: giảm tồn nguồn và tăng tồn đích nguyên tử, kiểm tra sức chứa.
CREATE OR ALTER PROCEDURE dbo.sp_HoanTatChuyenKho
    @MaPCK CHAR(6),
    @MaTK CHAR(6) = NULL
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

        IF @MaTK IS NOT NULL
            INSERT INTO dbo.LICH_SU_THAO_TAC
                (MaTK, HanhDong, TenBang, MaBanGhi, DuLieuCu, DuLieuMoi)
            VALUES (@MaTK, N'COMPLETE', N'PHIEU_CHUYEN_KHO', @MaPCK,
                N'{"trangThai":"NHAP"}', N'{"trangThai":"DA_HOAN_THANH"}');

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

-- sp_HoanTatKiemKe: Hoàn tất kiểm kê: đối chiếu snapshot và ghi điều chỉnh chênh lệch một lần.
CREATE OR ALTER PROCEDURE dbo.sp_HoanTatKiemKe
    @MaPKK CHAR(6),
    @MaTK CHAR(6) = NULL
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

        IF @MaTK IS NOT NULL
            INSERT INTO dbo.LICH_SU_THAO_TAC
                (MaTK, HanhDong, TenBang, MaBanGhi, DuLieuCu, DuLieuMoi)
            VALUES (@MaTK, N'COMPLETE', N'PHIEU_KIEM_KE', @MaPKK,
                N'{"trangThai":"NHAP"}', N'{"trangThai":"DA_HOAN_THANH"}');

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

-- sp_HoanTatTraHang: Hoàn tất trả hàng: kiểm tra lượng đã xuất, tình trạng hàng và nhập lại vị trí phù hợp.
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
