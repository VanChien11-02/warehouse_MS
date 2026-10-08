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

## Đề xuất phân công module dọc

> Trạng thái: **Draft để nhóm xác nhận**. Trách nhiệm rubric ở trên vẫn giữ nguyên; bảng này bổ sung ownership module để bốn thành viên có thể phát triển song song.

| Workstream | Owner đề xuất | Reviewer cần chốt | Branch | Module nhỏ |
| --- | --- | --- | --- | --- |
| Nền tảng và bảo mật | TV4 Phát | Cần chốt | `workstream/platform-security` | Nhân viên, tài khoản, auth, role, audit, Spring Security, app shell |
| Danh mục và cấu trúc kho | TV1 Chiến | Cần chốt | `workstream/master-data-warehouse` | Sản phẩm, đơn vị tính, nhà cung cấp, đối tác, kho/khu vực/vị trí |
| Nhập kho và tồn | TV2 Thi | Cần chốt | `workstream/inbound-inventory` | Phiếu nhập, lô, put-away, tồn theo lô/vị trí, báo cáo tồn |
| Xuất và kiểm soát tồn | TV3 Trung | Cần chốt | `workstream/outbound-stock-control` | Xuất FEFO, chuyển kho, kiểm kê, trả hàng, concurrency |

Chi tiết ranh giới file, dependency và baseline trước khi tách branch nằm trong [`WORKSTREAMS.md`](WORKSTREAMS.md).

### Việc nhận sau khi nhánh triển khai được merge

Sau khi nhóm review và merge các PR hiện có, trưởng nhóm ghi lại commit `main` làm baseline chung. Mỗi thành viên tạo branch trong bảng trên từ **cùng commit đó**, kiểm tra phần đã có, rồi mở PR nhỏ cho từng lỗi hoặc phần thiếu. Việc nhận ownership ở đây là trách nhiệm kiểm tra và bảo trì tiếp, không ghi lại tác giả của phần code đã có. Bảng sau là lịch review đề xuất; nhóm xác nhận reviewer thực tế trước khi đưa task vào `Ready`.

| Owner | Kiểm tra đầu tiên trên branch của mình | Reviewer đề xuất |
| --- | --- | --- |
| TV1 Chiến | Đối chiếu ERD với constraint, trigger, view, index; thử CRUD danh mục/kho và lưu bằng chứng query plan cho `PERF-01` | TV2 Thi |
| TV2 Thi | Chạy lại procedure/function nhập và tra tồn; chứng minh hoàn tất lặp, lỗi nghiệp vụ và rollback bằng SQL/API | TV3 Trung |
| TV3 Trung | Kiểm tra xuất FEFO, chuyển kho, kiểm kê, trả hàng; chạy tranh chấp hai session và đối chiếu sổ biến động sau rollback | TV4 Phát |
| TV4 Phát | Kiểm tra bốn role SQL, quyền API theo role, bootstrap tài khoản, audit và quy trình dựng demo từ máy sạch | TV1 Chiến |

Nếu một lỗi chạm hai module, owner của module có file cần sửa mở PR và mời owner module còn lại review. Thay đổi schema/API đi kèm contract, script, test và tài liệu trong chính PR đó. Không merge trực tiếp branch workstream của người khác vào branch của mình; cập nhật từ nhánh tích hợp mà nhóm đã chốt.

## Nguyên tắc chia việc

- Owner module chịu trách nhiệm xuyên suốt yêu cầu → contract → code → test → tài liệu.
- Người làm stored procedure/transaction phối hợp cùng owner backend, không tạo hai bản logic tồn kho khác nhau.
- Trách nhiệm rubric là vai trò chuyên môn/review; không thay thế ownership module và không cho phép tự sửa file của workstream khác.
- Chỉ public interface/DTO/contract được dùng giữa module; không import repository hoặc JPA entity của module khác.
- Mỗi người phải hiểu và demo được phần mình phụ trách.
- Không tự ghi đóng góp cho thành viên khi người đó chưa review và nhận trách nhiệm.
