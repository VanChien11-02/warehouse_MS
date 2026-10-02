# Baseline contract liên module

> Trạng thái: **Draft để nhóm thảo luận**  
> Owner: Cần chốt  
> Reviewer frontend/backend/database: Cần chốt

Tài liệu này khóa những điểm mà nhiều workstream cùng sử dụng. Nó không thay thế contract chi tiết của từng endpoint. Mọi mục ghi `Cần chốt` phải được giải quyết trước khi đổi trạng thái sang `Accepted`.

## 1. Quy ước đặt tên

| Tầng | Quy ước đề xuất | Ví dụ |
| --- | --- | --- |
| SQL Server | Giữ tên vật lý đã review trong ERD | `SAN_PHAM.MaSP`, `TON_KHO.SoLuongTon` |
| Java type | `PascalCase`, tên nghiệp vụ đầy đủ, không dấu | `SanPhamResponse`, `HoanTatPhieuNhapUseCase` |
| Java field/method | `camelCase`, tránh tự tạo viết tắt mới | `maSanPham`, `layTonKho()` |
| JSON | `camelCase`, trùng tên DTO | `maSanPham`, `soLuongTon` |
| URL | Danh từ số nhiều hoặc tên tài nguyên nhất quán, chữ thường, kebab-case | `/api/san-pham`, `/api/phieu-nhap` |
| Enum/mã lỗi | `UPPER_SNAKE_CASE` | `DA_HOAN_THANH`, `INSUFFICIENT_STOCK` |

Không bắt buộc tên vật lý SQL giống hệt Java/JSON. Mapping phải xuất hiện trong data dictionary hoặc contract; không được dùng đồng thời `maSP`, `productId`, `idSanPham` và `productCode` cho cùng một khái niệm công khai.

### Từ điển tối thiểu

| Khái niệm | SQL | Java/JSON đề xuất | Nhóm sở hữu |
| --- | --- | --- | --- |
| Mã sản phẩm | `MaSP` | `maSanPham` | Master data |
| Mã nhà cung cấp | `MaNCC` | `maNhaCungCap` | Master data |
| Mã đối tác nhận hàng | `MaDTNH` | `maDoiTacNhanHang` | Master data |
| Mã vị trí | `MaViTri` | `maViTri` | Warehouse |
| Mã lô | `MaLo` | `maLo` | Inbound/inventory |
| Mã phiếu nhập | `MaPN` | `maPhieuNhap` | Inbound |
| Mã phiếu xuất | `MaPX` | `maPhieuXuat` | Outbound |
| Số lượng tồn | `SoLuongTon` | `soLuongTon` | Inventory |
| Trạng thái chứng từ | `TrangThai` | `trangThai` | Shared contract |

## 2. Kiểu dữ liệu và biểu diễn JSON

- Ngày dùng chuỗi ISO `yyyy-MM-dd`.
- Thời điểm dùng ISO-8601 có offset; cách lưu UTC/local trong SQL: **Cần chốt**.
- Tiền và số lượng thập phân truyền dưới dạng JSON number; Java dùng `BigDecimal`, SQL dùng `DECIMAL`, không dùng `double/FLOAT`.
- Mã nghiệp vụ là string, không để frontend suy ra từ khóa tăng tự động.
- Giá trị không có dữ liệu dùng `null` khi contract cho phép; không thay bằng chuỗi rỗng.

## 3. Trạng thái chứng từ

Đề xuất enum dùng chung:

| Giá trị | Ý nghĩa | Cho phép sửa |
| --- | --- | --- |
| `NHAP` | Chứng từ đang soạn | Có |
| `DA_HOAN_THANH` | Đã ghi sổ tồn | Không |
| `DA_HUY` | Đã hủy trước khi ghi sổ | Không |

Chuyển trạng thái đề xuất:

```text
NHAP ──hoàn tất──> DA_HOAN_THANH
  └────hủy───────> DA_HUY
```

- Hoàn tất cùng một chứng từ lần thứ hai phải trả lỗi và không thay đổi tồn.
- Không sửa/xóa chứng từ `DA_HOAN_THANH`; điều chỉnh qua nghiệp vụ đảo/điều chỉnh được chấp nhận.
- Có cần trạng thái `CHO_DUYET` hay không: **Cần chốt**.

## 4. Quy ước HTTP

### Endpoint mẫu

Các đường dẫn dưới đây là đề xuất để chốt, chưa phải contract `Accepted`:

```text
POST   /api/auth/dang-nhap
GET    /api/san-pham
POST   /api/san-pham
GET    /api/ton-kho
POST   /api/phieu-nhap/{maPhieuNhap}/hoan-tat
POST   /api/phieu-xuat/{maPhieuXuat}/hoan-tat
POST   /api/phieu-chuyen/{maPhieuChuyen}/hoan-tat
POST   /api/phieu-kiem-ke/{maPhieuKiemKe}/hoan-tat
POST   /api/phieu-tra-hang/{maPhieuTraHang}/hoan-tat
```

Tên resource hiện được ghi `/api/sanpham` trong frontend baseline. Nhóm cần chọn `/api/sanpham` hoặc `/api/san-pham`, sau đó cập nhật đồng thời contract, adapter frontend và tài liệu. Khuyến nghị dùng kebab-case.

