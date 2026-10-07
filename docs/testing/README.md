# Kiểm thử và bằng chứng

## Mục tiêu

Mỗi yêu cầu phải truy được tới thiết kế, code và bài kiểm thử. Không ghi “đã đạt” nếu chưa chạy trên đúng module và môi trường được mô tả.

Business rule dùng mã ổn định trong [`../requirements/BUSINESS_RULES.md`](../requirements/BUSINESS_RULES.md). Tên test hoặc test evidence nên ghi mã `BR-*` tương ứng để truy vết.

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

Backend test đã được nối vào cổng mặc định. Chạy thêm SQL và tranh chấp hai session trên database đã dựng:

```powershell
pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency
```

`-DatabaseName <ten_database>` chọn database thử riêng. Bài SQL dùng `sqlcmd` với Windows Authentication; E2E HTTP cần API kết nối JDBC qua TCP/IP và tài khoản đăng nhập được tạo qua bootstrap. Kết quả SQL/Java không chứng minh API HTTP hay frontend đã tích hợp.
