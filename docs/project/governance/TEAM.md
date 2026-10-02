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

## Nguyên tắc chia việc

- Owner module chịu trách nhiệm xuyên suốt yêu cầu → contract → code → test → tài liệu.
- Người làm stored procedure/transaction phối hợp cùng owner backend, không tạo hai bản logic tồn kho khác nhau.
- Trách nhiệm rubric là vai trò chuyên môn/review; không thay thế ownership module và không cho phép tự sửa file của workstream khác.
- Chỉ public interface/DTO/contract được dùng giữa module; không import repository hoặc JPA entity của module khác.
- Mỗi người phải hiểu và demo được phần mình phụ trách.
- Không tự ghi đóng góp cho thành viên khi người đó chưa review và nhận trách nhiệm.
