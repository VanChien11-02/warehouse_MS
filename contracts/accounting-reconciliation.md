# Đối soát giá trị chứng từ

- Status: Accepted for implementation theo quyết định Project Owner 2026-10-22.
- Scope: ACC-01, SEC-01.
- Owner: backend/frontend/database; reviewer tích hợp: chủ repository.

Kế toán được đối soát **một lần** sau khi phiếu nhập hoặc xuất ở trạng thái
`DA_HOAN_THANH`. Đối soát là bản ghi riêng trong `DOI_SOAT_GIA_TRI`, không sửa
chứng từ, giá, tồn hoặc sổ biến động. Quản lý kho xem được kết quả nhưng không
được ghi; Admin và Nhân viên kho không truy cập API đối soát.

| Method | Route | Quyền | Kết quả |
| --- | --- | --- | --- |
| `GET` | `/api/doi-soat-gia-tri/{loaiChungTu}/{maChungTu}` | `QLKHO`, `KETOAN` | `200` bản ghi; `404 RECONCILIATION_NOT_FOUND` nếu chưa đối soát |
| `POST` | `/api/doi-soat-gia-tri/{loaiChungTu}/{maChungTu}` | `KETOAN` + CSRF | `200` bản ghi vừa tạo |

`loaiChungTu` chỉ nhận `NHAP` hoặc `XUAT`, mã chứng từ gồm 1–6 chữ/số.
Request POST:

```json
{"giaTriDoiSoat":120000.0000,"ghiChu":null}
```

Server khóa header phiếu trong transaction, kiểm tra đã hoàn tất, tính
`giaTriChungTu = SUM(SoLuong * DonGiaNhap/DonGiaXuat)` từ dòng hiện có và
so sánh bằng `DECIMAL(19,4)`. Nếu bằng nhau, trạng thái `KHOP`. Nếu khác,
trạng thái `CHENH_LECH` và `ghiChu` không rỗng là bắt buộc. Không nhận
`giaTriChungTu`, trạng thái hay người đối soát từ client. Response gồm
`loaiChungTu`, `maChungTu`, `giaTriChungTu`, `giaTriDoiSoat`, `chenhLech`
(giá trị đối soát trừ giá trị phiếu), `trangThai`, `ghiChu`,
`maTaiKhoanKeToan`, `thoiGian` UTC. Bản ghi có khóa `(LoaiChungTu, MaChungTu)`;
gọi lại trả `409 ALREADY_RECONCILED`, kể cả hai request cạnh tranh.

Phiếu chưa hoàn tất trả `409 DOCUMENT_NOT_COMPLETED`; phiếu không tồn tại trả
`404 DOCUMENT_NOT_FOUND`; sai giá trị/mã hoặc thiếu ghi chú chênh lệch trả
`422`; sai vai trò trả `403`, chưa đăng nhập `401`. Ghi audit `CREATE` cho
`DOI_SOAT_GIA_TRI` trong cùng transaction. Ghi nhận chênh lệch là cờ xử lý,
không tự tạo chứng từ điều chỉnh hay thay đổi số tồn.

Database sạch dùng `database/schema/030_doi_soat_gia_tri.sql` qua `init.sql`.
Database hiện có chạy `database/migrations/028_accounting_reconciliation.sql`
để thêm bảng và đồng bộ role SQL; script không xóa dữ liệu.
