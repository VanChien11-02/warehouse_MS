# Kế hoạch physical schema SQL Server

> Trạng thái: **Draft cho DB-01**. Schema phiếu kiểm kê và trả hàng đã có; procedure trả hàng và audit vẫn cần triển khai.

## Mục tiêu

- Dựng SQL Server 2022 từ database sạch bằng một điểm vào `database/init.sql`.
- Chia object theo file/module để bốn workstream hạn chế xung đột merge.
- Đủ constraint, procedure, function, trigger, view, index, security và test có ý nghĩa cho rubric.

## Cấu trúc file mục tiêu

```text
database/
├─ init.sql
├─ schema/
│  ├─ 001_auth.sql
│  ├─ 010_catalog.sql
│  ├─ 020_partner.sql
│  ├─ 030_warehouse.sql
│  ├─ 040_inbound_inventory.sql
│  ├─ 050_outbound.sql
│  └─ 060_stock_control.sql
├─ programmability/
│  ├─ procedures/
│  ├─ functions/
│  ├─ triggers/
│  └─ views/
├─ indexes/
├─ security/
├─ seed/
└─ tests/
```

Khi số object tăng, ưu tiên một object chính trên một file trong thư mục module, ví dụ `procedures/inbound/sp_HoanTatPhieuNhap.sql`. Không để nhiều thành viên cùng sửa một script khổng lồ.

## Thứ tự tạo bảng

Thứ tự chi tiết phải tôn trọng FK:

1. Bảng gốc auth và danh mục: `ROLE`, `NHAN_VIEN`, `LOAI_SAN_PHAM`, `DON_VI_TINH`, `NHA_CUNG_CAP`, `DOI_TAC_NHAN_HANG`, `KHO`.
2. Bảng phụ thuộc một cấp: `TAI_KHOAN`, `SAN_PHAM`, `KHU_VUC`.
3. Vị trí và mapping: `VI_TRI_KHO`, `NHA_CUNG_CAP_SAN_PHAM`, `DOI_TAC_SAN_PHAM`.
4. Nhập kho: `PHIEU_NHAP`, `CT_PHIEU_NHAP`, `LO_HANG`.
5. Tồn: `TON_KHO`.
6. Xuất kho: `PHIEU_XUAT`, `CT_PHIEU_XUAT`.
7. Chuyển kho: `PHIEU_CHUYEN_KHO`, `CT_PHIEU_CHUYEN_KHO`.
8. Kiểm kê: `PHIEU_KIEM_KE`, `CT_KIEM_KE`.
9. Trả hàng: `PHIEU_TRA_HANG`, `CT_PHIEU_TRA_HANG`.
10. Audit: `LICH_SU_THAO_TAC`; có thể tạo sớm hơn sau `TAI_KHOAN` nếu trigger cần dùng.

## Ownership

| Nhóm object | Owner module đề xuất | Reviewer chuyên môn |
| --- | --- | --- |
| Identity, role, security, audit | TV4 | TV1 constraint/trigger; TV2 error handling |
| Catalog, partner, warehouse | TV1 | TV4 permission; consumer module |
| Inbound, batch, inventory, reporting view | TV2 | TV1 index/view; TV3 transaction |
| Outbound, transfer, count, returning | TV3 | TV2 procedure; TV1 constraint/index |
| `init.sql` và thứ tự tích hợp | Trưởng nhóm/người được chỉ định | Ít nhất một reviewer khác |

## Data dictionary cần chốt

Mỗi column phải có các thuộc tính sau trước khi schema được Accepted:

| Thuộc tính | Ví dụ |
| --- | --- |
| Tên khái niệm và tên vật lý | Mã sản phẩm / `MaSP` |
| Kiểu và độ dài | `NVARCHAR(...)`, `DECIMAL(p,s)`, `DATE`, `DATETIME2` |
| Nullability | `NOT NULL` hoặc lý do cho phép null |
| Default | trạng thái mặc định, thời gian tạo nếu phù hợp |
| Key | PK, FK, unique hoặc composite key |
| Check | số lượng dương, giá không âm, enum hợp lệ |
| Mapping API | `maSanPham` |
| Business rule | mã `BR-*` liên quan |

