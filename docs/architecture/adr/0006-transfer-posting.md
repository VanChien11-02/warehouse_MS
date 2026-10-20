# ADR 0006: Ghi sổ chuyển kho

- Status: Accepted for BE implementation
- Date: 2026-10-07
- Scope: TRF-01, BR-TRF-001 đến BR-TRF-005

Chuyển kho di chuyển một lô giữa hai vị trí khác nhau mà không đổi tổng số lượng của lô. Procedure khóa header nháp, tất cả vị trí liên quan và các dòng tồn thuộc chúng trước khi đọc số lượng; kiểm tra tổng lượng nguồn theo từng vị trí/lô, sức chứa sau chuyển, đơn vị tính và yêu cầu bảo quản tại đích. Nếu một điều kiện sai, toàn phiếu thất bại, không thay đổi tồn.

Vị trí `Hư hỏng` không được dùng làm nguồn hoặc đích của phiếu chuyển thường. Nghiệp vụ trả hàng/kiểm kê sẽ đưa hàng vào vị trí này theo quy tắc riêng, tránh chuyển hàng hỏng thành tồn khả dụng chỉ bằng một phiếu chuyển.

Sổ `BIEN_DONG_TON_KHO` ghi biến động ròng theo từng vị trí/lô trong cùng transaction với cập nhật tồn và trạng thái phiếu. Nếu một vị trí vừa nhận vừa xuất cùng lô trên một phiếu, chỉ delta ròng khác 0 được ghi để giữ một dòng cho khóa nghiệp vụ. Báo cáo theo kho đọc sổ này, còn tổng lượng trên mọi kho của một phiếu chuyển bằng 0.
