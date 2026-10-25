CREATE TABLE dbo.[ROLE] (
    MaRole CHAR(6) NOT NULL,
    TenRole NVARCHAR(100) NOT NULL,
    MoTa NVARCHAR(500) NULL
);

INSERT INTO dbo.[ROLE] (MaRole, TenRole, MoTa) VALUES
    ('ADMIN', N'Admin', N'Quản trị hệ thống'),
    ('QLKHO', N'QuanLyKho', N'Quản lý kho và hoàn tất chứng từ'),
    ('NVKHO', N'NhanVienKho', N'Nhân viên vận hành kho'),
    ('KETOAN', N'KeToan', N'Kế toán và báo cáo');
