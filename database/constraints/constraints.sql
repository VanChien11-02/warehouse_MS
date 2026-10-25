-- Ràng buộc dùng cho database dựng mới: chạy sau toàn bộ CREATE TABLE.
-- Giữ nguyên tên, khóa, điều kiện và giá trị mặc định; chỉ chuyển vị trí khai báo.


-- ==================== dbo.[ROLE] ====================

-- PK_ROLE: Định danh duy nhất mỗi dòng bằng khóa chính (MaRole).
ALTER TABLE dbo.[ROLE] ADD CONSTRAINT PK_ROLE PRIMARY KEY (MaRole);

-- UQ_ROLE_TEN: Ngăn trùng lặp giá trị của khóa duy nhất (TenRole).
ALTER TABLE dbo.[ROLE] ADD CONSTRAINT UQ_ROLE_TEN UNIQUE (TenRole);

-- CK_ROLE_TEN_NOT_BLANK: Không cho phép giá trị rỗng hoặc chỉ chứa khoảng trắng.
ALTER TABLE dbo.[ROLE] ADD CONSTRAINT CK_ROLE_TEN_NOT_BLANK CHECK (LEN(LTRIM(RTRIM(TenRole))) > 0);


-- ==================== dbo.NHAN_VIEN ====================

-- PK_NHAN_VIEN: Định danh duy nhất mỗi dòng bằng khóa chính (MaNV).
ALTER TABLE dbo.NHAN_VIEN ADD CONSTRAINT PK_NHAN_VIEN PRIMARY KEY (MaNV);

-- DF_NHAN_VIEN_DANG_LAM: Cấp giá trị mặc định khi câu INSERT bỏ qua cột DangLamViec.
ALTER TABLE dbo.NHAN_VIEN ADD CONSTRAINT DF_NHAN_VIEN_DANG_LAM DEFAULT (1) FOR DangLamViec;

-- CK_NHAN_VIEN_TEN_NOT_BLANK: Không cho phép giá trị rỗng hoặc chỉ chứa khoảng trắng.
ALTER TABLE dbo.NHAN_VIEN ADD CONSTRAINT CK_NHAN_VIEN_TEN_NOT_BLANK CHECK (LEN(LTRIM(RTRIM(TenNV))) > 0);

-- CK_NHAN_VIEN_GIOI_TINH: Giới hạn giá trị giới tính theo danh mục hiện hành.
ALTER TABLE dbo.NHAN_VIEN ADD CONSTRAINT CK_NHAN_VIEN_GIOI_TINH CHECK (GioiTinh IN (N'Nam', N'Nữ', N'Khác'));

-- CK_NHAN_VIEN_LUONG: Không cho phép mức lương âm.
ALTER TABLE dbo.NHAN_VIEN ADD CONSTRAINT CK_NHAN_VIEN_LUONG CHECK (Luong >= 0);


-- ==================== dbo.TAI_KHOAN ====================

-- PK_TAI_KHOAN: Định danh duy nhất mỗi dòng bằng khóa chính (MaTK).
ALTER TABLE dbo.TAI_KHOAN ADD CONSTRAINT PK_TAI_KHOAN PRIMARY KEY (MaTK);

-- UQ_TAI_KHOAN_NHAN_VIEN: Ngăn trùng lặp giá trị của khóa duy nhất (MaNV).
ALTER TABLE dbo.TAI_KHOAN ADD CONSTRAINT UQ_TAI_KHOAN_NHAN_VIEN UNIQUE (MaNV);

-- UQ_TAI_KHOAN_TEN: Ngăn trùng lặp giá trị của khóa duy nhất (TenTK).
ALTER TABLE dbo.TAI_KHOAN ADD CONSTRAINT UQ_TAI_KHOAN_TEN UNIQUE (TenTK);

-- DF_TAI_KHOAN_TRANG_THAI: Cấp giá trị mặc định khi câu INSERT bỏ qua cột TrangThai.
ALTER TABLE dbo.TAI_KHOAN ADD CONSTRAINT DF_TAI_KHOAN_TRANG_THAI DEFAULT (1) FOR TrangThai;

-- FK_TAI_KHOAN_NHAN_VIEN: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.NHAN_VIEN.
ALTER TABLE dbo.TAI_KHOAN ADD CONSTRAINT FK_TAI_KHOAN_NHAN_VIEN FOREIGN KEY (MaNV)
        REFERENCES dbo.NHAN_VIEN (MaNV);

-- FK_TAI_KHOAN_ROLE: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.[ROLE].
ALTER TABLE dbo.TAI_KHOAN ADD CONSTRAINT FK_TAI_KHOAN_ROLE FOREIGN KEY (MaRole)
        REFERENCES dbo.[ROLE] (MaRole);

-- CK_TAI_KHOAN_TEN_NOT_BLANK: Không cho phép giá trị rỗng hoặc chỉ chứa khoảng trắng.
ALTER TABLE dbo.TAI_KHOAN ADD CONSTRAINT CK_TAI_KHOAN_TEN_NOT_BLANK CHECK (LEN(LTRIM(RTRIM(TenTK))) > 0);

-- CK_TAI_KHOAN_HASH_NOT_BLANK: Không cho phép giá trị rỗng hoặc chỉ chứa khoảng trắng.
ALTER TABLE dbo.TAI_KHOAN ADD CONSTRAINT CK_TAI_KHOAN_HASH_NOT_BLANK CHECK (LEN(LTRIM(RTRIM(MatKhauHash))) > 0);


-- ==================== dbo.LOAI_SAN_PHAM ====================

-- PK_LOAI_SAN_PHAM: Định danh duy nhất mỗi dòng bằng khóa chính (MaLoai).
ALTER TABLE dbo.LOAI_SAN_PHAM ADD CONSTRAINT PK_LOAI_SAN_PHAM PRIMARY KEY (MaLoai);

-- CK_LOAI_SAN_PHAM_BAO_QUAN: Giới hạn yêu cầu bảo quản ở các loại được hỗ trợ.
ALTER TABLE dbo.LOAI_SAN_PHAM ADD CONSTRAINT CK_LOAI_SAN_PHAM_BAO_QUAN
        CHECK (YeuCauBaoQuan IN (N'Khô', N'Mát', N'Đông lạnh'));


-- ==================== dbo.DON_VI_TINH ====================

