# ADR 0007: Docker Compose cho bản demo

- Trạng thái: Accepted trên nhánh triển khai; chờ review khi tích hợp repository.
- Ngày: 2026-10-09.
- Liên quan: `DEC-023`, `REL-01`.

## Quyết định

Cung cấp `compose.yaml` để dựng SQL Server 2022 Developer, khởi tạo database và seed giả lập, chạy API Java 21 và phục vụ frontend tĩnh. Ba mật khẩu được nhập qua `.env` local, không đưa vào Git. Giữ nguyên cách chạy trực tiếp trên máy trong build guide.

Database dùng named volume để giữ dữ liệu giữa các lần khởi động. Script khởi tạo chỉ dựng schema khi database chưa tồn tại, từ chối database có schema không đầy đủ và chạy lại seed idempotent. API dùng một login kỹ thuật riêng trên database demo; bốn role SQL phục vụ bài học vẫn được kiểm thử riêng.

## Hệ quả

Người chấm và thành viên có một quy trình dựng nhất quán trên máy hỗ trợ Linux containers. Việc demo bằng Compose cần Docker và đủ bộ nhớ cho SQL Server. Image SQL Server Developer chỉ dùng cho phát triển/demo; cấu hình này không phải bản triển khai production. Xem lệnh và giới hạn cụ thể tại [`../../development/DOCKER_DEMO.md`](../../development/DOCKER_DEMO.md).
