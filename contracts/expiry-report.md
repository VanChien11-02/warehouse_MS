# Báo cáo lô sắp hết hạn

- Status: Accepted for BE implementation
- Scope: REP-01, BR-INV-004
- Reviewer tích hợp: repository owner và frontend owner

`GET /api/bao-cao/lo-sap-het-han?soNgay=30&maKho=KHO001&page=0&size=20`
chỉ cho `QuanLyKho`; ba vai trò khác nhận 403. `soNgay` mặc định 30,
từ 0 đến 3650; `page` bắt đầu 0 và `size` từ 1 đến 100. `maKho` tùy chọn,
chuẩn hóa chữ hoa, gồm 1–6 ký tự chữ/số.

Ngày nghiệp vụ được tính tại `Asia/Bangkok` trên SQL Server. Chỉ lấy tồn dương
ở vị trí không phải `Hư hỏng`, có `HanSuDung` từ hôm nay đến hết ngày
`hôm nay + soNgay`. Lô đã hết hạn và lô không có hạn không nằm trong báo cáo.
Nguồn là `dbo.fn_LoSapHetHan(@SoNgay)`, phản ánh tồn hiện tại; báo cáo không
thay thế kiểm tra FEFO khi hoàn tất xuất.

Response `{soNgay,items,page,size,totalElements,totalPages}`; mỗi item gồm
`maKho`, `tenKho`, `maViTri`, `tenViTri`, `maLo`, `maSanPham`, `tenSanPham`,
`soLuongTon`, `hanSuDung`, `soNgayConLai`. Sắp hạn gần nhất, rồi kho/vị trí/lô.
Lỗi `422 INVALID_DAYS`, `INVALID_CODE`, `INVALID_PAGINATION`; kiểu tham số sai
trả `400 INVALID_PARAMETER`.
