# Trigger bảo vệ dữ liệu kho

Năm trigger hiện hành được gom trong [`triggers.sql`](triggers.sql), có comment
giải thích từng quy tắc. Chúng là lớp chặn cuối ở SQL
Server. Procedure vẫn chịu trách nhiệm kiểm tra nghiệp vụ, khóa tồn và ghi sổ
trong transaction. `AFTER` trigger chạy tự động trong chính transaction của
câu `INSERT`/`UPDATE`; `THROW` làm câu ghi thất bại và procedure rollback.
Không gọi `EXEC trigger` từ Java.

| Trigger | Khi nào chạy | Quy tắc và ví dụ chứng minh |
| --- | --- | --- |
| `trg_ViTriKho_BaoVeTon` | Sửa `VI_TRI_KHO` | Không hạ sức chứa dưới tồn, đổi khu/loại vị trí đang có tồn. `database/tests/021_position_stock_guard.sql` kiểm tra update nhiều dòng. |
| `trg_LoHang_GioiHanPhanBo` | Tạo/sửa `LO_HANG` | Tổng `SoLuongNhap` của mọi lô cùng `(MaPN, MaSP)` không vượt `CT_PHIEU_NHAP.SoLuong` (`BR-INB-004`). Chặn cả hai lô được thêm trong một câu SQL mà cộng lại vượt dòng nhập. |
| `trg_LoaiSanPham_BaoVeBaoQuan` | Sửa `LOAI_SAN_PHAM` | Không đổi yêu cầu bảo quản của loại đã có lô hàng (kể cả khi tồn về 0). Vẫn sửa được tên/mô tả, giữ cùng yêu cầu; loại chưa có lô đổi được. UI Loại sản phẩm nhận 409 `CATEGORY_STORAGE_LOCKED` từ SQL 51825. |
| `trg_TonKho_BaoVeViTri` | Tạo/sửa `TON_KHO` | Tổng tồn theo vị trí không vượt `SucChua` và các lô có tồn dương tại cùng vị trí phải có chung `MaDVT` (`BR-WHS-002`). Cộng `BIGINT` để tránh tràn khi tính tổng. |
| `trg_BienDongTonKho_DungChieu` | Tạo/sửa `BIEN_DONG_TON_KHO` | `NHAP`/`TRA_HANG` phải tăng; `XUAT` phải giảm. `CHUYEN`/`KIEM_KE` có thể tăng hoặc giảm nên trigger không áp dấu cố định cho hai loại này. `CHECK` sẵn có vẫn chặn delta bằng 0. |

`database/tests/024_inventory_guard_triggers.sql` kiểm tra bốn trigger: một
lệnh nhiều dòng sai bị rollback trọn vẹn, lệnh hợp lệ vẫn ghi được; trigger
dòng nhập cũ không còn. Bộ test procedure 009, 012, 014, 016, 018 cùng seed demo
xác nhận đường ghi từ API vẫn chạy. API không ghi trực tiếp tồn hay sổ biến động.

Mã lỗi SQL `51820`, `51822`–`51825` dành cho các trigger hiện hành; `51821` đã
ngừng dùng khi bỏ trigger dòng nhập. Khi hoàn tất nhập, procedure
chặn phân bổ thiếu; tổng lô vượt dòng được giao cho `trg_LoHang_GioiHanPhanBo`.
Trên form Phiếu nhập thật, dòng 10 với phân bổ 6+5 bị trigger chặn và API trả
422 `ALLOCATION_EXCEEDS_LINE`. Test 009 kiểm tra đúng nguồn lỗi và rollback cả
nghiệp vụ. Các lỗi vị trí, mapping, sức chứa vẫn có thể bị procedure chặn trước.

Tại UI Loại sản phẩm, đổi Khô sang Mát cho loại đã có lô sẽ bị trigger mới
chặn; giữ Khô rồi sửa tên/mô tả lưu được. Migration 030 gỡ trigger dòng nhập
cũ và tạo guard mới; migration 027 chỉ giữ lịch sử nâng cấp. Xem
[ADR 0009](../../docs/architecture/adr/0009-category-storage-history-guard.md).
