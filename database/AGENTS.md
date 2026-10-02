# Hướng dẫn SQL Server

Đọc ERD, backlog item và `database/README.md` trước khi sửa script.

- Script phải chạy trên SQL Server 2022 từ database sạch theo thứ tự trong `init.sql` sau khi file này được tạo.
- Dùng tên object nhất quán với ERD; ghi rõ khi tên vật lý khác tên khái niệm.
- Quantity của dòng giao dịch phải lớn hơn 0; tồn không âm; tiền dùng `DECIMAL`, không dùng `FLOAT`.
- Procedure nghiệp vụ dùng `SET XACT_ABORT ON`, `TRY...CATCH`, transaction và chống ghi sổ hai lần.
- Trigger phải xử lý nhiều dòng trong `inserted`/`deleted`, không giả định một dòng.
- Không xóa/sửa chứng từ hoàn tất để “sửa cho nhanh”; dùng chứng từ đảo/điều chỉnh theo thiết kế.
- Mỗi view/index/function/trigger cần test và giải thích mục đích nghiệp vụ hoặc hiệu năng.
- Không commit `.bak`, `.mdf`, `.ldf`, secret hoặc dữ liệu thật.
