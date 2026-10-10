# Contract dữ liệu đối tác

- Status: Accepted for BE schema implementation; HTTP API pending
- Date: 2026-10-07
- Scope: nền dữ liệu cho INB-01, OUT-01, BR-INB-007, BR-OUT-006
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`NHA_CUNG_CAP` lưu nhà cung cấp bằng `MaNCC CHAR(6)`, tên bắt buộc, địa chỉ, số điện thoại, email tùy chọn. `DOI_TAC_NHAN_HANG` lưu bên nhận bằng `MaDTNH CHAR(6)`, tên và loại đối tác bắt buộc, thông tin liên hệ tùy chọn. Chưa khóa enum `LoaiDoiTac` vì tài liệu nghiệp vụ chưa liệt kê các loại cần hỗ trợ; giá trị không được rỗng.

`NHA_CUNG_CAP_SAN_PHAM(MaNCC, MaSP)` và `DOI_TAC_SAN_PHAM(MaDTNH, MaSP)` có khóa chính ghép, FK tới đúng đối tác và sản phẩm. Mỗi cặp chỉ xuất hiện một lần. Không cascade delete; đối tác/sản phẩm đang được mapping hoặc chứng từ tham chiếu không xóa vật lý được.

Khi hoàn tất phiếu nhập, database phải xác nhận mọi sản phẩm trên phiếu được mapping với `MaNCC` của phiếu; khi hoàn tất phiếu xuất, mọi sản phẩm được mapping với `MaDTNH`. Thiếu bất kỳ cặp nào làm toàn transaction thất bại và không đổi tồn. Kiểm tra khi hoàn tất, không chỉ khi tạo nháp, để bắt thay đổi mapping trước ghi sổ.

Endpoint CRUD và gán/bỏ mapping sẽ được chốt trong mốc partner API. Chưa có HTTP endpoint đối tác trong commit schema này.
