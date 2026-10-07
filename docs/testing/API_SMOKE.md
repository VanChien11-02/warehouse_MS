# Kịch bản HTTP nhập → tồn → xuất FEFO → báo cáo

Kịch bản dùng Postman hoặc HTTP client có cookie jar. Chạy trên database demo, không dùng dữ liệu thật. Đây là hướng dẫn thực hiện; chỉ ghi đạt E2E sau khi chạy và đối chiếu response thực tế.

## Chuẩn bị

1. Dựng database sạch và seed theo [`../development/BUILD_GUIDE.md`](../development/BUILD_GUIDE.md). Seed tạo `SP0001`, `NCC001`, `DT0001`, `VT0001` và hai lô `SP0001` có hạn khác nhau; không tạo tài khoản.
2. Bật SQL Server TCP/IP, kiểm tra `Test-NetConnection 127.0.0.1 -Port 1433`, cấu hình JDBC và chạy `scripts/bootstrap-admin.ps1` đúng một lần. Dừng tiến trình bootstrap rồi chạy `scripts/dev.ps1 -Target api`.
3. Kiểm tra `GET http://127.0.0.1:8080/actuator/health` trả `UP`. Dùng cùng host `127.0.0.1` cho mọi request để cookie session được giữ.
4. Trong Postman tạo biến `baseUrl=http://127.0.0.1:8080`. Không lưu mật khẩu, cookie hay CSRF token vào collection/export được commit.

## Tạo tài khoản quản lý kho

1. `GET {{baseUrl}}/api/auth/csrf`: giữ `JSESSIONID` trong cookie jar và lấy `token` trong response.
2. `POST {{baseUrl}}/api/auth/dang-nhap`, header `X-CSRF-TOKEN: <token>`, JSON `{"tenTaiKhoan":"admin","matKhau":"<mật khẩu bootstrap>"}`. Kiểm tra role `ADMIN`; lấy CSRF token lại bằng route ở bước 1 nếu session/token đã đổi.
3. `POST {{baseUrl}}/api/nhan-vien` với cùng cookie và CSRF token, JSON `{"maNhanVien":"NVD002","tenNhanVien":"Quản lý kho demo","ngayVaoLam":"<ngày hôm nay yyyy-MM-dd>"}`. Kỳ vọng `201`. Nếu mã đã tồn tại do lần chạy trước, dùng nhân viên/tài khoản có sẵn hoặc chọn mã mới gồm tối đa 6 ký tự chữ/số.
4. `POST {{baseUrl}}/api/tai-khoan` với cùng cookie và CSRF token, JSON `{"maTaiKhoan":"TKD002","maNhanVien":"NVD002","tenTaiKhoan":"quanly.demo","role":"QLKHO","matKhau":"<mật khẩu riêng từ 12 ký tự>"}`. Kỳ vọng `201`, response không chứa mật khẩu/hash.
5. `POST {{baseUrl}}/api/auth/dang-xuat` với CSRF token. Lấy token mới qua `/api/auth/csrf`, rồi đăng nhập `quanly.demo`; kiểm tra `/api/auth/me` trả role `QLKHO`.

Mọi request `POST`/`PUT` sau đây cần cùng cookie và header `X-CSRF-TOKEN`. Nếu nhận `403`, lấy token mới từ `/api/auth/csrf` trong cùng cookie jar rồi thử lại.

## Luồng nghiệp vụ

1. `GET {{baseUrl}}/api/ton-kho?maSanPham=SP0001`: ghi lại tổng `soLuongTon` và lô/vị trí trước thao tác. Seed mới có 30 đơn vị `SP0001` ở hai vị trí.
2. `POST {{baseUrl}}/api/phieu-nhap` với JSON `{"maNhaCungCap":"NCC001","ghiChu":"Thử HTTP nhập kho","chiTiet":[{"maSanPham":"SP0001","soLuong":4,"donGiaNhap":12500.0000}]}`. Kỳ vọng `201`; lưu `maPhieuNhap` từ response.
3. `POST {{baseUrl}}/api/phieu-nhap/{{maPhieuNhap}}/hoan-tat` với JSON `{"phanBo":[{"maSanPham":"SP0001","maViTri":"VT0001","soLuong":4,"hanSuDung":"<ngày hôm nay cộng 20 ngày yyyy-MM-dd>"}]}`. Kỳ vọng `200`, trạng thái `DA_HOAN_THANH`. Ngày hạn mới phải sau hôm nay và trước hạn 30 ngày của lô seed để kiểm tra FEFO.
4. Gọi lại `/api/ton-kho?maSanPham=SP0001`: tổng `soLuongTon` tăng đúng 4; tìm `maLo` mới qua `maPhieuNhap` của bước 2. Ghi lại mã lô và số tồn của nó.
5. `POST {{baseUrl}}/api/phieu-xuat` với JSON `{"maDoiTacNhanHang":"DT0001","ghiChu":"Thử HTTP xuất FEFO","chiTiet":[{"maLo":"<mã lô mới>","maViTri":"VT0001","soLuong":2,"donGiaXuat":18000.0000}]}`. Kỳ vọng `201`; lưu `maPhieuXuat`.
6. `GET {{baseUrl}}/api/phieu-xuat/{{maPhieuXuat}}/goi-y-fefo?maSanPham=SP0001&soLuong=2`: `phanBo` phải bắt đầu bằng lô mới và `soLuongThieu=0`.
7. `POST {{baseUrl}}/api/phieu-xuat/{{maPhieuXuat}}/hoan-tat` không có body: kỳ vọng `200`, trạng thái `DA_HOAN_THANH`. Tồn lô mới giảm đúng 2; tổng tồn `SP0001` tăng ròng 2 so với bước 1.
8. Gọi hoàn tất phiếu xuất lần nữa: kỳ vọng `409 OUTBOUND_NOT_DRAFT`; tồn và số dòng sổ biến động không đổi. Có thể kiểm tra lại tồn bằng API và sổ bằng SQL trên database demo.
9. `GET {{baseUrl}}/api/bao-cao/nhap-xuat?tuNgay=<hôm nay>&denNgay=<hôm nay>&maKho=KHO001&maSanPham=SP0001`: kỳ vọng dòng có ít nhất 4 nhập và 2 xuất từ luồng vừa chạy, với `soLuongCuoiKy = soLuongDauKy + soLuongNhap - soLuongXuat + soLuongDieuChinh`.

Để kiểm tra rollback FEFO, tạo phiếu xuất nháp khác lấy hai đơn vị từ lô seed hạn 30 ngày khi lô hạn 20 ngày vẫn còn. Hoàn tất phải trả `409 FEFO_VIOLATION`; tồn và sổ biến động giữ nguyên. Hủy phiếu nháp bằng `POST /api/phieu-xuat/{maPhieuXuat}/huy` sau phép thử.

## Ghi bằng chứng

Lưu ngày chạy, phiên bản SQL Server, commit, mã phiếu, HTTP status và giá trị tồn/báo cáo trước-sau. Không lưu mật khẩu, session cookie hoặc token trong ảnh/log chia sẻ. Nếu JDBC không kết nối được, kiểm tra TCP/IP trước: `sqlcmd -E` trên cùng máy có thể vẫn chạy qua shared memory.
