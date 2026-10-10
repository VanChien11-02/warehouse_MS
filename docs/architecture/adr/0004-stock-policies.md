# ADR 0004: Quy tắc ghi sổ và định giá tồn kho

- Status: Accepted for BE implementation
- Date: 2026-10-05
- Scope: `DEC-011` đến `DEC-018` trong `OPEN_DECISIONS.md`

Các quyết định này áp dụng cho nhánh triển khai backend theo quyền kỹ thuật đã được giao. Khi tích hợp, chủ repository có thể review và thay đổi bằng một ADR mới cùng contract, script và test liên quan. Chúng không thay thế yêu cầu kiểm thử transaction và concurrency.

| ID | Quyết định | Điều kiện kiểm thử chính |
| --- | --- | --- |
| DEC-011 | Khi hoàn tất nhập, nhà cung cấp phải liên kết với mọi sản phẩm trên phiếu. Khi hoàn tất xuất, đối tác nhận hàng phải liên kết với mọi sản phẩm được xuất. | Thiếu mapping làm toàn phiếu thất bại và tồn không đổi. |
| DEC-012 | `SucChua` là số lượng đơn vị tính gốc có thể chứa tại một vị trí. Các lô có tồn dương cùng vị trí phải có cùng `MaDVT`. | Không nhận sản phẩm khác đơn vị tính vào vị trí đang có tồn; tổng lượng sau ghi sổ không vượt `SucChua`. |
| DEC-013 | Nếu loại sản phẩm có `YeuCauBaoQuan`, giá trị đó phải trùng `KHU_VUC.LoaiKhuVuc` của vị trí nhận hàng. Nếu không có yêu cầu, khu vực bất kỳ hợp lệ. | Nhập/chuyển/trả vào khu vực sai loại bị từ chối. |
| DEC-014 | `LO_HANG.HanSuDung` được phép `NULL`. Lô có hạn đã qua ngày nghiệp vụ không được xuất; lô không có hạn đứng sau mọi lô còn hạn khi gợi ý FEFO. | Gợi ý FEFO sắp đúng thứ tự; không xuất lô hết hạn. |
| DEC-015 | Chỉ `QuanLyKho` được hoàn tất chứng từ nhập, xuất, chuyển, kiểm kê và trả. `NhanVienKho` được lập/sửa nháp và nhập số đếm; `KeToan` chỉ đọc; `Admin` quản trị và đọc. | Gọi API hoàn tất trực tiếp bằng role khác nhận `403`. |
| DEC-016 | Hàng trả `Hư hỏng` chỉ vào vị trí `LoaiViTri = N'Hư hỏng'`; hàng tốt không vào vị trí này. Tồn tại vị trí hư hỏng bị loại khỏi tồn khả dụng và gợi ý FEFO. | Trả sai vị trí thất bại; hàng hỏng không được xuất. |
| DEC-017 | Giá trị tồn dùng đơn giá nhập thực tế của dòng `CT_PHIEU_NHAP` tạo lô; không dùng giá mặc định sản phẩm. | Đổi giá mặc định không làm đổi giá trị tồn của lô đã nhập. |
| DEC-018 | Mọi dòng kiểm kê có chênh lệch khác 0 phải có `LyDoChenhLech`; dòng không chênh lệch không cần lý do. | Hoàn tất phiếu có chênh lệch thiếu lý do bị từ chối và rollback. |

Procedure ghi sổ là nơi kiểm tra các quy tắc nhiều bảng trong cùng transaction; `CHECK` và FK vẫn bảo vệ điều kiện trên từng bảng. Frontend chỉ trình bày gợi ý và lỗi, không tự quyết định số tồn cuối cùng.
