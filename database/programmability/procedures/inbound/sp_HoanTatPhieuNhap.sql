CREATE OR ALTER PROCEDURE dbo.sp_HoanTatPhieuNhap
    @MaPN CHAR(6),
    @PhanBoJson NVARCHAR(MAX)
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
        END;

        DECLARE @NgayHoanTat DATETIME2(3) = SYSUTCDATETIME();
        UPDATE dbo.PHIEU_NHAP
        SET TrangThai = N'DA_HOAN_THANH', NgayHoanTat = @NgayHoanTat
        WHERE MaPN = @MaPN;

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
