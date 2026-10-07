SET NOCOUNT ON;
WAITFOR TIME '$(StartAt)';
DECLARE @NgayNghiepVu DATE = CONVERT(DATE,
    SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time');
BEGIN TRY
    EXEC dbo.sp_HoanTatPhieuXuat @MaPX = 'CNC002',
        @NgayNghiepVu = @NgayNghiepVu;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51208 THROW;
    PRINT N'CNC002 không đủ tồn sau phiên còn lại.';
END CATCH;
