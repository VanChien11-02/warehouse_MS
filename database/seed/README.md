# Dữ liệu mẫu

Chạy từ root sau `database/init.sql`:

```powershell
sqlcmd -S localhost -E -C -b -d BlueStock -i database/seed/demo.sql
```

Seed tạo hai sản phẩm (`SP0001` đồ khô, `SP0002` hàng mát), một nhà cung cấp,
một đối tác nhận, một kho với hai khu vực và bốn vị trí. Phiếu nhập mẫu
`PND001` được hoàn tất qua procedure, tạo ba lô và 40 đơn vị tồn. Hai lô
`SP0001` có hạn khác nhau để thử gợi ý và kiểm tra FEFO; hạn được tính từ ngày
chạy seed theo `Asia/Bangkok`. Vị trí hàng hỏng bắt đầu trống để thử trả hàng.

Script có thể chạy lại mà không cộng tồn lần hai. Nếu mã `PND001` đã tồn tại
nhưng chưa hoàn tất, script dừng để tránh ghi đè dữ liệu. Các mã `SP0001`,
`KHO001`, `PND001` và mã mẫu liên quan dành cho demo, không dùng với dữ liệu
thật. Seed không có tài khoản, password hoặc hash; tạo tài khoản Admin bằng
`scripts/bootstrap-admin.ps1`, rồi dùng API quản trị để cấp tài khoản cho
các vai trò còn lại.

`catalog_demo.sql` chỉ tạo `LSP001` và `DVT001`, phù hợp khi cần thử CRUD danh
mục mà không nạp sẵn sản phẩm/chứng từ.
