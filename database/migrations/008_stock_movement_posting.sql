-- Migration giữ nguyên SQL trước khi gom file; nội dung :r đã được đưa trực tiếp vào đây.
:ON ERROR EXIT
IF OBJECT_ID(N'dbo.BIEN_DONG_TON_KHO', N'U') IS NULL
    THROW 51710, N'Apply stock movement schema before posting procedures.', 1;
GO
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