### Phân trang

Request đề xuất:

```text
?page=0&size=20&sort=tenSanPham,asc
```

Response đề xuất:

```json
{
  "items": [],
  "page": 0,
  "size": 20,
  "totalElements": 0,
  "totalPages": 0
}
```

### Lỗi có cấu trúc

```json
{
  "code": "INSUFFICIENT_STOCK",
  "message": "Số lượng tồn không đủ",
  "fieldErrors": [
    {
      "field": "soLuong",
      "code": "GREATER_THAN_AVAILABLE",
      "message": "Số lượng yêu cầu vượt tồn khả dụng"
    }
  ],
  "traceId": ""
}
```

| HTTP status | Trường hợp |
| --- | --- |
| `400` | JSON/kiểu dữ liệu không hợp lệ |
| `401` | Chưa đăng nhập/token không hợp lệ |
| `403` | Đã đăng nhập nhưng không có quyền |
| `404` | Không tìm thấy tài nguyên |
| `409` | Mã trùng, trạng thái xung đột, hoàn tất lặp hoặc không đủ tồn |
| `422` | Dữ liệu đúng cú pháp nhưng vi phạm validation nghiệp vụ; có sử dụng hay không: **Cần chốt** |
| `500` | Lỗi ngoài dự kiến; không trả stack trace/SQL cho client |

## 5. Public interface giữa các module

Chỉ public DTO/interface được import chéo module. Repository, JPA entity, controller và implementation là nội bộ.

Chữ ký minh họa cần được chốt lại khi khởi tạo backend:

```java
public interface SanPhamQueryPort {
    SanPhamSnapshot laySanPhamDangHoatDong(String maSanPham);
}

public interface ViTriKhoQueryPort {
    ViTriSnapshot layViTriHopLe(String maViTri);
}

public interface TonKhoQueryPort {
    TonKhoSnapshot layTonKho(String maLo, String maViTri);
}
```

Các use case ghi sổ nên tách theo nghiệp vụ thay vì dùng một interface cập nhật tồn chung:

```java
public interface HoanTatPhieuNhapUseCase {
    KetQuaGhiSo hoanTat(String maPhieuNhap, String maNguoiThucHien);
}

public interface HoanTatPhieuXuatUseCase {
    KetQuaGhiSo hoanTat(String maPhieuXuat, String maNguoiThucHien);
}
```

Lý do: transaction nhập/xuất/chuyển/kiểm kê/trả có invariant khác nhau và phải khớp với stored procedure tương ứng.

## 6. Stored procedure contract

| Procedure | Owner triển khai đề xuất | Kết quả bắt buộc |
| --- | --- | --- |
| `sp_HoanTatPhieuNhap` | TV2 | Tạo lô/put-away/tăng tồn nguyên tử, chống hoàn tất lặp |
| `sp_HoanTatPhieuXuat` | TV3, TV2 review chuẩn procedure | Chọn/kiểm tra FEFO, không âm tồn, chống hoàn tất lặp |
| `sp_HoanTatChuyenKho` | TV3 | Giảm nguồn/tăng đích nguyên tử, kiểm tra sức chứa |
| `sp_HoanTatKiemKe` | TV3 | Lưu snapshot/chênh lệch và điều chỉnh đúng một lần |
| `sp_HoanTatTraHang` | TV3 | Không trả vượt lượng xuất, nhập đúng vị trí/tình trạng |
| `sp_TraCuuTonKho` | TV2 | Lọc theo kho/vị trí/sản phẩm/lô và truy được nguồn |

Quy ước chung:

- `SET XACT_ABORT ON`, `TRY...CATCH`, transaction và rollback.
- Kiểm tra trạng thái trong cùng transaction.
- Khóa dòng tồn phù hợp trước bước đọc-kiểm tra-cập nhật.
- Không trả message SQL thô làm mã lỗi công khai.
- Cơ chế trả mã lỗi/output/result set: **Cần chốt**.

## 7. Quy tắc thay đổi contract

- Thay đổi thêm field optional là non-breaking nếu client cũ bỏ qua được.
- Đổi tên/xóa field, đổi kiểu, đổi enum hoặc semantics là breaking.
- Breaking change phải được frontend, backend và database reviewer liên quan chấp nhận trước khi merge.
- Contract được merge trước hoặc cùng PR với provider; consumer không tự suy đoán field chưa có trong contract.
- Khi `Accepted`, mỗi endpoint phải có request, response thành công, response lỗi, role và ví dụ.

## 8. Checklist để chuyển sang Accepted

- [ ] Chốt owner/reviewer.
- [ ] Chốt URL style và sửa tài liệu frontend tương ứng.
- [ ] Chốt lưu/hiển thị thời gian.
- [ ] Chốt có/không `CHO_DUYET`.
- [ ] Chốt dùng `409` hay `422` cho từng lỗi nghiệp vụ.
- [ ] Chốt cơ chế trả lỗi từ stored procedure sang Spring.
- [ ] Thay interface minh họa bằng chữ ký Java đã compile trong project.
- [ ] Viết contract chi tiết cho Session/RBAC và sản phẩm trước tiên.
