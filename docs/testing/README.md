# Kiểm thử và bằng chứng

## Mục tiêu

Mỗi yêu cầu phải truy được tới thiết kế, code và bài kiểm thử. Không ghi “đã đạt” nếu chưa chạy trên đúng module và môi trường được mô tả.

## Các lớp kiểm thử

- Frontend: kiểm tra cú pháp, responsive, validation, loading/error state và luồng tạo payload.
- Backend: unit test domain/application, controller/security test và integration test.
- Database: chạy script từ database sạch; test constraint, trigger, procedure/function, rollback và phân quyền.
- E2E: đăng nhập → nhập lô → xem tồn → xuất FEFO → báo cáo; kiểm tra ít nhất một luồng lỗi rollback.
- Concurrency: hai transaction đồng thời cùng xuất một dòng tồn; kết quả không được âm hoặc xuất vượt.

## Bằng chứng tối thiểu

- Lệnh đã chạy, ngày chạy và commit/nhánh.
- Kết quả pass/fail cụ thể.
- Ảnh hoặc log ngắn cho demo/rubric khi cần.
- Với index: execution plan hoặc số đo trước/sau trên cùng dữ liệu.
- Với role: script GRANT/REVOKE/DENY và kết quả truy cập được/bị từ chối.

## Cổng root

```powershell
pwsh -File scripts/verify.ps1
```

Khi backend/database được thêm, owner phải nối kiểm tra module vào cổng root trong cùng PR.
