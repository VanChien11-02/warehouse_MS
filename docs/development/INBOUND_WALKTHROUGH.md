# Trình bày thủ tục hoàn tất nhập và transaction

Code chạy thật: [`../../database/procedures/procedures.sql`](../../database/procedures/procedures.sql),
thủ tục đầu tiên `dbo.sp_HoanTatPhieuNhap`. Database cũ nâng cấp bằng
[`../../database/migrations/031_simplify_inbound_completion.sql`](../../database/migrations/031_simplify_inbound_completion.sql).
Không đổi tham số, kết quả trả về hoặc mã lỗi. Không tách validation sang
procedure phụ và không bỏ quy tắc để làm code ngắn.

## Đầu vào

- `@MaPN`: mã phiếu nháp cần hoàn tất.
- `@PhanBoJson`: danh sách sản phẩm, vị trí, số lượng, ngày sản xuất/hạn dùng từ UI.
- `@MaTK`: tài khoản thực hiện, dùng ghi nhật ký; API lấy từ phiên đăng nhập.

## Năm bước trong code

| Bước | Việc thực hiện | Mục đích |
| --- | --- | --- |
| 1 | Khóa phiếu, kiểm tra tồn tại và `NHAP` | Hai yêu cầu không thể cùng hoàn tất phiếu thành công |
| 2 | Đọc JSON vào bảng biến, chuyển ngày, kiểm tra sản phẩm/mapping/lượng | Dữ liệu hợp lệ và phân bổ không thiếu; vượt lượng do trigger lô chặn ở bước 4 |
| 3 | Khóa loại, vị trí; kiểm tra bảo quản, đơn vị tính, sức chứa | Vị trí nhận phù hợp và dữ liệu được bảo vệ trong lúc ghi sổ |
| 4 | Duyệt phân bổ; cấp mã và INSERT lô → tồn → sổ biến động | Mỗi phân bổ tạo một lô cùng tồn tại vị trí và một dòng tăng tồn |
| 5 | Đổi trạng thái, ghi audit, COMMIT | Công nhận phiếu hoàn tất sau khi toàn bộ ghi sổ thành công |

`@PhanBo` là bảng biến giữ dữ liệu đầu vào của lời gọi; không phải bảng tồn
chính thức. `UNION ALL` trong bước 3 ghép đơn vị của hàng sắp nhập với hàng
đang có tồn dương, rồi `COUNT(DISTINCT MaDVT) > 1` phát hiện trộn đơn vị.
Các cột ngày được chuyển một lần và dùng lại khi kiểm tra/tạo lô.

## Khung transaction để nói trước

Đây là sơ đồ đọc code; không phải script SQL để chạy riêng:

```text
SET XACT_ABORT ON
BEGIN TRY
    BEGIN TRANSACTION
    1. Khóa và kiểm tra phiếu
    2. Đọc, kiểm tra phân bổ
    3. Khóa và kiểm tra vị trí nhận
    4. Tạo từng lô → tăng tồn → ghi sổ
    5. Đổi trạng thái → ghi audit
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    Nếu còn transaction: ROLLBACK TRANSACTION
    THROW để API nhận lỗi và UI thông báo
END CATCH
```

`SET XACT_ABORT ON` giúp transaction bị hủy hoặc không thể commit khi gặp
lỗi thực thi; `CATCH` kiểm tra `XACT_STATE()` và rollback nếu còn transaction.
`THROW;` chuyển tiếp lỗi gốc, kể cả lỗi trigger. Khóa `UPDLOCK, HOLDLOCK` trên
phiếu được giữ trong transaction để yêu cầu thứ hai phải đợi và kiểm tra lại
trạng thái sau khi yêu cầu thứ nhất kết thúc.

## Demo trên UI

Đăng nhập Quản lý kho, mở chế độ API. Chọn sản phẩm/nhà cung cấp đã liên kết,
hai vị trí đúng bảo quản, cùng đơn vị và đủ sức chứa. Ghi lại tồn ban đầu `T`.