-- PK_DON_VI_TINH: Định danh duy nhất mỗi dòng bằng khóa chính (MaDVT).
ALTER TABLE dbo.DON_VI_TINH ADD CONSTRAINT PK_DON_VI_TINH PRIMARY KEY (MaDVT);

-- UQ_DON_VI_TINH_TEN: Ngăn trùng lặp giá trị của khóa duy nhất (TenDVT).
ALTER TABLE dbo.DON_VI_TINH ADD CONSTRAINT UQ_DON_VI_TINH_TEN UNIQUE (TenDVT);


-- ==================== dbo.SAN_PHAM ====================

-- PK_SAN_PHAM: Định danh duy nhất mỗi dòng bằng khóa chính (MaSP).
ALTER TABLE dbo.SAN_PHAM ADD CONSTRAINT PK_SAN_PHAM PRIMARY KEY (MaSP);

-- DF_SAN_PHAM_GIA_NHAP: Cấp giá trị mặc định khi câu INSERT bỏ qua cột GiaNhapMacDinh.
ALTER TABLE dbo.SAN_PHAM ADD CONSTRAINT DF_SAN_PHAM_GIA_NHAP DEFAULT (0) FOR GiaNhapMacDinh;

-- DF_SAN_PHAM_GIA_BAN: Cấp giá trị mặc định khi câu INSERT bỏ qua cột GiaBanMacDinh.
ALTER TABLE dbo.SAN_PHAM ADD CONSTRAINT DF_SAN_PHAM_GIA_BAN DEFAULT (0) FOR GiaBanMacDinh;

-- FK_SAN_PHAM_LOAI: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.LOAI_SAN_PHAM.
ALTER TABLE dbo.SAN_PHAM ADD CONSTRAINT FK_SAN_PHAM_LOAI FOREIGN KEY (MaLoai)
        REFERENCES dbo.LOAI_SAN_PHAM (MaLoai);

-- FK_SAN_PHAM_DVT: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.DON_VI_TINH.
ALTER TABLE dbo.SAN_PHAM ADD CONSTRAINT FK_SAN_PHAM_DVT FOREIGN KEY (MaDVT)
        REFERENCES dbo.DON_VI_TINH (MaDVT);

-- CK_SAN_PHAM_GIA_NHAP: Không cho phép giá tiền âm.
ALTER TABLE dbo.SAN_PHAM ADD CONSTRAINT CK_SAN_PHAM_GIA_NHAP CHECK (GiaNhapMacDinh >= 0);

-- CK_SAN_PHAM_GIA_BAN: Không cho phép giá tiền âm.
ALTER TABLE dbo.SAN_PHAM ADD CONSTRAINT CK_SAN_PHAM_GIA_BAN CHECK (GiaBanMacDinh >= 0);


-- ==================== dbo.KHO ====================

-- PK_KHO: Định danh duy nhất mỗi dòng bằng khóa chính (MaKho).
ALTER TABLE dbo.KHO ADD CONSTRAINT PK_KHO PRIMARY KEY (MaKho);

-- UQ_KHO_TEN: Ngăn trùng lặp giá trị của khóa duy nhất (TenKho).
ALTER TABLE dbo.KHO ADD CONSTRAINT UQ_KHO_TEN UNIQUE (TenKho);


-- ==================== dbo.KHU_VUC ====================

-- PK_KHU_VUC: Định danh duy nhất mỗi dòng bằng khóa chính (MaKhuVuc).
ALTER TABLE dbo.KHU_VUC ADD CONSTRAINT PK_KHU_VUC PRIMARY KEY (MaKhuVuc);

-- FK_KHU_VUC_KHO: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.KHO.
ALTER TABLE dbo.KHU_VUC ADD CONSTRAINT FK_KHU_VUC_KHO FOREIGN KEY (MaKho)
        REFERENCES dbo.KHO (MaKho);

-- UQ_KHU_VUC_TEN: Ngăn trùng lặp giá trị của khóa duy nhất (MaKho, TenKhuVuc).
ALTER TABLE dbo.KHU_VUC ADD CONSTRAINT UQ_KHU_VUC_TEN UNIQUE (MaKho, TenKhuVuc);

-- CK_KHU_VUC_LOAI: Giới hạn loại khu vực theo điều kiện bảo quản được hỗ trợ.
ALTER TABLE dbo.KHU_VUC ADD CONSTRAINT CK_KHU_VUC_LOAI
        CHECK (LoaiKhuVuc IN (N'Khô', N'Mát', N'Đông lạnh'));


-- ==================== dbo.VI_TRI_KHO ====================

-- PK_VI_TRI_KHO: Định danh duy nhất mỗi dòng bằng khóa chính (MaViTri).
ALTER TABLE dbo.VI_TRI_KHO ADD CONSTRAINT PK_VI_TRI_KHO PRIMARY KEY (MaViTri);

-- FK_VI_TRI_KHO_KHU_VUC: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.KHU_VUC.
ALTER TABLE dbo.VI_TRI_KHO ADD CONSTRAINT FK_VI_TRI_KHO_KHU_VUC FOREIGN KEY (MaKhuVuc)
        REFERENCES dbo.KHU_VUC (MaKhuVuc);

-- UQ_VI_TRI_KHO_TEN: Ngăn trùng lặp giá trị của khóa duy nhất (MaKhuVuc, TenViTri).
ALTER TABLE dbo.VI_TRI_KHO ADD CONSTRAINT UQ_VI_TRI_KHO_TEN UNIQUE (MaKhuVuc, TenViTri);

-- CK_VI_TRI_KHO_SUC_CHUA: Không cho phép sức chứa vị trí âm.
ALTER TABLE dbo.VI_TRI_KHO ADD CONSTRAINT CK_VI_TRI_KHO_SUC_CHUA CHECK (SucChua >= 0);

-- CK_VI_TRI_KHO_LOAI: Giới hạn loại vị trí lưu trữ, lấy hàng hoặc hư hỏng.
ALTER TABLE dbo.VI_TRI_KHO ADD CONSTRAINT CK_VI_TRI_KHO_LOAI
        CHECK (LoaiViTri IN (N'Lưu trữ', N'Lấy hàng', N'Hư hỏng'));


-- ==================== dbo.NHA_CUNG_CAP ====================

-- PK_NHA_CUNG_CAP: Định danh duy nhất mỗi dòng bằng khóa chính (MaNCC).
ALTER TABLE dbo.NHA_CUNG_CAP ADD CONSTRAINT PK_NHA_CUNG_CAP PRIMARY KEY (MaNCC);

