-- Sequence sinh mã; giữ nguyên kiểu, giá trị bắt đầu và bước tăng.

-- SEQ_PHIEU_NHAP: Cấp số tiếp theo để sinh mã phieu nhap.
CREATE SEQUENCE dbo.SEQ_PHIEU_NHAP AS INT START WITH 1 INCREMENT BY 1;

-- SEQ_LO_HANG: Cấp số tiếp theo để sinh mã lô hàng.
CREATE SEQUENCE dbo.SEQ_LO_HANG AS INT START WITH 1 INCREMENT BY 1;

-- SEQ_PHIEU_XUAT: Cấp số tiếp theo để sinh mã phieu xuat.
CREATE SEQUENCE dbo.SEQ_PHIEU_XUAT AS INT START WITH 1 INCREMENT BY 1;

-- SEQ_PHIEU_CHUYEN_KHO: Cấp số tiếp theo để sinh mã phieu chuyen kho.
CREATE SEQUENCE dbo.SEQ_PHIEU_CHUYEN_KHO AS INT START WITH 1 INCREMENT BY 1;

-- SEQ_PHIEU_KIEM_KE: Cấp số tiếp theo để sinh mã phieu kiem ke.
CREATE SEQUENCE dbo.SEQ_PHIEU_KIEM_KE AS INT START WITH 1 INCREMENT BY 1;

-- SEQ_PHIEU_TRA_HANG: Cấp số tiếp theo để sinh mã phieu tra hang.
CREATE SEQUENCE dbo.SEQ_PHIEU_TRA_HANG AS INT START WITH 1 INCREMENT BY 1;
