## Kết quả

Mô tả ngắn thay đổi và lý do.

## Liên kết

- Closes #
- Backlog/ADR/contract:

## Phạm vi thay đổi

- [ ] Frontend
- [ ] Backend
- [ ] Database
- [ ] Contract/API
- [ ] Tài liệu/CI

## Kiểm tra

```text
pwsh -File scripts/verify.ps1
```

- Kết quả:
- Kiểm tra chưa chạy và lý do:

## Checklist

- [ ] Không có secret, `.env`, database backup hoặc build output.
- [ ] API/schema thay đổi đã cập nhật contract và có reviewer liên quan.
- [ ] Transaction/tồn kho đã kiểm tra rollback và chống xử lý lặp khi phù hợp.
- [ ] Loading/error/empty state đã kiểm tra nếu thay đổi frontend.
- [ ] Tài liệu và `CHANGELOG.md` đã cập nhật.