-- CK_NHA_CUNG_CAP_TEN_NOT_BLANK: Không cho phép giá trị rỗng hoặc chỉ chứa khoảng trắng.
ALTER TABLE dbo.NHA_CUNG_CAP ADD CONSTRAINT CK_NHA_CUNG_CAP_TEN_NOT_BLANK CHECK (LEN(LTRIM(RTRIM(TenNCC))) > 0);


-- ==================== dbo.DOI_TAC_NHAN_HANG ====================

-- PK_DOI_TAC_NHAN_HANG: Định danh duy nhất mỗi dòng bằng khóa chính (MaDTNH).
ALTER TABLE dbo.DOI_TAC_NHAN_HANG ADD CONSTRAINT PK_DOI_TAC_NHAN_HANG PRIMARY KEY (MaDTNH);

-- CK_DOI_TAC_NHAN_HANG_TEN_NOT_BLANK: Không cho phép giá trị rỗng hoặc chỉ chứa khoảng trắng.
ALTER TABLE dbo.DOI_TAC_NHAN_HANG ADD CONSTRAINT CK_DOI_TAC_NHAN_HANG_TEN_NOT_BLANK
        CHECK (LEN(LTRIM(RTRIM(TenDoiTac))) > 0);

-- CK_DOI_TAC_NHAN_HANG_LOAI_NOT_BLANK: Không cho phép giá trị rỗng hoặc chỉ chứa khoảng trắng.
ALTER TABLE dbo.DOI_TAC_NHAN_HANG ADD CONSTRAINT CK_DOI_TAC_NHAN_HANG_LOAI_NOT_BLANK
        CHECK (LEN(LTRIM(RTRIM(LoaiDoiTac))) > 0);


-- ==================== dbo.NHA_CUNG_CAP_SAN_PHAM ====================

-- PK_NHA_CUNG_CAP_SAN_PHAM: Định danh duy nhất mỗi dòng bằng khóa chính (MaNCC, MaSP).
ALTER TABLE dbo.NHA_CUNG_CAP_SAN_PHAM ADD CONSTRAINT PK_NHA_CUNG_CAP_SAN_PHAM PRIMARY KEY (MaNCC, MaSP);

-- FK_NCC_SP_NCC: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.NHA_CUNG_CAP.
ALTER TABLE dbo.NHA_CUNG_CAP_SAN_PHAM ADD CONSTRAINT FK_NCC_SP_NCC FOREIGN KEY (MaNCC)
        REFERENCES dbo.NHA_CUNG_CAP (MaNCC);

-- FK_NCC_SP_SP: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.SAN_PHAM.
ALTER TABLE dbo.NHA_CUNG_CAP_SAN_PHAM ADD CONSTRAINT FK_NCC_SP_SP FOREIGN KEY (MaSP)
        REFERENCES dbo.SAN_PHAM (MaSP);


-- ==================== dbo.DOI_TAC_SAN_PHAM ====================

-- PK_DOI_TAC_SAN_PHAM: Định danh duy nhất mỗi dòng bằng khóa chính (MaDTNH, MaSP).
ALTER TABLE dbo.DOI_TAC_SAN_PHAM ADD CONSTRAINT PK_DOI_TAC_SAN_PHAM PRIMARY KEY (MaDTNH, MaSP);

-- FK_DT_SP_DT: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.DOI_TAC_NHAN_HANG.
ALTER TABLE dbo.DOI_TAC_SAN_PHAM ADD CONSTRAINT FK_DT_SP_DT FOREIGN KEY (MaDTNH)
        REFERENCES dbo.DOI_TAC_NHAN_HANG (MaDTNH);

-- FK_DT_SP_SP: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.SAN_PHAM.
ALTER TABLE dbo.DOI_TAC_SAN_PHAM ADD CONSTRAINT FK_DT_SP_SP FOREIGN KEY (MaSP)
        REFERENCES dbo.SAN_PHAM (MaSP);


-- ==================== dbo.PHIEU_NHAP ====================

-- PK_PHIEU_NHAP: Định danh duy nhất mỗi dòng bằng khóa chính (MaPN).
ALTER TABLE dbo.PHIEU_NHAP ADD CONSTRAINT PK_PHIEU_NHAP PRIMARY KEY (MaPN);

-- DF_PHIEU_NHAP_NGAY: Cấp giá trị mặc định khi câu INSERT bỏ qua cột NgayNhap.
ALTER TABLE dbo.PHIEU_NHAP ADD CONSTRAINT DF_PHIEU_NHAP_NGAY DEFAULT (SYSUTCDATETIME()) FOR NgayNhap;

-- DF_PHIEU_NHAP_TRANG_THAI: Cấp giá trị mặc định khi câu INSERT bỏ qua cột TrangThai.
ALTER TABLE dbo.PHIEU_NHAP ADD CONSTRAINT DF_PHIEU_NHAP_TRANG_THAI DEFAULT (N'NHAP') FOR TrangThai;

-- FK_PHIEU_NHAP_NCC: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.NHA_CUNG_CAP.
ALTER TABLE dbo.PHIEU_NHAP ADD CONSTRAINT FK_PHIEU_NHAP_NCC FOREIGN KEY (MaNCC)
        REFERENCES dbo.NHA_CUNG_CAP (MaNCC);

-- FK_PHIEU_NHAP_NV: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.NHAN_VIEN.
ALTER TABLE dbo.PHIEU_NHAP ADD CONSTRAINT FK_PHIEU_NHAP_NV FOREIGN KEY (MaNV)
        REFERENCES dbo.NHAN_VIEN (MaNV);

-- CK_PHIEU_NHAP_TRANG_THAI: Chỉ nhận trạng thái nháp, đã hoàn thành hoặc đã hủy.
ALTER TABLE dbo.PHIEU_NHAP ADD CONSTRAINT CK_PHIEU_NHAP_TRANG_THAI
        CHECK (TrangThai IN (N'NHAP', N'DA_HOAN_THANH', N'DA_HUY'));

-- CK_PHIEU_NHAP_HOAN_TAT: Thời điểm hoàn tất chỉ có giá trị khi chứng từ đã hoàn thành.
ALTER TABLE dbo.PHIEU_NHAP ADD CONSTRAINT CK_PHIEU_NHAP_HOAN_TAT CHECK (
        (TrangThai = N'DA_HOAN_THANH' AND NgayHoanTat IS NOT NULL)
        OR (TrangThai <> N'DA_HOAN_THANH' AND NgayHoanTat IS NULL)
    );


