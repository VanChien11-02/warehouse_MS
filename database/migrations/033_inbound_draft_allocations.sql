:ON ERROR EXIT
-- Lưu các hàng phân bổ đang soạn, tách khỏi LO_HANG/TON_KHO chỉ tạo khi hoàn tất.
IF COL_LENGTH(N'dbo.PHIEU_NHAP', N'PhanBoNhapJson') IS NULL
    ALTER TABLE dbo.PHIEU_NHAP ADD PhanBoNhapJson NVARCHAR(MAX) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.PHIEU_NHAP')
      AND name = N'CK_PHIEU_NHAP_PHAN_BO_NHAP')
    ALTER TABLE dbo.PHIEU_NHAP ADD CONSTRAINT CK_PHIEU_NHAP_PHAN_BO_NHAP CHECK (
        PhanBoNhapJson IS NULL OR (ISJSON(PhanBoNhapJson) = 1
            AND LEFT(LTRIM(PhanBoNhapJson), 1) = N'[')
    );
GO
