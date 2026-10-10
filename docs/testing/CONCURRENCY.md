# Kiểm chứng hai phiên xuất cùng tồn

Từ root repository, sau khi dựng `BlueStock`:

```powershell
pwsh -File scripts/verify-concurrency.ps1
```

Script tạo một lô có 6 đơn vị và hai phiếu xuất nháp cùng lấy 4 đơn vị từ
cùng vị trí. Hai tiến trình `sqlcmd` chờ cùng một mốc giây rồi gọi
`sp_HoanTatPhieuXuat` ở hai session. Kết quả chấp nhận: đúng một phiếu hoàn
tất, phiếu kia nhận lỗi thiếu tồn `51208` và vẫn là nháp; tồn cuối bằng 2,
sổ xuất có đúng một biến động `-4`. Bài đối chiếu dọn dữ liệu giả sau cả
trường hợp đạt và không đạt. Mã fixture `CNC001`/`CNC002` phải đang trống.

Có thể chạy chung cổng kiểm chứng:

```powershell
pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency
```

Ngày 2026-10-07 trên SQL Server 17.0.1135.8, hai lần chạy đã đạt: một lần
`CNC001` chốt trước, một lần `CNC002` chốt trước. Đây là kiểm chứng tranh chấp
trên cùng vị trí/lô; chưa phải kiểm thử tải nhiều người dùng hoặc đo độ trễ.
