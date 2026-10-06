# ADR 0005: Kiểm tra FEFO khi hoàn tất xuất

- Status: Accepted for BE implementation
- Date: 2026-10-07
- Scope: OUT-01, BR-OUT-002, BR-OUT-003, BR-OUT-007

Phiếu xuất ghi rõ `MaLo` và `MaViTri` cho từng dòng. Gợi ý FEFO trên API/UI không giữ chỗ tồn; dữ liệu có thể đổi trước khi hoàn tất. Vì vậy procedure hoàn tất kiểm tra lại thứ tự FEFO sau khi khóa tồn và trước khi trừ.

Với mỗi sản phẩm, không được lấy từ một lô hạn muộn hơn nếu lô còn hạn sớm hơn vẫn còn tồn khả dụng sau toàn bộ phân bổ trên cùng phiếu. Các lô cùng ngày hạn có thể chọn linh hoạt giữa vị trí. Lô không có hạn đứng sau mọi lô có hạn còn hiệu lực. Lô đã hết hạn và tồn ở vị trí `Hư hỏng` không được xuất và không tham gia thứ tự FEFO.

Ngày nghiệp vụ `Asia/Bangkok` được backend tính rồi truyền vào procedure bằng tham số `DATE`; procedure không dùng giờ hệ điều hành SQL Server để tự suy ngày. Khi hai phiên hoàn tất cạnh tranh, khóa tồn và kiểm tra lại số lượng quyết định kết quả cuối cùng.

Test cần chứng minh: chọn lô muộn bị từ chối khi lô sớm còn tồn; dùng hết lô sớm rồi lấy lô muộn thành công; hoàn tất lặp và thiếu tồn không thay đổi tồn. Các ca lô hết hạn, không hạn và tranh chấp đồng thời thuộc bộ test mở rộng trước khi đánh dấu OUT-01 hoàn thành.
