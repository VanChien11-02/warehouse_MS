# Trigger bảo vệ dữ liệu kho

Năm trigger trong thư mục này là lớp chặn cuối ở SQL Server. Procedure vẫn chịu trách nhiệm kiểm tra nghiệp vụ, khóa tồn và ghi sổ trong transaction. `AFTER` trigger chạy tự động trong chính transaction của câu `INSERT`/`UPDATE`; `THROW` làm câu ghi thất bại và procedure rollback. Không gọi `EXEC trigger` từ Java.

| Trigger | Khi nào chạy | Quy tắc và ví dụ chứng minh |
| --- | --- | --- |
| `trg_ViTriKho_BaoVeTon` | Sửa `VI_TRI_KHO` | Không hạ sức chứa dưới tồn, đổi khu/loại vị trí đang có tồn. `database/tests/021_position_stock_guard.sql` kiểm tra update nhiều dòng. |
| `trg_LoHang_GioiHanPhanBo` | Tạo/sửa `LO_HANG` | Tổng `SoLuongNhap` của mọi lô cùng `(MaPN, MaSP)` không vượt `CT_PHIEU_NHAP.SoLuong` (`BR-INB-004`). Chặn cả hai lô được thêm trong một câu SQL mà cộng lại vượt dòng nhập. |
| `trg_CtPhieuNhap_GioiHanLo` | Tạo/sửa `CT_PHIEU_NHAP` | Không giảm lượng của dòng nhập xuống dưới tổng lô đã tạo. Đây là chiều sửa từ bảng chi tiết, bổ sung cho trigger trên bảng lô. |
| `trg_TonKho_BaoVeViTri` | Tạo/sửa `TON_KHO` | Tổng tồn theo vị trí không vượt `SucChua` và các lô có tồn dương tại cùng vị trí phải có chung `MaDVT` (`BR-WHS-002`). Cộng `BIGINT` để tránh tràn khi tính tổng. |
| `trg_BienDongTonKho_DungChieu` | Tạo/sửa `BIEN_DONG_TON_KHO` | `NHAP`/`TRA_HANG` phải tăng; `XUAT` phải giảm. `CHUYEN`/`KIEM_KE` có thể tăng hoặc giảm nên trigger không áp dấu cố định cho hai loại này. `CHECK` sẵn có vẫn chặn delta bằng 0. |

`database/tests/024_inventory_guard_triggers.sql` kiểm tra bốn trigger mới: một lệnh nhiều dòng sai bị rollback trọn vẹn, lệnh hợp lệ vẫn ghi được, và cập nhật dòng nhập không làm sai phân bổ lô. Bộ test procedure 009, 012, 014, 016, 018 cùng seed demo xác nhận đường ghi từ API vẫn chạy: Spring JDBC gọi `sp_HoanTat*`, procedure ghi các bảng trên và trigger tự kích hoạt. API không có endpoint ghi trực tiếp `TON_KHO` hay sổ biến động.

Mã lỗi SQL `51820`–`51824` dành cho các trigger. Các procedure đã có mã lỗi nghiệp vụ riêng và thường từ chối yêu cầu sai trước khi tới trigger; trigger bảo vệ thêm các đường ghi trực tiếp hoặc thay đổi phát sinh trong transaction. Khi trình bày báo cáo, dùng kết quả test SQL để chứng minh trigger chặn dữ liệu, rồi dùng luồng API nhập → tồn → xuất để chứng minh ứng dụng đi qua các trigger mà không phải gọi chúng bằng tay.
