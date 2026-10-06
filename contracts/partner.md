# Contract dữ liệu đối tác

- Status: Accepted for BE schema and supplier API implementation; recipient API pending
- Date: 2026-10-07
- Scope: nền dữ liệu cho INB-01, OUT-01, BR-INB-007, BR-OUT-006
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`NHA_CUNG_CAP` lưu nhà cung cấp bằng `MaNCC CHAR(6)`, tên bắt buộc, địa chỉ, số điện thoại, email tùy chọn. `DOI_TAC_NHAN_HANG` lưu bên nhận bằng `MaDTNH CHAR(6)`, tên và loại đối tác bắt buộc, thông tin liên hệ tùy chọn. Chưa khóa enum `LoaiDoiTac` vì tài liệu nghiệp vụ chưa liệt kê các loại cần hỗ trợ; giá trị không được rỗng.

`NHA_CUNG_CAP_SAN_PHAM(MaNCC, MaSP)` và `DOI_TAC_SAN_PHAM(MaDTNH, MaSP)` có khóa chính ghép, FK tới đúng đối tác và sản phẩm. Mỗi cặp chỉ xuất hiện một lần. Không cascade delete; đối tác/sản phẩm đang được mapping hoặc chứng từ tham chiếu không xóa vật lý được.

Khi hoàn tất phiếu nhập, database phải xác nhận mọi sản phẩm trên phiếu được mapping với `MaNCC` của phiếu; khi hoàn tất phiếu xuất, mọi sản phẩm được mapping với `MaDTNH`. Thiếu bất kỳ cặp nào làm toàn transaction thất bại và không đổi tồn. Kiểm tra khi hoàn tất, không chỉ khi tạo nháp, để bắt thay đổi mapping trước ghi sổ.

## API nhà cung cấp

Các route dưới `/api/nha-cung-cap` dùng session và CSRF chung. `GET` dành cho bốn role đã đăng nhập; thao tác ghi dành cho `Admin` và `QuanLyKho`. Danh sách hỗ trợ `page` từ 0, `size` từ 1 đến 100 và `q` tìm mã/tên (tối đa 100 ký tự), trả `{items,page,size,totalElements,totalPages}`. Mã tối đa 6 ký tự chữ/số, không phân biệt hoa thường; mã đã tạo không sửa được.

| Method | Route | Kết quả |
| --- | --- | --- |
| `GET` | `/api/nha-cung-cap` | `200` danh sách phân trang |
| `GET` | `/api/nha-cung-cap/{maNhaCungCap}` | `200` thông tin một nhà cung cấp |
| `POST` | `/api/nha-cung-cap` | `201` và `Location` |
| `PUT` | `/api/nha-cung-cap/{maNhaCungCap}` | `200` thông tin sau cập nhật |
| `DELETE` | `/api/nha-cung-cap/{maNhaCungCap}` | `204` nếu chưa được tham chiếu |
| `GET` | `/api/nha-cung-cap/{maNhaCungCap}/san-pham` | `200` mảng mã sản phẩm đã liên kết |
| `POST` | `/api/nha-cung-cap/{maNhaCungCap}/san-pham/{maSanPham}` | `201` khi liên kết được tạo |
| `DELETE` | `/api/nha-cung-cap/{maNhaCungCap}/san-pham/{maSanPham}` | `204` khi xóa liên kết |

Tạo: `{"maNhaCungCap":"NCC001","tenNhaCungCap":"Nhà cung cấp A","diaChi":null,"soDienThoai":null,"email":null}`. Cập nhật dùng cùng các trường trừ `maNhaCungCap`. Đọc trả cùng năm trường. Tên bắt buộc và không quá 255 ký tự; địa chỉ tối đa 500, số điện thoại 20, email hợp lệ và tối đa 255 ký tự. Trường tùy chọn rỗng được lưu `null`.

Lỗi dùng envelope chuẩn: `422 INVALID_CODE/INVALID_PAGINATION/INVALID_QUERY/INVALID_PRODUCT`, `404 SUPPLIER_NOT_FOUND/SUPPLIER_PRODUCT_NOT_FOUND`, `409 SUPPLIER_CODE_EXISTS/SUPPLIER_PRODUCT_EXISTS/SUPPLIER_IN_USE`. Lỗi validation DTO dùng `422 VALIDATION_FAILED`. Database FK ngăn xóa nhà cung cấp đang được chứng từ hoặc mapping tham chiếu. Khi bỏ mapping, phiếu đã hoàn tất vẫn giữ lịch sử; phiếu nháp sẽ bị kiểm tra lại tại lúc hoàn tất.

API đối tác nhận hàng được bổ sung trong mốc tiếp theo.
