# Contract dữ liệu nhập và tồn kho

- Status: Accepted for BE schema and procedure implementation; HTTP API pending
- Date: 2026-10-07
- Scope: INB-01, INV-01, BR-INB-001 đến BR-INB-007, BR-INV-001 đến BR-INV-005
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_NHAP` có mã `MaPN CHAR(6)`, nhà cung cấp, nhân viên lập, thời điểm tạo UTC, trạng thái `NHAP`/`DA_HOAN_THANH`/`DA_HUY`, ghi chú và thời điểm hoàn tất UTC. `NgayHoanTat` chỉ có giá trị khi trạng thái là `DA_HOAN_THANH`.

`CT_PHIEU_NHAP(MaPN, MaSP)` giữ số lượng nguyên dương và đơn giá nhập thực tế `DECIMAL(19,4)` không âm. `LO_HANG.MaLo` là mã lô; mỗi lô tham chiếu đúng một dòng `(MaPN, MaSP)`, có số lượng nhập nguyên dương, ngày sản xuất/hạn dùng tùy chọn và hạn không trước ngày sản xuất. Tổng lượng lô từ mỗi dòng không được vượt lượng dòng nhập; procedure hoàn tất sẽ kiểm tra trong transaction.

`TON_KHO(MaViTri, MaLo)` giữ tồn theo cặp vị trí/lô, số lượng nguyên không âm. Không lưu số tồn tổng trong sản phẩm. Sản phẩm và đơn vị tính của tồn được truy qua lô → dòng nhập → sản phẩm. Ứng dụng không ghi trực tiếp bảng tồn; các nghiệp vụ hoàn tất dùng procedure kiểm tra sức chứa, đơn vị tính và bảo quản trong cùng transaction.

`SEQ_PHIEU_NHAP` và `SEQ_LO_HANG` cấp số cho mã `PN0001` và `LO0001` theo ADR 0003. Khoảng trống sau rollback là hợp lệ; procedure phải trả lỗi rõ khi vượt không gian bốn chữ số.

`dbo.sp_HoanTatPhieuNhap(@MaPN CHAR(6), @PhanBoJson NVARCHAR(MAX))` là điểm ghi sổ nhập. JSON là array, mỗi phần tử tạo một lô mới:

```json
[{"maSanPham":"SP0001","maViTri":"VT0001","soLuong":10,"ngaySanXuat":"2026-01-01","hanSuDung":"2026-12-31"}]
```

Ngày có thể `null` hoặc bỏ qua. Tổng `soLuong` của các phần tử theo từng `maSanPham` phải **bằng** lượng trên `CT_PHIEU_NHAP` để một phiếu hoàn tất không bỏ sót hàng. Procedure khóa phiếu và vị trí nhận, kiểm tra mapping nhà cung cấp/sản phẩm, ngày lô, loại bảo quản, một đơn vị tính cho mỗi vị trí có tồn dương và sức chứa trước khi tạo lô/tăng tồn. Phiếu phải ở `NHAP`; hoàn tất lặp trả lỗi mà không ghi thêm. Thành công trả result set `maPhieuNhap`, `trangThai`, `ngayHoanTat` UTC.

Mã lỗi SQL ổn định trong dải `51101–51113`: `51101` không thấy phiếu; `51102` trạng thái sai; `51103–51104` JSON/dữ liệu phân bổ sai; `51105` thiếu dòng; `51106` thiếu mapping; `51107–51108` sản phẩm/số lượng không khớp; `51109` vị trí không tồn tại; `51110` bảo quản hoặc loại vị trí sai; `51111` trộn đơn vị; `51112` vượt sức chứa; `51113` hết mã lô. JDBC adapter sẽ ánh xạ các số này sang mã HTTP contract, không trả message SQL thô.

API tạo/sửa/hủy nháp, endpoint gọi procedure và tra cứu tồn sẽ được chốt trong mốc tiếp theo. Hiện chưa có HTTP endpoint nhập hay tồn.
