-- Chọn database BlueStock trong ô chọn database của SSMS trước khi chạy.
-- Bôi đen từng SELECT rồi F5. File này chỉ chứa truy vấn SELECT.
-- Nếu xem dữ liệu giống UI Docker: kết nối localhost,14330 (DB_PORT mặc định).

SELECT DB_NAME() AS DatabaseDangChon;

-- 1. Index: có dòng trả về nghĩa là index tồn tại trên đúng bảng.
SELECT name, type_desc, is_disabled
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.PHIEU_NHAP')
  AND name = N'IX_PHIEU_NHAP_NGAY_MA';

-- 2. View.
SELECT name, type_desc
FROM sys.views
WHERE object_id = OBJECT_ID(N'dbo.vw_LichSuNhapKho');

-- 3. Function: SQL_SCALAR_FUNCTION là hàm trả một giá trị.
SELECT name, type_desc
FROM sys.objects
WHERE object_id = OBJECT_ID(N'dbo.fn_TonTheoLo') AND type = 'FN';

-- 4. Hai trigger: is_disabled = 0 là đang bật.
SELECT name, OBJECT_NAME(parent_id) AS Bang, is_disabled
FROM sys.triggers
WHERE object_id IN (OBJECT_ID(N'dbo.trg_LoHang_GioiHanPhanBo'),
                    OBJECT_ID(N'dbo.trg_LoaiSanPham_BaoVeBaoQuan'));

-- 5. Stored procedure.
SELECT name, type_desc
FROM sys.procedures
WHERE object_id = OBJECT_ID(N'dbo.sp_HoanTatPhieuNhap');

-- 6. CHECK: xem tên và biểu thức của hai ràng buộc.
SELECT name, definition
FROM sys.check_constraints
WHERE object_id IN (OBJECT_ID(N'dbo.CK_CT_PHIEU_NHAP_SO_LUONG'),
                    OBJECT_ID(N'dbo.CK_LO_HANG_HAN'));

-- 7. Khóa ngoại lô -> dòng nhập.
SELECT name, OBJECT_NAME(parent_object_id) AS BangCon,
       OBJECT_NAME(referenced_object_id) AS BangCha
FROM sys.foreign_keys
WHERE object_id = OBJECT_ID(N'dbo.FK_LO_HANG_CT_PN');

-- 8. Transaction không có object riêng. Xem code procedure chứa transaction.
-- Tìm BEGIN TRANSACTION, COMMIT TRANSACTION, ROLLBACK TRANSACTION trong kết quả.
SELECT OBJECT_DEFINITION(OBJECT_ID(N'dbo.sp_HoanTatPhieuNhap')) AS MaNguonThuTuc;

-- Lưu ý: kết quả rỗng/NULL cần kiểm tra database, schema và quyền xem metadata.
-- Các SELECT chứng minh có object/code, không thay thế bài chứng minh hiệu năng hay rollback.
