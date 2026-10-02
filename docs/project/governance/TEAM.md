# Phân công nhóm

Tài liệu này chuẩn hóa nội dung từ file `chia_viec.md` cũ. Các mã TV và phần việc dưới đây được giữ nguyên; họ tên đầy đủ, GitHub và reviewer cụ thể cần được nhóm xác nhận trong sprint planning.

## Trách nhiệm theo rubric database

| Mã | Thành viên | Phần việc chính | Đầu ra tối thiểu |
| --- | --- | --- | --- |
| TV1 | Chiến | Ràng buộc, trigger, view, index | Ít nhất 5 constraint có ý nghĩa, 5 trigger, 5 view, 5 index và minh chứng index |
| TV2 | Thi | Stored procedure, user-defined function, xử lý lỗi | Ít nhất 5 procedure, 5 function, `TRY...CATCH` và test lỗi |
| TV3 | Trung | Transaction, concurrency và khôi phục lỗi | Ít nhất 5 transaction nghiệp vụ, rollback và một tình huống tranh chấp đồng thời |
| TV4 | Phát | Bảo mật và phân quyền | Ít nhất 4 role/login, ma trận quyền, GRANT/REVOKE/DENY và test truy cập |

## Trách nhiệm chung

Mỗi chủ phần việc phải:

- Liên kết object SQL với một nghiệp vụ thật trong ERD/backlog.
- Viết script chạy lại được và dữ liệu test tối thiểu.
- Tạo test thành công và thất bại, không chỉ viết object.
- Nhờ một thành viên khác review trước khi merge.
- Cập nhật tài liệu và bằng chứng cho báo cáo/vấn đáp.

## Phân công module cần chốt

Phân chia theo loại object SQL giúp đạt rubric nhưng chưa đủ để phát triển ứng dụng. Nhóm cần gán thêm owner/reviewer cho các module dọc:

| Module | Owner | Reviewer | Ghi chú |
| --- | --- | --- | --- |
| Repository, tích hợp và tài liệu | Cần chốt | Cần chốt | Điều phối merge, changelog và báo cáo |
| Frontend và trải nghiệm | Cần chốt | Cần chốt | Dashboard, danh mục, phiếu và báo cáo |
| Backend nền tảng và auth | Cần chốt | Cần chốt | Spring Boot, security, exception, contract |
| Danh mục và cấu trúc kho | Cần chốt | Cần chốt | Sản phẩm, đối tác, kho/khu vực/vị trí |
| Nhập kho và lô | Cần chốt | Cần chốt | Phiếu nhập, tạo lô, put-away |
| Xuất kho và FEFO | Cần chốt | Cần chốt | Chọn lô/vị trí, chống xuất vượt tồn |
| Chuyển kho, kiểm kê, trả hàng | Cần chốt | Cần chốt | Transaction và chứng từ điều chỉnh |
| QA và traceability | Cần chốt | Cần chốt | Test plan, E2E, concurrency, evidence |

## Nguyên tắc chia việc

- Owner module chịu trách nhiệm xuyên suốt yêu cầu → contract → code → test → tài liệu.
- Người làm stored procedure/transaction phối hợp cùng owner backend, không tạo hai bản logic tồn kho khác nhau.
- Mỗi người phải hiểu và demo được phần mình phụ trách.
- Không tự ghi đóng góp cho thành viên khi người đó chưa review và nhận trách nhiệm.