Precision tiền, kiểu thời điểm và cách sinh mã dùng ADR 0003. Độ dài mã/tên đã triển khai cho chín bảng nền tảng; collation và chính sách ngừng dùng danh mục cần ghi rõ khi triển khai endpoint tương ứng.

## Constraint bắt buộc tối thiểu

- `TAI_KHOAN.MaNV` unique.
- Quantity chi tiết nhập/xuất/chuyển/trả lớn hơn 0.
- Giá không âm.
- Tồn không âm.
- Hạn sử dụng không trước ngày sản xuất.
- Nguồn và đích chuyển khác nhau.
- Enum trạng thái/tình trạng chỉ nhận giá trị đã chốt.
- PK/FK composite đúng với ERD, đặc biệt `TON_KHO(MaViTri, MaLo)`.

Constraint bảo vệ dữ liệu cơ bản; validation nghiệp vụ đa bảng và transaction vẫn nằm trong procedure/application service phù hợp.

## Programmability inventory

### Procedure nghiệp vụ

- `sp_HoanTatPhieuNhap`.
- `sp_HoanTatPhieuXuat`.
- `sp_HoanTatChuyenKho`.
- `sp_HoanTatKiemKe`.
- `sp_HoanTatTraHang`.
- `sp_TraCuuTonKho` hoặc query/view tương đương đã review.

### Function

- `fn_TonTheoSanPham`.
- `fn_TonTheoLo`.
- `fn_TonKhaDungTaiViTri`.
- `fn_GiaTriTonKho`.
- `fn_LoSapHetHan`.

### View

- `vw_TonKhoChiTiet`.
- `vw_TonKhoTheoSanPham`.
- `vw_LichSuNhapKho`.
- `vw_LichSuXuatKho`.
- `vw_LoSapHetHan`.
- `vw_ChenhLechKiemKe`.

### Trigger

Trigger chỉ dùng cho bảo vệ/audit phù hợp, phải xử lý nhiều dòng trong `inserted`/`deleted`. Không dùng trigger để tạo bản logic ghi sổ thứ hai cạnh procedure.

## Index baseline

- `SAN_PHAM(TenSP)`.
- `LO_HANG(MaSP, HanSuDung)`.
- `TON_KHO(MaLo) INCLUDE (MaViTri, SoLuongTon)`.
- `PHIEU_NHAP(NgayNhap, MaNCC)`.
- `PHIEU_XUAT(NgayXuat, MaDTNH)`.
- `LICH_SU_THAO_TAC(ThoiGian, MaTK)`.

Mỗi index cần query đại diện và bằng chứng trước/sau; không tạo chỉ để đủ số lượng.

## Script convention

- File encoding UTF-8.
- Dùng schema-qualified object name, ví dụ `dbo.SAN_PHAM` nếu schema `dbo` được chốt.
- Dùng `CREATE OR ALTER` cho procedure/function/view/trigger khi phù hợp.
- Procedure transaction dùng `SET NOCOUNT ON`, `SET XACT_ABORT ON`, `TRY...CATCH` và rollback an toàn.
- Không dùng `GO` bên trong dynamic context không hỗ trợ; runner phải được tài liệu hóa.
- Không hard-code login/password thật trong security script.
- Seed và test tách khỏi schema production-like.

## Test database tối thiểu

| Nhóm | Bài test |
| --- | --- |
| Schema | PK/FK/unique/check/default và nullability |
| Procedure | success, validation error, rollback, hoàn tất lặp |
| Trigger | multi-row insert/update/delete phù hợp |
| Security | GRANT/REVOKE/DENY cho bốn role |
| Concurrency | hai phiên xuất/chuyển cùng tồn không làm âm |
| Index | execution plan hoặc số đo trước/sau trên cùng dataset |
| Rebuild | chạy từ database sạch theo `init.sql` |

## Definition of DB baseline complete

- [ ] Data dictionary được review.
- [ ] `init.sql` chạy trên SQL Server 2022 từ database sạch.
- [ ] Seed demo chạy được.
- [ ] Constraint và five posting procedures có test.
- [ ] Security roles có test truy cập.
- [ ] Concurrency scenario có script/hướng dẫn hai session.
- [ ] Backend integration test gọi được procedure quan trọng.
- [ ] Không có secret, `.bak`, `.mdf` hoặc `.ldf` trong Git.
