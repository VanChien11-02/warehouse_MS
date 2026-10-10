CREATE TABLE dbo.[ROLE] (
    MaRole CHAR(6) NOT NULL CONSTRAINT PK_ROLE PRIMARY KEY,
    TenRole NVARCHAR(100) NOT NULL CONSTRAINT UQ_ROLE_TEN UNIQUE,
    MoTa NVARCHAR(500) NULL,
    CONSTRAINT CK_ROLE_TEN_NOT_BLANK CHECK (LEN(LTRIM(RTRIM(TenRole))) > 0)
);

INSERT INTO dbo.[ROLE] (MaRole, TenRole, MoTa) VALUES
    ('ADMIN', N'Admin', N'Quản trị hệ thống'),
    ('QLKHO', N'QuanLyKho', N'Quản lý kho và hoàn tất chứng từ'),
    ('NVKHO', N'NhanVienKho', N'Nhân viên vận hành kho'),
    ('KETOAN', N'KeToan', N'Kế toán và báo cáo');
