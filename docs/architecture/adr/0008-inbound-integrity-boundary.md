# ADR 0008: Ranh giới procedure và trigger của nhập kho

- Status: Accepted theo yêu cầu trực tiếp của Project Owner
- Date: 2026-10-25
- Scope: INB-01, DB-R01, BR-INB-004

Phần giữ `trg_CtPhieuNhap_GioiHanLo` bên dưới đã được thay bằng
[ADR 0009](0009-category-storage-history-guard.md) theo yêu cầu tiếp theo của
Project Owner. Ranh giới thiếu lượng/vượt lượng của procedure và trigger lô
vẫn giữ nguyên; không còn trigger trên bảng chi tiết nhập trong schema hiện hành.

## Bối cảnh

Giao diện vận hành kho phải thực hiện nghiệp vụ thật. Mục thực hành trigger
và endpoint ghi fixture riêng không thuộc sản phẩm và được gỡ. Procedure
trước đây kiểm tra tổng phân bổ bằng dòng nhập trước khi INSERT lô nên trường
hợp vượt bị procedure chặn, không chứng minh được lỗi từ trigger trên UI.

## Quyết định

- `sp_HoanTatPhieuNhap` tiếp tục khóa phiếu/vị trí, kiểm tra cấu trúc phân bổ,
  mapping, bảo quản, đơn vị, sức chứa và trạng thái; chặn phân bổ **thiếu** với
  51108. Chỉ đủ số lượng mới hoàn tất.
- Điều kiện tổng lô **không vượt** dòng nhập do
  `trg_LoHang_GioiHanPhanBo` đảm nhận khi INSERT/UPDATE `LO_HANG` thật. Procedure
  không kiểm tra lại cùng điều kiện trước khi INSERT. Lỗi 51820 truyền qua
  CATCH/THROW; toàn bộ tạo lô, tồn, sổ và trạng thái cùng rollback.
- API ánh xạ 51820 thành 422 `ALLOCATION_EXCEEDS_LINE` với lời hướng dẫn sửa
  lượng phân bổ; 51108 thành 422 `ALLOCATION_INCOMPLETE`. UI giữ dữ liệu nhập
  để người dùng sửa. Không hiển thị tên trigger hay chi tiết JDBC cho người
  vận hành; bằng chứng nguồn lỗi nằm ở test SQL và contract.
- Không đổi thời điểm tạo lô sang phiếu nháp, không cho sửa/xóa phiếu hoàn tất.
  Vì vậy `trg_CtPhieuNhap_GioiHanLo` không có tình huống lỗi có thể thao tác
  bằng UI thông thường trong vòng đời hiện tại. Nó bảo vệ chiều sửa bảng chi
  tiết khi có đường ghi SQL được cấp quyền hoặc luồng bổ sung sau này, tránh
  dữ liệu lô đã có mâu thuẫn với dòng nhập. Test SQL nhiều dòng vẫn cần thiết.

## Ý nghĩa

Procedure điều phối một lần ghi sổ; trigger bảo vệ invariant giữa các bảng
cho mọi đường ghi chạm tới bảng đó. Các lớp có thể cùng bảo vệ dữ liệu, nhưng
không gọi lỗi do procedure phát sinh là bằng chứng trigger chặn. Không mở
thao tác sai nghiệp vụ hoặc làm yếu quyền để buộc tất cả trigger phát lỗi UI.

## Kiểm chứng

- `database/tests/009_inbound_completion.sql`: gọi procedure thật với dòng 10,
  phân bổ 6+5; kiểm tra ERROR_NUMBER 51820 và ERROR_PROCEDURE đúng tên trigger;
  không còn lô/tồn/sổ/audit COMPLETE, phiếu vẫn NHAP. Giữ các ca thiếu lượng,
  sai sức chứa, thiếu mapping và chống hoàn tất lặp.
- `database/tests/024_inventory_guard_triggers.sql`: kiểm tra riêng cả hai
  chiều sửa và câu SQL nhiều dòng, không đặt chức năng này vào ứng dụng.
- Controller/service test kiểm tra thông báo API, role và endpoint thử đã đóng.
- Browser test dùng form nhập thật, đi qua API/SQL Server, thử vượt/thiếu/vị
  trí sai, sửa hợp lệ rồi hoàn tất; tồn chỉ tăng khi thành công.