-- ==================== dbo.CT_PHIEU_NHAP ====================

-- PK_CT_PHIEU_NHAP: Định danh duy nhất mỗi dòng bằng khóa chính (MaPN, MaSP).
ALTER TABLE dbo.CT_PHIEU_NHAP ADD CONSTRAINT PK_CT_PHIEU_NHAP PRIMARY KEY (MaPN, MaSP);

-- FK_CT_PHIEU_NHAP_PN: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.PHIEU_NHAP.
ALTER TABLE dbo.CT_PHIEU_NHAP ADD CONSTRAINT FK_CT_PHIEU_NHAP_PN FOREIGN KEY (MaPN)
        REFERENCES dbo.PHIEU_NHAP (MaPN);

-- FK_CT_PHIEU_NHAP_SP: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.SAN_PHAM.
ALTER TABLE dbo.CT_PHIEU_NHAP ADD CONSTRAINT FK_CT_PHIEU_NHAP_SP FOREIGN KEY (MaSP)
        REFERENCES dbo.SAN_PHAM (MaSP);

-- CK_CT_PHIEU_NHAP_SO_LUONG: Số lượng của dòng giao dịch hoặc lô phải lớn hơn 0.
ALTER TABLE dbo.CT_PHIEU_NHAP ADD CONSTRAINT CK_CT_PHIEU_NHAP_SO_LUONG CHECK (SoLuong > 0);

-- CK_CT_PHIEU_NHAP_DON_GIA: Không cho phép giá tiền âm.
ALTER TABLE dbo.CT_PHIEU_NHAP ADD CONSTRAINT CK_CT_PHIEU_NHAP_DON_GIA CHECK (DonGiaNhap >= 0);


-- ==================== dbo.LO_HANG ====================

-- PK_LO_HANG: Định danh duy nhất mỗi dòng bằng khóa chính (MaLo).
ALTER TABLE dbo.LO_HANG ADD CONSTRAINT PK_LO_HANG PRIMARY KEY (MaLo);

-- FK_LO_HANG_CT_PN: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.CT_PHIEU_NHAP.
ALTER TABLE dbo.LO_HANG ADD CONSTRAINT FK_LO_HANG_CT_PN FOREIGN KEY (MaPN, MaSP)
        REFERENCES dbo.CT_PHIEU_NHAP (MaPN, MaSP);

-- CK_LO_HANG_SO_LUONG: Số lượng của dòng giao dịch hoặc lô phải lớn hơn 0.
ALTER TABLE dbo.LO_HANG ADD CONSTRAINT CK_LO_HANG_SO_LUONG CHECK (SoLuongNhap > 0);

-- CK_LO_HANG_HAN: Hạn sử dụng không được trước ngày sản xuất khi có đủ hai ngày.
ALTER TABLE dbo.LO_HANG ADD CONSTRAINT CK_LO_HANG_HAN CHECK (
        NgaySanXuat IS NULL OR HanSuDung IS NULL OR HanSuDung >= NgaySanXuat
    );


-- ==================== dbo.TON_KHO ====================

-- PK_TON_KHO: Định danh duy nhất mỗi dòng bằng khóa chính (MaViTri, MaLo).
ALTER TABLE dbo.TON_KHO ADD CONSTRAINT PK_TON_KHO PRIMARY KEY (MaViTri, MaLo);

-- FK_TON_KHO_VI_TRI: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.VI_TRI_KHO.
ALTER TABLE dbo.TON_KHO ADD CONSTRAINT FK_TON_KHO_VI_TRI FOREIGN KEY (MaViTri)
        REFERENCES dbo.VI_TRI_KHO (MaViTri);

-- FK_TON_KHO_LO: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.LO_HANG.
ALTER TABLE dbo.TON_KHO ADD CONSTRAINT FK_TON_KHO_LO FOREIGN KEY (MaLo)
        REFERENCES dbo.LO_HANG (MaLo);

-- CK_TON_KHO_SO_LUONG: Không cho phép số tồn âm tại cặp vị trí và lô.
ALTER TABLE dbo.TON_KHO ADD CONSTRAINT CK_TON_KHO_SO_LUONG CHECK (SoLuongTon >= 0);


-- ==================== dbo.PHIEU_XUAT ====================

-- PK_PHIEU_XUAT: Định danh duy nhất mỗi dòng bằng khóa chính (MaPX).
ALTER TABLE dbo.PHIEU_XUAT ADD CONSTRAINT PK_PHIEU_XUAT PRIMARY KEY (MaPX);

-- DF_PHIEU_XUAT_NGAY: Cấp giá trị mặc định khi câu INSERT bỏ qua cột NgayXuat.
ALTER TABLE dbo.PHIEU_XUAT ADD CONSTRAINT DF_PHIEU_XUAT_NGAY DEFAULT (SYSUTCDATETIME()) FOR NgayXuat;

-- DF_PHIEU_XUAT_TRANG_THAI: Cấp giá trị mặc định khi câu INSERT bỏ qua cột TrangThai.
ALTER TABLE dbo.PHIEU_XUAT ADD CONSTRAINT DF_PHIEU_XUAT_TRANG_THAI DEFAULT (N'NHAP') FOR TrangThai;

-- FK_PHIEU_XUAT_DT: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.DOI_TAC_NHAN_HANG.
ALTER TABLE dbo.PHIEU_XUAT ADD CONSTRAINT FK_PHIEU_XUAT_DT FOREIGN KEY (MaDTNH)
        REFERENCES dbo.DOI_TAC_NHAN_HANG (MaDTNH);

-- FK_PHIEU_XUAT_NV: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.NHAN_VIEN.
ALTER TABLE dbo.PHIEU_XUAT ADD CONSTRAINT FK_PHIEU_XUAT_NV FOREIGN KEY (MaNV)
        REFERENCES dbo.NHAN_VIEN (MaNV);

-- CK_PHIEU_XUAT_TRANG_THAI: Chỉ nhận trạng thái nháp, đã hoàn thành hoặc đã hủy.
ALTER TABLE dbo.PHIEU_XUAT ADD CONSTRAINT CK_PHIEU_XUAT_TRANG_THAI
        CHECK (TrangThai IN (N'NHAP', N'DA_HOAN_THANH', N'DA_HUY'));