1. Vào **Phiếu nhập kho → Phiếu mới**, thêm dòng số lượng **10**, giá hợp lệ,
   bấm **Lưu nháp**, ghi lại mã phiếu.
2. Phân bổ **6** vào vị trí thứ nhất, **5** vào vị trí thứ hai; bấm **Hoàn tất**.
   UI báo tổng phân bổ vượt lượng nhập. Phiếu còn nháp, tồn vẫn `T`.
3. Giải thích: vòng lặp đã INSERT lô/tồn/sổ cho lượng 6. Khi INSERT lô 5,
   trigger phát lỗi 51820 vì tổng 11 > 10. Procedure vào CATCH và rollback
   cả phần 6 đã ghi trước đó. Test SQL 009 kiểm chứng không còn lô/tồn/sổ/audit
   COMPLETE của lần thất bại; UI cho thấy kết quả nghiệp vụ.
4. Sửa phân bổ thành **6 + 4**, bấm **Hoàn tất**. Phiếu hoàn tất, hai lô có
   lượng 6 và 4, tồn tăng thành `T + 10`: toàn bộ transaction được commit.
5. Mở lại phiếu: chỉ xem, không sửa chứng từ hoàn tất. Cơ chế chặn gọi lại
   procedure còn được kiểm tra bởi test SQL 009; ẩn nút trên UI không tự nó
   chứng minh database đã chặn ghi sổ lặp.

Khi tải lại phiếu nháp, cần điền lại phân bổ vì phân bổ chưa được lưu trong
nháp. Nút Hoàn tất lưu nháp bằng một request riêng trước khi gọi ghi sổ;
rollback của procedure không xóa phiếu nháp đã lưu. Sequence cấp mã không
hoàn lại số khi rollback, nên mã lô bị nhảy số không có nghĩa là sót lô.

## Demo view lịch sử trên UI

Đăng nhập QLKHO/KETOAN tại `http://127.0.0.1:5174/?mode=api#inbound`, chọn tab
**Lịch sử nhập kho**. Nhập mã phiếu vào bộ lọc rồi bấm **Tra cứu**.

- Phiếu nháp hoặc lần hoàn tất rollback: không có dòng lịch sử của phiếu đó.
- Hoàn tất 6+4 với giá 12.500: hai dòng theo hai lô, giá trị nhập 75.000/50.000.
- Bấm mã phiếu trong bảng để mở lại chứng từ gốc; các tab giữ nháp đang nhập.
- Có thể lọc thêm mã sản phẩm, nhà cung cấp và ngày hoàn tất UTC, xóa bộ lọc,
  làm mới hoặc chuyển trang (20 lô/trang).

Luồng dữ liệu: UI → `GET /api/phieu-nhap/lich-su` → application service →
`InboundJdbcRepository.findHistory` → `SELECT ... FROM dbo.vw_LichSuNhapKho`.
View JOIN bốn bảng và chỉ lấy phiếu hoàn tất; Java không dựng lại logic đó.
Lịch sử giữ **lượng nhập ban đầu** sau khi xuất hàng; tồn hiện tại xem ở Tồn kho.

## Lời trình bày thủ tục khoảng một phút

“Khi người dùng bấm Hoàn tất, API gọi sp_HoanTatPhieuNhap với mã phiếu và
danh sách phân bổ. Thủ tục mở transaction, khóa phiếu để chống hoàn tất hai
lần, rồi kiểm tra dữ liệu và vị trí nhận hàng. Với mỗi phân bổ, thủ tục tạo
lô, thêm tồn tại vị trí và ghi sổ biến động. Sau đó cập nhật trạng thái và
ghi tài khoản thực hiện. Nếu mọi bước thành công thì COMMIT. Nếu có lỗi,
kể cả lỗi trigger, CATCH rollback toàn bộ và trả lỗi về UI. Ví dụ dòng nhập
10 nhưng phân bổ 6 và 5: lỗi ở lô thứ hai sẽ hủy cả lô, tồn và sổ đã ghi cho
lượng 6, nên hệ thống không bị nhập dở dang.”
