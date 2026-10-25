# Index phục vụ tra cứu kho

[`001_inventory_lookup.sql`](001_inventory_lookup.sql) gom toàn bộ tám
index tường minh, giữ nguyên câu SQL và thêm comment mục đích từng index.
Index do PK/UNIQUE tạo nằm trong `../constraints/constraints.sql`.
File này dùng khi dựng mới qua `init.sql`; bốn index chuyển từ file tạo bảng
vẫn dùng `CREATE INDEX` như trước, nên không chạy lại toàn bộ file trên
database đã có các index đó. Migration 026 giữ nguyên bốn index tra cứu có
`IF NOT EXISTS`, không bị mở rộng thành tám index.

| Index | Truy vấn |
| --- | --- |
| `IX_LO_HANG_SAN_PHAM_HAN` | Lọc sản phẩm/hạn dùng khi gợi ý FEFO và báo cáo hạn |
| `IX_TON_KHO_LO_VI_TRI` | Nối tồn từ lô sang vị trí, cộng tồn theo lô |
| `IX_PHIEU_NHAP_NGAY_MA` | Phân trang phiếu nhập mới nhất |
| `IX_PHIEU_XUAT_NGAY_MA` | Phân trang phiếu xuất mới nhất |
| `IX_BIEN_DONG_TON_KHO_NGAY` | Lọc sổ biến động theo thời gian, vị trí và lô |
| `IX_PHIEU_TRA_HANG_PX` | Tra phiếu trả theo phiếu xuất gốc và trạng thái |
| `IX_LICH_SU_THAO_TAC_THOI_GIAN` | Tra audit theo thời gian và tài khoản |
| `IX_DOI_SOAT_GIA_TRI_THOI_GIAN` | Tra lịch sử đối soát theo thời gian và Kế toán |

Test `023_inventory_indexes.sql` kiểm tra object, khóa đầu và truy vấn đại diện.
Các index này tăng chi phí ghi khi thêm lô/chứng từ; chỉ giữ nếu workload demo và
plan thực tế chứng minh lợi ích.

Đo trên SQL Server 17.0.1135.8 ngày 2026-10-07 bằng:

```powershell
sqlcmd -S localhost -E -C -b -d BlueStock -i database/indexes/measure_inventory_lookup.sql
```

Script tạo 100 sản phẩm và 10.000 lô giả trong transaction, lọc một sản phẩm,
buộc lần đầu đọc clustered index và lần hai dùng index mới trên cùng dữ liệu.
`SET STATISTICS IO/TIME` cho kết quả: mỗi truy vấn trả 100 lô; scan 48 logical
reads, 15 ms CPU/14 ms elapsed; index 3 logical reads, 0 ms CPU/0 ms elapsed.
Dữ liệu đo được rollback. Đây là một lần chạy trên cache ấm; logical reads là
bằng chứng chính, thời gian không phải cam kết hiệu năng trên máy khác hoặc
SQL Server 2022.

Tìm kiếm chuỗi giữa tên sản phẩm dùng `CHARINDEX`, nên chưa tạo index `TenSP`
chỉ để đủ số lượng vì truy vấn đó không seek được với B-tree thông thường.