-- CK_PHIEU_XUAT_HOAN_TAT: Thời điểm hoàn tất chỉ có giá trị khi chứng từ đã hoàn thành.
ALTER TABLE dbo.PHIEU_XUAT ADD CONSTRAINT CK_PHIEU_XUAT_HOAN_TAT CHECK (
        (TrangThai = N'DA_HOAN_THANH' AND NgayHoanTat IS NOT NULL)
        OR (TrangThai <> N'DA_HOAN_THANH' AND NgayHoanTat IS NULL)
    );


-- ==================== dbo.CT_PHIEU_XUAT ====================

-- PK_CT_PHIEU_XUAT: Định danh duy nhất mỗi dòng bằng khóa chính (MaPX, MaLo, MaViTri).
ALTER TABLE dbo.CT_PHIEU_XUAT ADD CONSTRAINT PK_CT_PHIEU_XUAT PRIMARY KEY (MaPX, MaLo, MaViTri);

-- FK_CT_PHIEU_XUAT_PX: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.PHIEU_XUAT.
ALTER TABLE dbo.CT_PHIEU_XUAT ADD CONSTRAINT FK_CT_PHIEU_XUAT_PX FOREIGN KEY (MaPX)
        REFERENCES dbo.PHIEU_XUAT (MaPX);

-- FK_CT_PHIEU_XUAT_LO: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.LO_HANG.
ALTER TABLE dbo.CT_PHIEU_XUAT ADD CONSTRAINT FK_CT_PHIEU_XUAT_LO FOREIGN KEY (MaLo)
        REFERENCES dbo.LO_HANG (MaLo);

-- FK_CT_PHIEU_XUAT_VI_TRI: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.VI_TRI_KHO.
ALTER TABLE dbo.CT_PHIEU_XUAT ADD CONSTRAINT FK_CT_PHIEU_XUAT_VI_TRI FOREIGN KEY (MaViTri)
        REFERENCES dbo.VI_TRI_KHO (MaViTri);

-- CK_CT_PHIEU_XUAT_SO_LUONG: Số lượng của dòng giao dịch hoặc lô phải lớn hơn 0.
ALTER TABLE dbo.CT_PHIEU_XUAT ADD CONSTRAINT CK_CT_PHIEU_XUAT_SO_LUONG CHECK (SoLuong > 0);

-- CK_CT_PHIEU_XUAT_DON_GIA: Không cho phép giá tiền âm.
ALTER TABLE dbo.CT_PHIEU_XUAT ADD CONSTRAINT CK_CT_PHIEU_XUAT_DON_GIA CHECK (DonGiaXuat >= 0);


-- ==================== dbo.BIEN_DONG_TON_KHO ====================

-- PK_BIEN_DONG_TON_KHO: Định danh duy nhất mỗi dòng bằng khóa chính (MaBienDong).
ALTER TABLE dbo.BIEN_DONG_TON_KHO ADD CONSTRAINT PK_BIEN_DONG_TON_KHO PRIMARY KEY (MaBienDong);

-- FK_BIEN_DONG_TON_KHO_VI_TRI: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.VI_TRI_KHO.
ALTER TABLE dbo.BIEN_DONG_TON_KHO ADD CONSTRAINT FK_BIEN_DONG_TON_KHO_VI_TRI FOREIGN KEY (MaViTri)
        REFERENCES dbo.VI_TRI_KHO (MaViTri);

-- FK_BIEN_DONG_TON_KHO_LO: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.LO_HANG.
ALTER TABLE dbo.BIEN_DONG_TON_KHO ADD CONSTRAINT FK_BIEN_DONG_TON_KHO_LO FOREIGN KEY (MaLo)
        REFERENCES dbo.LO_HANG (MaLo);

-- CK_BIEN_DONG_TON_KHO_LOAI: Chỉ ghi sổ các loại nghiệp vụ nhập, xuất, chuyển, kiểm kê, trả hàng.
ALTER TABLE dbo.BIEN_DONG_TON_KHO ADD CONSTRAINT CK_BIEN_DONG_TON_KHO_LOAI CHECK
        (LoaiNghiepVu IN (N'NHAP', N'XUAT', N'CHUYEN', N'KIEM_KE', N'TRA_HANG'));

-- CK_BIEN_DONG_TON_KHO_SO_LUONG: Biến động phải làm thay đổi tồn, không ghi delta bằng 0.
ALTER TABLE dbo.BIEN_DONG_TON_KHO ADD CONSTRAINT CK_BIEN_DONG_TON_KHO_SO_LUONG CHECK (SoLuongThayDoi <> 0);

-- UQ_BIEN_DONG_TON_KHO_NGHIEP_VU: Ngăn trùng lặp giá trị của khóa duy nhất (LoaiNghiepVu, MaChungTu, MaViTri, MaLo).
ALTER TABLE dbo.BIEN_DONG_TON_KHO ADD CONSTRAINT UQ_BIEN_DONG_TON_KHO_NGHIEP_VU UNIQUE
        (LoaiNghiepVu, MaChungTu, MaViTri, MaLo);


-- ==================== dbo.PHIEU_CHUYEN_KHO ====================

-- PK_PHIEU_CHUYEN_KHO: Định danh duy nhất mỗi dòng bằng khóa chính (MaPCK).
ALTER TABLE dbo.PHIEU_CHUYEN_KHO ADD CONSTRAINT PK_PHIEU_CHUYEN_KHO PRIMARY KEY (MaPCK);

-- DF_PHIEU_CHUYEN_KHO_NGAY: Cấp giá trị mặc định khi câu INSERT bỏ qua cột NgayChuyen.
ALTER TABLE dbo.PHIEU_CHUYEN_KHO ADD CONSTRAINT DF_PHIEU_CHUYEN_KHO_NGAY DEFAULT (SYSUTCDATETIME()) FOR NgayChuyen;

-- DF_PHIEU_CHUYEN_KHO_TRANG_THAI: Cấp giá trị mặc định khi câu INSERT bỏ qua cột TrangThai.
ALTER TABLE dbo.PHIEU_CHUYEN_KHO ADD CONSTRAINT DF_PHIEU_CHUYEN_KHO_TRANG_THAI DEFAULT (N'NHAP') FOR TrangThai;

-- FK_PHIEU_CHUYEN_KHO_NV: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.NHAN_VIEN.
ALTER TABLE dbo.PHIEU_CHUYEN_KHO ADD CONSTRAINT FK_PHIEU_CHUYEN_KHO_NV FOREIGN KEY (MaNV)
        REFERENCES dbo.NHAN_VIEN (MaNV);

