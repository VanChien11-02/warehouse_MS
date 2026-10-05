# Danh mục quy tắc nghiệp vụ

Các mã trong tài liệu này dùng để liên kết requirement → contract → code → test. Nội dung được rút từ ERD/backlog hiện hành; mục có chữ **Cần chốt** chưa phải quyết định Accepted.

## Xác thực và phân quyền

| Mã | Quy tắc | Test tối thiểu |
| --- | --- | --- |
| BR-SEC-001 | Mật khẩu chỉ được lưu dạng hash, không log password/token | Không tìm thấy password rõ trong DB/log |
| BR-SEC-002 | Endpoint mặc định bị từ chối nếu chưa khai báo quyền | Anonymous nhận `401`; role sai nhận `403` |
| BR-SEC-003 | Một nhân viên có tối đa một tài khoản | Insert tài khoản thứ hai cho cùng `MaNV` thất bại |
| BR-SEC-004 | Tài khoản bị khóa không đăng nhập được | Login thất bại nhưng không lộ nguyên nhân nhạy cảm |
| BR-SEC-005 | Frontend không phải nguồn sự thật về quyền | Gọi API trực tiếp bằng role sai vẫn bị từ chối |

## Danh mục và cấu trúc kho

| Mã | Quy tắc | Test tối thiểu |
| --- | --- | --- |
| BR-CAT-001 | Mã sản phẩm, kho, khu vực, vị trí và đối tác phải duy nhất theo schema đã chốt | Tạo mã trùng trả lỗi có cấu trúc |
| BR-CAT-002 | Giá mặc định không âm; tiền dùng `DECIMAL`/`BigDecimal` | Giá âm bị từ chối, số thập phân không dùng FLOAT |
| BR-WHS-001 | Khu vực phải thuộc một kho; vị trí phải thuộc một khu vực | FK sai bị từ chối |
| BR-WHS-002 | Sức chứa là số đơn vị tính gốc; tồn dương tại một vị trí chỉ dùng một `MaDVT` | Từ chối trộn đơn vị tính hoặc vượt `SucChua` |
| BR-WHS-003 | `YeuCauBaoQuan` của loại sản phẩm phải trùng loại khu vực nếu có giá trị | Nhập/chuyển/trả vào khu vực sai loại bị từ chối |

## Nhập kho và lô

| Mã | Quy tắc | Test tối thiểu |
| --- | --- | --- |
| BR-INB-001 | Chỉ phiếu nháp được thêm/sửa/xóa dòng | Sửa phiếu hoàn tất bị từ chối |
| BR-INB-002 | Số lượng nhập lớn hơn 0, đơn giá không âm | Boundary 0/âm bị từ chối |
| BR-INB-003 | `HanSuDung >= NgaySanXuat` khi cả hai có giá trị | Lô có hạn trước ngày sản xuất thất bại |
| BR-INB-004 | Tổng lượng lô tạo từ một dòng không vượt số lượng dòng nhập | Tạo lô vượt lượng bị rollback |
| BR-INB-005 | Hoàn tất nhập tạo lô/put-away/tăng tồn trong một transaction | Lỗi giữa chừng không để lô/tồn dở dang |
| BR-INB-006 | Một phiếu nhập chỉ được ghi sổ một lần | Gọi hoàn tất lần hai không đổi tồn |
| BR-INB-007 | Nhà cung cấp phải liên kết với mọi sản phẩm trước khi hoàn tất nhập | Thiếu mapping làm toàn phiếu thất bại và tồn không đổi |

## Tồn kho

| Mã | Quy tắc | Test tối thiểu |
| --- | --- | --- |
| BR-INV-001 | Tồn được quản lý theo khóa `(MaViTri, MaLo)` | Cùng lô ở hai vị trí cho hai dòng tồn riêng |
| BR-INV-002 | `SoLuongTon` không âm | Mọi đường cập nhật âm đều bị chặn |
| BR-INV-003 | Đọc-kiểm tra-cập nhật tồn nằm trong một transaction có khóa phù hợp | Hai phiên xuất đồng thời không vượt tồn |
| BR-INV-004 | Tra cứu tồn truy được sản phẩm, lô, vị trí và chứng từ nguồn | Response/view có khóa truy vết |
| BR-INV-005 | Frontend không gửi số tồn cuối cùng để database tin trực tiếp | Server tự tính sau transaction |

## Xuất kho

| Mã | Quy tắc | Test tối thiểu |
| --- | --- | --- |
| BR-OUT-001 | Số lượng xuất lớn hơn 0 và không vượt tồn tại lô/vị trí | Thiếu tồn trả lỗi, không âm tồn |
| BR-OUT-002 | Chỉ lô chưa hết hạn được xuất | Lô hết hạn không xuất được |
| BR-OUT-003 | Hệ thống ưu tiên lô có hạn gần nhất theo FEFO | Dữ liệu nhiều lô chọn đúng thứ tự |
| BR-OUT-004 | Chi tiết xuất phải chỉ rõ `MaLo` và `MaViTri` | Payload thiếu nguồn tồn bị từ chối |
| BR-OUT-005 | Hoàn tất xuất và trừ tồn là nguyên tử, chống hoàn tất lặp | Lỗi/nhấn hai lần không trừ hai lần |
| BR-OUT-006 | Đối tác phải liên kết với mọi sản phẩm trước khi hoàn tất xuất | Thiếu mapping làm toàn phiếu thất bại và tồn không đổi |
| BR-OUT-007 | Lô không có hạn dùng đứng sau lô còn hạn; lô hết hạn không được xuất | Gợi ý và hoàn tất xử lý đúng cả ba trường hợp |

