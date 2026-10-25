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

## Bộ dữ liệu vấn đáp: danh mục → kho → nhập lô

`inbound_viva_demo.sql` chạy độc lập với `demo.sql`, sau khi đã dựng
`database/init.sql`. Bộ mã bắt đầu bằng `C` để dễ lọc, dùng dữ liệu giả và không
tạo tài khoản. Chạy từ root repository:

```powershell
sqlcmd -S localhost -E -C -b -d BlueStock -i database/seed/inbound_viva_demo.sql
sqlcmd -S localhost -E -C -b -d BlueStock -i database/seed/inbound_viva_checks.sql
```

| Mã | Dữ liệu hoặc tình huống |
| --- | --- |
| `CLP001`, `CLP002`; `CDV001`, `CDV002`; `CSP001`, `CSP002` | Hai loại bảo quản khô/mát, hai đơn vị tính và hai sản phẩm |
| `CNC001`, `CNC002` | NCC hợp lệ đã liên kết hai sản phẩm; NCC chưa liên kết để thử lỗi |
| `CKH001`, `CKV001..002`, `CVT001..003` | Một kho, hai khu vực; kệ khô nhỏ `CVT002` sức chứa 5, đã có 4 |
| `CPN001` | Phiếu đã hoàn tất bằng `sp_HoanTatPhieuNhap`: 3 lô, 18 đơn vị tồn ban đầu, 3 dòng lịch sử trong view |
| `CPN002` | Phiếu nháp hợp lệ để thao tác hoàn tất trước giảng viên |
| `CPN003` | Phiếu nháp để thử sai tổng phân bổ `51108` hoặc vượt sức chứa `51112` |
| `CPN004` | Phiếu nháp của NCC chưa liên kết sản phẩm: lỗi `51106` |
| `CPN005` | Phiếu nháp có một dòng 7 đơn vị để thử trigger: hai lô 4 + 4 phải bị từ chối `51820` |

`inbound_viva_checks.sql` đọc view/function, ép truy vấn dùng index
`IX_LO_HANG_SAN_PHAM_HAN`, rồi xác nhận ba lỗi procedure và trigger nhiều dòng
không để lại lô hoặc đổi trạng thái phiếu. Chạy file kiểm tra **trước khi** tự
hoàn tất `CPN002` hoặc sửa các phiếu nháp. Script seed chạy lại không tăng tồn
lần hai; nếu đã dùng các phiếu nháp để demo, nó không đặt chúng về trạng thái
ban đầu. Khi cần bộ dữ liệu sạch, dựng database demo mới rồi nạp seed.

Để hoàn tất trực tiếp `CPN002`, chạy trong SSMS hoặc `sqlcmd`:

```sql
EXEC dbo.sp_HoanTatPhieuNhap
    @MaPN = 'CPN002',
    @PhanBoJson = N'[{"maSanPham":"CSP001","maViTri":"CVT001","soLuong":3},
                    {"maSanPham":"CSP002","maViTri":"CVT003","soLuong":2}]';

SELECT MaPN, TrangThai, NgayHoanTat
FROM dbo.PHIEU_NHAP WHERE MaPN = 'CPN002';
SELECT MaPN, MaSP, MaLo, SoLuongNhap, GiaTriNhap
FROM dbo.vw_LichSuNhapKho WHERE MaPN = 'CPN002';
```

Gọi hoàn tất `CPN002` lần hai sẽ báo `51102`; số lô và tồn không được tăng
thêm. Trong SSMS, bật **Include Actual Execution Plan** và chạy truy vấn theo
`CSP001`, `HanSuDung` trên `LO_HANG` để xem index. File kiểm tra ép index để
chứng minh object tồn tại và dùng được; vài lô demo chưa đủ để kết luận index
làm truy vấn nhanh hơn. Đo hiệu năng trên dữ liệu lớn theo
[`../indexes/README.md`](../indexes/README.md).