-- CK_PHIEU_CHUYEN_KHO_TRANG_THAI: Chỉ nhận trạng thái nháp, đã hoàn thành hoặc đã hủy.
ALTER TABLE dbo.PHIEU_CHUYEN_KHO ADD CONSTRAINT CK_PHIEU_CHUYEN_KHO_TRANG_THAI
        CHECK (TrangThai IN (N'NHAP', N'DA_HOAN_THANH', N'DA_HUY'));

-- CK_PHIEU_CHUYEN_KHO_HOAN_TAT: Thời điểm hoàn tất chỉ có giá trị khi chứng từ đã hoàn thành.
ALTER TABLE dbo.PHIEU_CHUYEN_KHO ADD CONSTRAINT CK_PHIEU_CHUYEN_KHO_HOAN_TAT CHECK (
        (TrangThai = N'DA_HOAN_THANH' AND NgayHoanTat IS NOT NULL)
        OR (TrangThai <> N'DA_HOAN_THANH' AND NgayHoanTat IS NULL)
    );


-- ==================== dbo.CT_PHIEU_CHUYEN_KHO ====================

-- PK_CT_PHIEU_CHUYEN_KHO: Định danh duy nhất mỗi dòng bằng khóa chính (MaPCK, MaLo, MaViTriNguon, MaViTriDich).
ALTER TABLE dbo.CT_PHIEU_CHUYEN_KHO ADD CONSTRAINT PK_CT_PHIEU_CHUYEN_KHO
        PRIMARY KEY (MaPCK, MaLo, MaViTriNguon, MaViTriDich);

-- FK_CT_PHIEU_CHUYEN_KHO_PCK: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.PHIEU_CHUYEN_KHO.
ALTER TABLE dbo.CT_PHIEU_CHUYEN_KHO ADD CONSTRAINT FK_CT_PHIEU_CHUYEN_KHO_PCK FOREIGN KEY (MaPCK)
        REFERENCES dbo.PHIEU_CHUYEN_KHO (MaPCK);

-- FK_CT_PHIEU_CHUYEN_KHO_LO: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.LO_HANG.
ALTER TABLE dbo.CT_PHIEU_CHUYEN_KHO ADD CONSTRAINT FK_CT_PHIEU_CHUYEN_KHO_LO FOREIGN KEY (MaLo)
        REFERENCES dbo.LO_HANG (MaLo);

-- FK_CT_PHIEU_CHUYEN_KHO_NGUON: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.VI_TRI_KHO.
ALTER TABLE dbo.CT_PHIEU_CHUYEN_KHO ADD CONSTRAINT FK_CT_PHIEU_CHUYEN_KHO_NGUON FOREIGN KEY (MaViTriNguon)
        REFERENCES dbo.VI_TRI_KHO (MaViTri);

-- FK_CT_PHIEU_CHUYEN_KHO_DICH: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.VI_TRI_KHO.
ALTER TABLE dbo.CT_PHIEU_CHUYEN_KHO ADD CONSTRAINT FK_CT_PHIEU_CHUYEN_KHO_DICH FOREIGN KEY (MaViTriDich)
        REFERENCES dbo.VI_TRI_KHO (MaViTri);

-- CK_CT_PHIEU_CHUYEN_KHO_SO_LUONG: Số lượng của dòng giao dịch hoặc lô phải lớn hơn 0.
ALTER TABLE dbo.CT_PHIEU_CHUYEN_KHO ADD CONSTRAINT CK_CT_PHIEU_CHUYEN_KHO_SO_LUONG CHECK (SoLuong > 0);

-- CK_CT_PHIEU_CHUYEN_KHO_VI_TRI: Vị trí nguồn và đích của một dòng chuyển phải khác nhau.
ALTER TABLE dbo.CT_PHIEU_CHUYEN_KHO ADD CONSTRAINT CK_CT_PHIEU_CHUYEN_KHO_VI_TRI CHECK (MaViTriNguon <> MaViTriDich);


-- ==================== dbo.PHIEU_KIEM_KE ====================

-- PK_PHIEU_KIEM_KE: Định danh duy nhất mỗi dòng bằng khóa chính (MaPKK).
ALTER TABLE dbo.PHIEU_KIEM_KE ADD CONSTRAINT PK_PHIEU_KIEM_KE PRIMARY KEY (MaPKK);

-- DF_PHIEU_KIEM_KE_NGAY: Cấp giá trị mặc định khi câu INSERT bỏ qua cột NgayKiemKe.
ALTER TABLE dbo.PHIEU_KIEM_KE ADD CONSTRAINT DF_PHIEU_KIEM_KE_NGAY DEFAULT (SYSUTCDATETIME()) FOR NgayKiemKe;

-- DF_PHIEU_KIEM_KE_TRANG_THAI: Cấp giá trị mặc định khi câu INSERT bỏ qua cột TrangThai.
ALTER TABLE dbo.PHIEU_KIEM_KE ADD CONSTRAINT DF_PHIEU_KIEM_KE_TRANG_THAI DEFAULT (N'NHAP') FOR TrangThai;

-- FK_PHIEU_KIEM_KE_NV: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.NHAN_VIEN.
ALTER TABLE dbo.PHIEU_KIEM_KE ADD CONSTRAINT FK_PHIEU_KIEM_KE_NV FOREIGN KEY (MaNV)
        REFERENCES dbo.NHAN_VIEN (MaNV);

-- FK_PHIEU_KIEM_KE_VI_TRI: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.VI_TRI_KHO.
ALTER TABLE dbo.PHIEU_KIEM_KE ADD CONSTRAINT FK_PHIEU_KIEM_KE_VI_TRI FOREIGN KEY (MaViTri)
        REFERENCES dbo.VI_TRI_KHO (MaViTri);

-- CK_PHIEU_KIEM_KE_TRANG_THAI: Chỉ nhận trạng thái nháp, đã hoàn thành hoặc đã hủy.
ALTER TABLE dbo.PHIEU_KIEM_KE ADD CONSTRAINT CK_PHIEU_KIEM_KE_TRANG_THAI
        CHECK (TrangThai IN (N'NHAP', N'DA_HOAN_THANH', N'DA_HUY'));