## Chuyển kho

| Mã | Quy tắc | Test tối thiểu |
| --- | --- | --- |
| BR-TRF-001 | Vị trí nguồn và đích phải khác nhau | Cùng vị trí bị từ chối |
| BR-TRF-002 | Lượng chuyển không vượt tồn nguồn | Thiếu tồn rollback toàn phiếu |
| BR-TRF-003 | Lượng sau chuyển không vượt sức chứa đích | Vượt sức chứa bị từ chối |
| BR-TRF-004 | Giảm nguồn và tăng đích trong cùng transaction | Lỗi bước tăng đích khôi phục nguồn |
| BR-TRF-005 | Phiếu chuyển chỉ ghi sổ một lần | Hoàn tất lặp không đổi tồn |

## Kiểm kê

| Mã | Quy tắc | Test tối thiểu |
| --- | --- | --- |
| BR-CNT-001 | Phiếu lưu số lượng hệ thống tại thời điểm snapshot và số thực tế | Dữ liệu snapshot không bị UI tính lại |
| BR-CNT-002 | Mọi chênh lệch khác 0 phải có lý do | Hoàn tất thiếu lý do bị từ chối và rollback |
| BR-CNT-003 | Điều chỉnh tồn chỉ xảy ra khi hoàn tất/duyệt và chỉ một lần | Nháp không đổi tồn; hoàn tất lặp không đổi tồn |
| BR-CNT-004 | Điều chỉnh không được tạo tồn âm | Số thực tế/logic sai bị từ chối |

## Trả hàng

| Mã | Quy tắc | Test tối thiểu |
| --- | --- | --- |
| BR-RET-001 | Phiếu trả tham chiếu phiếu xuất gốc | `MaPX` không hợp lệ bị từ chối |
| BR-RET-002 | Lượng trả cộng dồn theo phiếu xuất/lô không vượt lượng đã xuất | Trả vượt bị rollback |
| BR-RET-003 | Dòng trả phân loại `Tốt` hoặc `Hư hỏng` theo enum đã chốt | Giá trị ngoài enum bị từ chối |
| BR-RET-004 | Hàng hư hỏng chỉ vào vị trí `Hư hỏng` và không còn khả dụng để xuất | Trả sai vị trí bị từ chối; FEFO bỏ qua tồn hư hỏng |
| BR-RET-005 | Hoàn tất trả và tăng tồn phù hợp là nguyên tử, chỉ một lần | Lỗi/hoàn tất lặp không tăng hai lần |

## Chứng từ và audit dùng chung

| Mã | Quy tắc | Test tối thiểu |
| --- | --- | --- |
| BR-DOC-001 | Chỉ chứng từ nháp được sửa/xóa | Mọi loại phiếu hoàn tất đều bất biến |
| BR-DOC-002 | Chứng từ hoàn tất không bị xóa vật lý để sửa nhanh | Có nghiệp vụ đảo/điều chỉnh phù hợp |
| BR-DOC-003 | Mọi lần hoàn tất kiểm tra trạng thái trong cùng transaction | Race hoàn tất chỉ một request thành công |
| BR-AUD-001 | Thao tác quan trọng ghi actor, thời gian, hành động và bản ghi | Audit truy được theo tài khoản/thời gian |
| BR-AUD-002 | Audit không lưu password/token/connection string | Kiểm tra dữ liệu audit/log |

## Báo cáo

| Mã | Quy tắc | Test tối thiểu |
| --- | --- | --- |
| BR-REP-001 | Báo cáo tồn phản ánh transaction đã commit, không tính phiếu nháp | So sánh trước/sau hoàn tất |
| BR-REP-002 | Giá trị tồn dùng đơn giá nhập thực tế theo lô và `DECIMAL` | Đổi giá mặc định sản phẩm không làm đổi giá trị tồn đã ghi sổ |
| BR-REP-003 | Báo cáo nhập-xuất lọc thời gian có boundary thống nhất | Test đầu/cuối ngày theo timezone đã chốt |
| BR-REP-004 | Báo cáo là read model, không sửa dữ liệu nghiệp vụ | Endpoint báo cáo chỉ đọc |

## Quy tắc sử dụng mã

- Test và contract nên tham chiếu mã `BR-*` liên quan.
- Nếu thay đổi nghĩa của quy tắc, cập nhật ERD/backlog/contract và test trong cùng PR.
- Không đánh dấu quy tắc “đạt” chỉ vì có constraint/object; phải có test chứng minh luồng thành công và thất bại.
