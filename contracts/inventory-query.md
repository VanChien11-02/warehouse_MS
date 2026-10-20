# Contract tra cứu tồn theo lô và vị trí

- Status: Accepted for BE implementation
- Date: 2026-10-07
- Scope: INV-01, BR-INV-001, BR-INV-004, BR-REP-001, BR-REP-002
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`GET /api/ton-kho` yêu cầu session đã đăng nhập; cả bốn role được đọc. Không có endpoint ghi số tồn trực tiếp. Danh sách chỉ gồm dòng có `soLuongTon > 0` từ phiếu nhập đã hoàn tất, theo khóa `(maViTri, maLo)`.

Query hỗ trợ `page=0&size=20`, `maKho`, `maViTri`, `maSanPham`, `maLo`, `hanSuDungTruoc=yyyy-MM-dd` và `chiKhaDung=true|false`. `size` từ 1–100; mã lọc được trim/chuyển chữ hoa và dài 1–6 ký tự chữ/số. `hanSuDungTruoc` bao gồm ngày đã cho, không lấy lô có hạn `null`. Thứ tự: mã sản phẩm, hạn gần nhất trước, lô không hạn sau, rồi vị trí/lô. Response có page envelope chung.

Mỗi item trả `maKho`, `tenKho`, `maKhuVuc`, `tenKhuVuc`, `maViTri`, `tenViTri`, `loaiViTri`, `maLo`, `maSanPham`, `tenSanPham`, `maDonViTinh`, `soLuongTon`, `ngaySanXuat`, `hanSuDung`, `maPhieuNhap`, `ngayHoanTat`, `donGiaNhap`, `giaTriTon`, `khaDung`. `donGiaNhap` là giá thực tế của dòng nhập tạo lô; `giaTriTon = soLuongTon × donGiaNhap`, dùng `BigDecimal`, không phụ thuộc giá mặc định hiện tại. `ngayHoanTat` trả UTC với `Z`.

`khaDung=false` nếu vị trí là `Hư hỏng` hoặc hạn dùng trước ngày nghiệp vụ tại `Asia/Bangkok`. Lô không có hạn dùng được xem là chưa hết hạn. `chiKhaDung=true` lọc các dòng theo cùng quy tắc. Đây là chỉ dấu đọc; procedure xuất kho vẫn phải khóa và kiểm tra tồn/hạn lần nữa khi hoàn tất.

Lỗi dùng envelope chung: `422 INVALID_CODE` hoặc `INVALID_PAGINATION`; `400 INVALID_PARAMETER` nếu ngày/kiểu tham số sai; `401` khi chưa đăng nhập. Nguồn SQL là `dbo.vw_TonKhoChiTiet`, nối vị trí, lô, sản phẩm, phiếu nhập và đơn giá nhập; view loại phiếu nháp.