-- CK_PHIEU_KIEM_KE_HOAN_TAT: Thời điểm hoàn tất chỉ có giá trị khi chứng từ đã hoàn thành.
ALTER TABLE dbo.PHIEU_KIEM_KE ADD CONSTRAINT CK_PHIEU_KIEM_KE_HOAN_TAT CHECK (
        (TrangThai = N'DA_HOAN_THANH' AND NgayHoanTat IS NOT NULL)
        OR (TrangThai <> N'DA_HOAN_THANH' AND NgayHoanTat IS NULL)
    );


-- ==================== dbo.CT_KIEM_KE ====================

-- PK_CT_KIEM_KE: Định danh duy nhất mỗi dòng bằng khóa chính (MaPKK, MaLo).
ALTER TABLE dbo.CT_KIEM_KE ADD CONSTRAINT PK_CT_KIEM_KE PRIMARY KEY (MaPKK, MaLo);

-- FK_CT_KIEM_KE_PKK: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.PHIEU_KIEM_KE.
ALTER TABLE dbo.CT_KIEM_KE ADD CONSTRAINT FK_CT_KIEM_KE_PKK FOREIGN KEY (MaPKK)
        REFERENCES dbo.PHIEU_KIEM_KE (MaPKK);

-- FK_CT_KIEM_KE_LO: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.LO_HANG.
ALTER TABLE dbo.CT_KIEM_KE ADD CONSTRAINT FK_CT_KIEM_KE_LO FOREIGN KEY (MaLo)
        REFERENCES dbo.LO_HANG (MaLo);

-- CK_CT_KIEM_KE_SO_LUONG_HE_THONG: Số lượng hệ thống tại thời điểm kiểm kê phải không âm.
ALTER TABLE dbo.CT_KIEM_KE ADD CONSTRAINT CK_CT_KIEM_KE_SO_LUONG_HE_THONG CHECK (SoLuongHeThong >= 0);

-- CK_CT_KIEM_KE_SO_LUONG_THUC_TE: Số lượng kiểm kê thực tế được để NULL khi chưa đếm, còn lại phải không âm.
ALTER TABLE dbo.CT_KIEM_KE ADD CONSTRAINT CK_CT_KIEM_KE_SO_LUONG_THUC_TE
        CHECK (SoLuongThucTe IS NULL OR SoLuongThucTe >= 0);


-- ==================== dbo.PHIEU_TRA_HANG ====================

-- PK_PHIEU_TRA_HANG: Định danh duy nhất mỗi dòng bằng khóa chính (MaPTH).
ALTER TABLE dbo.PHIEU_TRA_HANG ADD CONSTRAINT PK_PHIEU_TRA_HANG PRIMARY KEY (MaPTH);

-- DF_PHIEU_TRA_HANG_NGAY: Cấp giá trị mặc định khi câu INSERT bỏ qua cột NgayTra.
ALTER TABLE dbo.PHIEU_TRA_HANG ADD CONSTRAINT DF_PHIEU_TRA_HANG_NGAY DEFAULT (SYSUTCDATETIME()) FOR NgayTra;

-- DF_PHIEU_TRA_HANG_TRANG_THAI: Cấp giá trị mặc định khi câu INSERT bỏ qua cột TrangThai.
ALTER TABLE dbo.PHIEU_TRA_HANG ADD CONSTRAINT DF_PHIEU_TRA_HANG_TRANG_THAI DEFAULT (N'NHAP') FOR TrangThai;

-- FK_PHIEU_TRA_HANG_PX: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.PHIEU_XUAT.
ALTER TABLE dbo.PHIEU_TRA_HANG ADD CONSTRAINT FK_PHIEU_TRA_HANG_PX FOREIGN KEY (MaPX)
        REFERENCES dbo.PHIEU_XUAT (MaPX);

-- FK_PHIEU_TRA_HANG_NV: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.NHAN_VIEN.
ALTER TABLE dbo.PHIEU_TRA_HANG ADD CONSTRAINT FK_PHIEU_TRA_HANG_NV FOREIGN KEY (MaNV)
        REFERENCES dbo.NHAN_VIEN (MaNV);

-- CK_PHIEU_TRA_HANG_TRANG_THAI: Chỉ nhận trạng thái nháp, đã hoàn thành hoặc đã hủy.
ALTER TABLE dbo.PHIEU_TRA_HANG ADD CONSTRAINT CK_PHIEU_TRA_HANG_TRANG_THAI
        CHECK (TrangThai IN (N'NHAP', N'DA_HOAN_THANH', N'DA_HUY'));

-- CK_PHIEU_TRA_HANG_HOAN_TAT: Thời điểm hoàn tất chỉ có giá trị khi chứng từ đã hoàn thành.
ALTER TABLE dbo.PHIEU_TRA_HANG ADD CONSTRAINT CK_PHIEU_TRA_HANG_HOAN_TAT CHECK (
        (TrangThai = N'DA_HOAN_THANH' AND NgayHoanTat IS NOT NULL)
        OR (TrangThai <> N'DA_HOAN_THANH' AND NgayHoanTat IS NULL)
    );


-- ==================== dbo.CT_PHIEU_TRA_HANG ====================

-- PK_CT_PHIEU_TRA_HANG: Định danh duy nhất mỗi dòng bằng khóa chính (MaPTH, MaLo).
ALTER TABLE dbo.CT_PHIEU_TRA_HANG ADD CONSTRAINT PK_CT_PHIEU_TRA_HANG PRIMARY KEY (MaPTH, MaLo);

-- FK_CT_PHIEU_TRA_HANG_PTH: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.PHIEU_TRA_HANG.
ALTER TABLE dbo.CT_PHIEU_TRA_HANG ADD CONSTRAINT FK_CT_PHIEU_TRA_HANG_PTH FOREIGN KEY (MaPTH)
        REFERENCES dbo.PHIEU_TRA_HANG (MaPTH);

-- FK_CT_PHIEU_TRA_HANG_LO: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.LO_HANG.
ALTER TABLE dbo.CT_PHIEU_TRA_HANG ADD CONSTRAINT FK_CT_PHIEU_TRA_HANG_LO FOREIGN KEY (MaLo)
        REFERENCES dbo.LO_HANG (MaLo);

-- FK_CT_PHIEU_TRA_HANG_VI_TRI: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.VI_TRI_KHO.
ALTER TABLE dbo.CT_PHIEU_TRA_HANG ADD CONSTRAINT FK_CT_PHIEU_TRA_HANG_VI_TRI FOREIGN KEY (MaViTri)
        REFERENCES dbo.VI_TRI_KHO (MaViTri);

