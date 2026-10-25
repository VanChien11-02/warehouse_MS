# Phân công nhóm

Phân công đề xuất hiện hành nằm trong [`DBMS_WORK_ASSIGNMENT.md`](DBMS_WORK_ASSIGNMENT.md). Bốn thành viên sở hữu bốn luồng nghiệp vụ từ schema, ràng buộc, trigger, view, index, function, procedure và transaction đến API/UI, test và tài liệu. Mỗi người phải thực hành đầy đủ các chủ đề DBMS trong chính luồng mình và có bằng chứng để vấn đáp.

| Mã | Thành viên | Luồng chính | Reviewer đề xuất |
| --- | --- | --- | --- |
| TV1 | Chiến | Danh mục, đối tác, kho và nhập lô | TV2 Thi |
| TV2 | Thi | Tra tồn, xuất FEFO và báo cáo xuất | TV3 Trung |
| TV3 | Trung | Chuyển vị trí và kiểm kê | TV4 Phát |
| TV4 | Phát | Trả hàng, đối soát, audit và phân quyền | TV1 Chiến |

> Trạng thái: **Đề xuất để nhóm xác nhận**. Bảng này giao trách nhiệm cho công việc sắp tới, không ghi lại tác giả của code đã có. Reviewer và commit baseline thực tế cần được bốn thành viên chốt tại `GOV-02`.

Ranh giới module, branch và quy tắc ghép code nằm trong [`WORKSTREAMS.md`](WORKSTREAMS.md). Mỗi PR có owner, reviewer, acceptance criteria, test và bằng chứng; thay đổi schema/API phải cập nhật contract, script và tài liệu liên quan. Không nhận đóng góp thay người khác khi người đó chưa review và xác nhận.
