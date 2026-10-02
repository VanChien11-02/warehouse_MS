# Quy trình làm việc rút gọn

## Nhịp một tuần

| Thời điểm | Hoạt động | Đầu ra |
| --- | --- | --- |
| Đầu tuần | Sprint planning | Mục tiêu, owner, reviewer, task Ready |
| Giữa tuần | Đồng bộ blocker | Quyết định kỹ thuật và việc cần hỗ trợ |
| Cuối tuần | Review + demo | Bản chạy/script/sơ đồ và kết quả test |
| Sau review | Retrospective | Một điểm giữ lại, một điểm cần sửa |

GitHub Project dùng: `Backlog → Ready → In Progress → In Review → Done`, kèm `Blocked` khi có cản trở thật.

## Definition of Ready

Một task chỉ vào `Ready` khi có:

- Yêu cầu hoặc pain point nguồn.
- Kết quả cụ thể cần tạo.
- Owner và reviewer.
- Tiêu chí chấp nhận kiểm tra được.
- Phụ thuộc và file/API/database dự kiến ảnh hưởng.

## Definition of Done

- Yêu cầu, ERD/contract và tài liệu liên quan đã cập nhật.
- Code/script build hoặc chạy không lỗi.
- Test phù hợp đạt và có bằng chứng.
- Reviewer khác owner đã kiểm tra.
- PR đã merge vào `main` và CI đạt.
- Changelog được cập nhật nếu thay đổi hành vi/cấu trúc/quy trình.

## Nhánh và Pull Request

- `main`: luôn chạy được.
- `feature/<issue>-<ket-qua>`: chức năng mới.
- `fix/<issue>-<van-de>`: sửa lỗi.
- `docs/<issue>-<noi-dung>`: tài liệu.
- `test/<issue>-<pham-vi>`: kiểm thử.

Không trộn refactor không liên quan vào PR chức năng. Thay đổi schema/API phải có reviewer của frontend/backend/database liên quan.

## Mẫu cập nhật Issue

```text
Kết quả hôm nay:
Bước tiếp theo:
Lệnh/test đã chạy:
Blocker hoặc quyết định cần nhóm chốt:
```
