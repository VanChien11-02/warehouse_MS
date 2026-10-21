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
