# Hướng dẫn frontend

Đọc `README.md` trong thư mục này, backlog item và API contract liên quan trước khi sửa.

- Giữ UI responsive, bàn phím dùng được và nhãn form rõ ràng.
- Mỗi luồng dữ liệu phải có loading, empty, error và success state phù hợp.
- Không đặt quyền, giá trị tồn cuối cùng hoặc quy tắc ghi sổ làm nguồn sự thật ở frontend.
- Tách dữ liệu mẫu và API qua adapter/cấu hình; không rải URL endpoint khắp UI.
- Không đổi framework hoặc thêm dependency production nếu chưa có backlog/ADR được nhóm chấp nhận.
- Trước khi bàn giao chạy `pwsh -File scripts/verify.ps1` từ root và kiểm tra Console không có lỗi ngoài lỗi API được chủ động mô phỏng.
