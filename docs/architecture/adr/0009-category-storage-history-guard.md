# ADR 0009: Thay trigger dòng nhập bằng bảo vệ yêu cầu bảo quản

- Status: Accepted for implementation theo yêu cầu thay trigger của Project Owner
- Date: 2026-10-25
- Scope: CAT-01, DB-R01, BR-CAT-003; thay phần trigger dòng nhập của ADR 0008

## Quyết định

Gỡ `trg_CtPhieuNhap_GioiHanLo`, thay bằng
`trg_LoaiSanPham_BaoVeBaoQuan` trên `LOAI_SAN_PHAM` sau UPDATE. Khi có bất kỳ
lô hàng nào thuộc sản phẩm của loại này, không đổi `YeuCauBaoQuan`, kể cả đổi
từ/có NULL. Vẫn sửa được tên/mô tả hoặc lưu lại cùng yêu cầu bảo quản. Loại
chưa có lô được đổi yêu cầu bình thường. Lịch sử lô vẫn tồn tại khi đã xuất hết
tồn, nên điều kiện dựa trên lô, không chỉ trên lượng tồn hiện tại.

Lý do: sửa danh mục không được đổi nghĩa bảo quản của hàng đã nhập. Điều kiện
này khác giới hạn lượng lô, có thể phát sinh tự nhiên khi Quản lý kho sửa loại
sản phẩm trên UI. Không tạo trang thực hành hay cho sửa phiếu hoàn tất.

## Tích hợp

- Trigger xử lý tập `inserted`/`deleted`, chỉ xét giá trị bảo quản thực sự đổi;
  nếu một loại vi phạm trong UPDATE nhiều dòng thì toàn câu bị rollback.
- SQL 51825 được API `PUT /api/loai-san-pham/{maLoai}` ánh xạ thành HTTP 409
  `CATEGORY_STORAGE_LOCKED`, thông báo người dùng vẫn sửa được tên/mô tả.
- Procedure nhập giữ khóa chia sẻ HOLDLOCK trên các loại liên quan từ trước
  kiểm tra bảo quản đến khi tạo lô/commit. Sửa loại đồng thời phải chờ và sẽ
  thấy lô đã ghi; nếu sửa trước, nhập đọc yêu cầu mới. Khóa loại trước vị trí.
- Migration 030 DROP trigger cũ, tạo trigger mới và cập nhật procedure nhập;
  chạy lại được. Compose chạy sau migration 027/029 để không để trigger cũ
  sống lại. `init.sql` lấy đúng năm trigger hiện hành từ file gom.

## Giới hạn và trách nhiệm

Trigger trên LO_HANG chỉ chạy khi LO_HANG thay đổi, không tự chặn UPDATE
CT_PHIEU_NHAP. Sau khi bỏ trigger chiều ngược, không tuyên bố nó còn bảo vệ
đường ghi SQL trực tiếp đó. API vẫn khóa chỉ sửa phiếu NHAP, chỉ tạo lô khi
hoàn tất; quản trị SQL không được dùng quyền ghi trực tiếp để sửa chứng từ đã
ghi sổ. Đây là quyết định thay object theo phạm vi và vòng đời ứng dụng hiện tại.

## Demo và kiểm chứng

Quản lý kho mở Loại sản phẩm, chọn loại đã có lô (seed LSP001), đổi Khô sang
Mát, bấm Lưu. API trả 409 do trigger, database giữ Khô, dialog giữ nội dung để
sửa. Chọn lại Khô rồi đổi tên/mô tả sẽ lưu được. Với loại chưa có lô, đổi bảo
quản hợp lệ vẫn lưu được.

Test 024 kiểm tra trigger cũ không còn, trigger mới bật; đổi nhiều loại trong
một câu bị rollback; đổi về NULL bị chặn; sửa tên/cùng yêu cầu được phép; loại
chưa có lô đổi được. Test provider kiểm tra mapping lỗi, role. Browser dùng
form danh mục thật và SQL Server thật. Test nhập 009 giữ ca vượt lượng và
rollback từ trigger lô hiện có.