-- CK_CT_PHIEU_TRA_HANG_SO_LUONG: Số lượng của dòng giao dịch hoặc lô phải lớn hơn 0.
ALTER TABLE dbo.CT_PHIEU_TRA_HANG ADD CONSTRAINT CK_CT_PHIEU_TRA_HANG_SO_LUONG CHECK (SoLuong > 0);

-- CK_CT_PHIEU_TRA_HANG_TINH_TRANG: Chỉ nhận hàng trả ở tình trạng tốt hoặc hư hỏng.
ALTER TABLE dbo.CT_PHIEU_TRA_HANG ADD CONSTRAINT CK_CT_PHIEU_TRA_HANG_TINH_TRANG
        CHECK (TinhTrang IN (N'Tốt', N'Hư hỏng'));


-- ==================== dbo.LICH_SU_THAO_TAC ====================

-- PK_LICH_SU_THAO_TAC: Định danh duy nhất mỗi dòng bằng khóa chính (MaLichSu).
ALTER TABLE dbo.LICH_SU_THAO_TAC ADD CONSTRAINT PK_LICH_SU_THAO_TAC PRIMARY KEY (MaLichSu);

-- DF_LICH_SU_THAO_TAC_THOI_GIAN: Cấp giá trị mặc định khi câu INSERT bỏ qua cột ThoiGian.
ALTER TABLE dbo.LICH_SU_THAO_TAC ADD CONSTRAINT DF_LICH_SU_THAO_TAC_THOI_GIAN DEFAULT (SYSUTCDATETIME()) FOR ThoiGian;

-- FK_LICH_SU_THAO_TAC_TAI_KHOAN: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.TAI_KHOAN.
ALTER TABLE dbo.LICH_SU_THAO_TAC ADD CONSTRAINT FK_LICH_SU_THAO_TAC_TAI_KHOAN FOREIGN KEY (MaTK)
        REFERENCES dbo.TAI_KHOAN (MaTK);

-- CK_LICH_SU_THAO_TAC_HANH_DONG: Chỉ ghi các hành động audit được hệ thống hỗ trợ.
ALTER TABLE dbo.LICH_SU_THAO_TAC ADD CONSTRAINT CK_LICH_SU_THAO_TAC_HANH_DONG CHECK
        (HanhDong IN (N'CREATE', N'UPDATE', N'CANCEL', N'COMPLETE',
                      N'PASSWORD_CHANGE', N'PASSWORD_RESET'));

-- CK_LICH_SU_THAO_TAC_DU_LIEU_CU: Dữ liệu trước thay đổi phải là JSON hợp lệ hoặc NULL.
ALTER TABLE dbo.LICH_SU_THAO_TAC ADD CONSTRAINT CK_LICH_SU_THAO_TAC_DU_LIEU_CU CHECK
        (DuLieuCu IS NULL OR ISJSON(DuLieuCu) = 1);

-- CK_LICH_SU_THAO_TAC_DU_LIEU_MOI: Dữ liệu sau thay đổi phải là JSON hợp lệ hoặc NULL.
ALTER TABLE dbo.LICH_SU_THAO_TAC ADD CONSTRAINT CK_LICH_SU_THAO_TAC_DU_LIEU_MOI CHECK
        (DuLieuMoi IS NULL OR ISJSON(DuLieuMoi) = 1);


-- ==================== dbo.DOI_SOAT_GIA_TRI ====================

-- DF_DOI_SOAT_GIA_TRI_THOI_GIAN: Cấp giá trị mặc định khi câu INSERT bỏ qua cột ThoiGian.
ALTER TABLE dbo.DOI_SOAT_GIA_TRI ADD CONSTRAINT DF_DOI_SOAT_GIA_TRI_THOI_GIAN DEFAULT (SYSUTCDATETIME()) FOR ThoiGian;

-- PK_DOI_SOAT_GIA_TRI: Định danh duy nhất mỗi dòng bằng khóa chính (LoaiChungTu, MaChungTu).
ALTER TABLE dbo.DOI_SOAT_GIA_TRI ADD CONSTRAINT PK_DOI_SOAT_GIA_TRI PRIMARY KEY (LoaiChungTu, MaChungTu);

-- FK_DOI_SOAT_GIA_TRI_TAI_KHOAN: Bảo đảm dữ liệu tham chiếu tồn tại ở dbo.TAI_KHOAN.
ALTER TABLE dbo.DOI_SOAT_GIA_TRI ADD CONSTRAINT FK_DOI_SOAT_GIA_TRI_TAI_KHOAN FOREIGN KEY (MaTKKeToan)
        REFERENCES dbo.TAI_KHOAN (MaTK);

-- CK_DOI_SOAT_GIA_TRI_LOAI: Chỉ đối soát chứng từ nhập hoặc xuất.
ALTER TABLE dbo.DOI_SOAT_GIA_TRI ADD CONSTRAINT CK_DOI_SOAT_GIA_TRI_LOAI CHECK (LoaiChungTu IN ('NHAP', 'XUAT'));

-- CK_DOI_SOAT_GIA_TRI_TRANG_THAI: Chỉ ghi nhận kết quả khớp hoặc chênh lệch.
ALTER TABLE dbo.DOI_SOAT_GIA_TRI ADD CONSTRAINT CK_DOI_SOAT_GIA_TRI_TRANG_THAI CHECK (TrangThai IN ('KHOP', 'CHENH_LECH'));

-- CK_DOI_SOAT_GIA_TRI_GIA_TRI: Giá trị chứng từ và giá trị đối soát đều không âm.
ALTER TABLE dbo.DOI_SOAT_GIA_TRI ADD CONSTRAINT CK_DOI_SOAT_GIA_TRI_GIA_TRI CHECK (GiaTriChungTu >= 0 AND GiaTriDoiSoat >= 0);

-- CK_DOI_SOAT_GIA_TRI_KET_QUA: Kết quả khớp cần hai giá trị bằng nhau; chênh lệch cần hai giá trị khác nhau và có ghi chú.
ALTER TABLE dbo.DOI_SOAT_GIA_TRI ADD CONSTRAINT CK_DOI_SOAT_GIA_TRI_KET_QUA CHECK (
        (TrangThai = 'KHOP' AND GiaTriChungTu = GiaTriDoiSoat)
        OR (TrangThai = 'CHENH_LECH' AND GiaTriChungTu <> GiaTriDoiSoat
            AND NULLIF(LTRIM(RTRIM(GhiChu)), N'') IS NOT NULL)
    );
