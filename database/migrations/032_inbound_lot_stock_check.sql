:ON ERROR EXIT
-- Kiểm tra tổng tồn lô mới trong transaction hoàn tất nhập; chạy sau migration 031.
-- CREATE OR ALTER cho phép chạy lại; không cập nhật dữ liệu chứng từ đã ghi sổ.
-- fn_TonTheoLo: Tổng số lượng tồn của một lô trên tất cả vị trí.
CREATE OR ALTER FUNCTION dbo.fn_TonTheoLo(@MaLo CHAR(6))
RETURNS BIGINT
AS
BEGIN
    DECLARE @SoLuong BIGINT;
    SELECT @SoLuong = COALESCE(SUM(CONVERT(BIGINT, SoLuongTon)), 0)
    FROM dbo.TON_KHO WHERE MaLo = @MaLo;
    RETURN @SoLuong;
END;
GO

-- sp_HoanTatPhieuNhap: Hoàn tất nhập: kiểm tra phiếu, tạo lô, phân bổ vị trí và tăng tồn trong một transaction.
CREATE OR ALTER PROCEDURE dbo.sp_HoanTatPhieuNhap
    @MaPN CHAR(6),
    @PhanBoJson NVARCHAR(MAX),
    @MaTK CHAR(6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TrangThai NVARCHAR(20), @MaNCC CHAR(6), @SoDaKhoa INT;
    DECLARE @PhanBo TABLE (
        ThuTu INT PRIMARY KEY, MaSP NVARCHAR(4000), MaViTri NVARCHAR(4000), SoLuong INT,
        NgaySanXuatText NVARCHAR(4000), HanSuDungText NVARCHAR(4000),
        NgaySanXuat DATE, HanSuDung DATE
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Khóa phiếu: chỉ phiếu nháp được ghi sổ, ngăn hoàn tất hai lần.
        SELECT @TrangThai = TrangThai, @MaNCC = MaNCC
        FROM dbo.PHIEU_NHAP WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPN = @MaPN;

        IF @TrangThai IS NULL
            THROW 51101, N'Phiếu nhập không tồn tại.', 1;
        IF @TrangThai <> N'NHAP'
            THROW 51102, N'Phiếu nhập không còn ở trạng thái nháp.', 1;

        -- 2. Đọc phân bổ từ UI; kiểm tra dữ liệu, sản phẩm và lượng nhập.
        IF @PhanBoJson IS NULL OR ISJSON(@PhanBoJson) <> 1 OR LEFT(LTRIM(@PhanBoJson), 1) <> N'['
            THROW 51103, N'Phân bổ lô phải là JSON array.', 1;

        INSERT INTO @PhanBo (ThuTu, MaSP, MaViTri, SoLuong, NgaySanXuatText, HanSuDungText)
        SELECT CONVERT(INT, j.[key]),
               UPPER(LTRIM(RTRIM(JSON_VALUE(j.value, '$.maSanPham')))),
               UPPER(LTRIM(RTRIM(JSON_VALUE(j.value, '$.maViTri')))),
               TRY_CONVERT(INT, JSON_VALUE(j.value, '$.soLuong')),
               JSON_VALUE(j.value, '$.ngaySanXuat'),
               JSON_VALUE(j.value, '$.hanSuDung')
        FROM OPENJSON(@PhanBoJson) j;

        UPDATE @PhanBo
        SET NgaySanXuat = TRY_CONVERT(DATE, NgaySanXuatText, 23),
            HanSuDung = TRY_CONVERT(DATE, HanSuDungText, 23);

        IF NOT EXISTS (SELECT 1 FROM @PhanBo)
            THROW 51103, N'Phân bổ lô không được rỗng.', 1;
        IF EXISTS (SELECT 1 FROM @PhanBo
                   WHERE MaSP IS NULL OR LEN(MaSP) NOT BETWEEN 1 AND 6
                      OR MaViTri IS NULL OR LEN(MaViTri) NOT BETWEEN 1 AND 6
                      OR SoLuong IS NULL OR SoLuong <= 0
                      OR (NgaySanXuatText IS NOT NULL AND NgaySanXuat IS NULL)
                      OR (HanSuDungText IS NOT NULL AND HanSuDung IS NULL)
                      OR HanSuDung < NgaySanXuat)
            THROW 51104, N'Dữ liệu phân bổ lô không hợp lệ.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.CT_PHIEU_NHAP WHERE MaPN = @MaPN)
            THROW 51105, N'Phiếu nhập chưa có dòng sản phẩm.', 1;
        IF EXISTS (
            SELECT 1 FROM dbo.CT_PHIEU_NHAP ct WHERE ct.MaPN = @MaPN
            AND NOT EXISTS (SELECT 1 FROM dbo.NHA_CUNG_CAP_SAN_PHAM
                            WHERE MaNCC = @MaNCC AND MaSP = ct.MaSP)
        )
            THROW 51106, N'Nhà cung cấp chưa liên kết với mọi sản phẩm.', 1;
        IF EXISTS (
            SELECT 1 FROM @PhanBo p
            WHERE NOT EXISTS (SELECT 1 FROM dbo.CT_PHIEU_NHAP WHERE MaPN = @MaPN AND MaSP = p.MaSP)
        )
            THROW 51107, N'Phân bổ có sản phẩm không thuộc phiếu nhập.', 1;
        IF EXISTS (
            SELECT 1 FROM dbo.CT_PHIEU_NHAP ct WHERE ct.MaPN = @MaPN
            AND ISNULL((SELECT SUM(CONVERT(BIGINT, SoLuong)) FROM @PhanBo WHERE MaSP = ct.MaSP), 0) < ct.SoLuong
        )
            THROW 51108, N'Chưa phân bổ đủ số lượng từng dòng nhập.', 1;

        -- 3. Giữ khóa loại và vị trí đến cuối transaction, rồi kiểm tra nơi nhận.
        SELECT @SoDaKhoa = COUNT(*)
        FROM dbo.LOAI_SAN_PHAM loai WITH (HOLDLOCK)
        WHERE EXISTS (
            SELECT 1 FROM @PhanBo p
            JOIN dbo.SAN_PHAM sp ON sp.MaSP = p.MaSP
            WHERE sp.MaLoai = loai.MaLoai
        );

        SELECT @SoDaKhoa = COUNT(*)
        FROM dbo.VI_TRI_KHO WITH (UPDLOCK, HOLDLOCK)
        WHERE MaViTri IN (SELECT MaViTri FROM @PhanBo);
        IF @SoDaKhoa <> (SELECT COUNT(DISTINCT MaViTri) FROM @PhanBo)
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
            SELECT 1 FROM (
                SELECT p.MaViTri, sp.MaDVT FROM @PhanBo p
                JOIN dbo.SAN_PHAM sp ON sp.MaSP = p.MaSP
                UNION ALL
                SELECT ton.MaViTri, sp.MaDVT FROM dbo.TON_KHO ton WITH (UPDLOCK, HOLDLOCK)
                JOIN dbo.LO_HANG lo ON lo.MaLo = ton.MaLo
                JOIN dbo.SAN_PHAM sp ON sp.MaSP = lo.MaSP
                WHERE ton.SoLuongTon > 0 AND ton.MaViTri IN (SELECT MaViTri FROM @PhanBo)
            ) donVi GROUP BY MaViTri HAVING COUNT(DISTINCT MaDVT) > 1
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

        -- 4. Mỗi phân bổ tạo một lô, tồn tại vị trí và một dòng sổ biến động.
        DECLARE @ThuTu INT = -1, @MaSP CHAR(6), @MaViTri CHAR(6), @SoLuong INT;
        DECLARE @NgaySanXuat DATE, @HanSuDung DATE, @SoTiepTheo INT, @MaLo CHAR(6);
        DECLARE @NgayHoanTat DATETIME2(3) = SYSUTCDATETIME();

        WHILE EXISTS (SELECT 1 FROM @PhanBo WHERE ThuTu > @ThuTu)
        BEGIN
            SELECT TOP (1) @ThuTu = ThuTu, @MaSP = MaSP, @MaViTri = MaViTri,
                @SoLuong = SoLuong, @NgaySanXuat = NgaySanXuat, @HanSuDung = HanSuDung
            FROM @PhanBo WHERE ThuTu > @ThuTu ORDER BY ThuTu;

            SELECT @SoTiepTheo = NEXT VALUE FOR dbo.SEQ_LO_HANG;
            IF @SoTiepTheo > 9999
                THROW 51113, N'Đã hết mã lô sáu ký tự.', 1;
            SET @MaLo = 'LO' + RIGHT('0000' + CONVERT(VARCHAR(10), @SoTiepTheo), 4);

            -- Trigger lô chặn tổng vượt dòng nhập ngay tại INSERT này (51820).
            INSERT INTO dbo.LO_HANG (MaLo, MaPN, MaSP, NgaySanXuat, HanSuDung, SoLuongNhap)
            VALUES (@MaLo, @MaPN, @MaSP, @NgaySanXuat, @HanSuDung, @SoLuong);
            INSERT INTO dbo.TON_KHO (MaViTri, MaLo, SoLuongTon)
            VALUES (@MaViTri, @MaLo, @SoLuong);

            -- Lô vừa nhập phải có tổng tồn đúng bằng lượng phân bổ trước khi ghi sổ.
            IF dbo.fn_TonTheoLo(@MaLo) <> @SoLuong
                THROW 51114, N'Tổng tồn của lô mới không khớp số lượng nhập.', 1;

            INSERT INTO dbo.BIEN_DONG_TON_KHO
                (LoaiNghiepVu, MaChungTu, MaViTri, MaLo, SoLuongThayDoi, NgayGhiSo)
            VALUES (N'NHAP', @MaPN, @MaViTri, @MaLo, @SoLuong, @NgayHoanTat);
        END;

        -- 5. Đánh dấu hoàn tất, ghi người thao tác; chỉ COMMIT khi mọi bước thành công.
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
        -- Lỗi ở bất kỳ bước nào: hủy toàn bộ ghi sổ, trả lỗi để UI thông báo.
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
