# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- Quản trị viên quản lý nhân viên, tài khoản đăng nhập và quyền hạn.
- Quản lý kho quản lý hàng hóa, kho bãi, đối tác, chứng từ và báo cáo.
- Nhân viên kho thực hiện nhập kho, xuất kho và tra cứu tồn kho trong ca làm việc.
- Vai trò Kế toán đang có trong backlog bảo mật nhưng phạm vi giao diện cụ thể chưa được chốt.

## Product Purpose

Hệ thống hỗ trợ vận hành kho từ danh mục hàng hóa và vị trí lưu trữ đến nhập, xuất, chuyển, kiểm kê, trả hàng và báo cáo tồn. Bản frontend cần demo trực tiếp được trong khi vẫn sẵn sàng kết nối Spring Boot và SQL Server.

## Positioning

Một không gian vận hành kho thống nhất, trong đó người dùng nhìn thấy đúng tác vụ theo vai trò, theo dõi được chứng từ nguồn và xử lý tồn theo lô/vị trí thay vì chỉ quản lý số lượng tổng.

## Operating Context

Người dùng làm việc với bảng dữ liệu lớn, mã sản phẩm, mã lô, kho, khu vực, vị trí, nhà cung cấp, đối tác nhận hàng và các chứng từ master-detail. Luồng chính là nhập lô, ghi nhận tồn theo vị trí, xuất theo FEFO, chuyển vị trí, kiểm kê và xử lý trả hàng.

## Capabilities and Constraints

- Frontend dùng HTML, CSS và Vanilla JavaScript; không thêm framework hoặc production dependency nếu chưa có backlog/ADR.
- Backend mục tiêu là Java 21, Spring Boot 3.x; database là Microsoft SQL Server và T-SQL.
- API trao đổi JSON qua HTTP và hợp đồng dùng chung nằm trong `contracts/`.
- Frontend không là nguồn sự thật cho phân quyền, tồn cuối cùng hoặc trạng thái hoàn tất chứng từ.
- Chứng từ đã hoàn tất không được sửa/xóa; điều chỉnh phải đi qua nghiệp vụ phù hợp.
- Giao diện cần có loading, empty, error và success state; bảng lớn có tìm kiếm, bộ lọc và phân trang.

## Brand Commitments

- Tên sản phẩm hiện tại: BlueStock.
- Giao diện tiếng Việt.
- Giữ tinh thần editorial của trang tham khảo `web_tham_khao/index (2).html`: nền kem, xanh rừng, xanh sage và màu đất nung, được tiết chế cho bối cảnh ứng dụng vận hành.

## Evidence on Hand

- ERD và quy tắc nghiệp vụ: `docs/architecture/database/ERD_VA_NGHIEP_VU.md`.
- Backlog hiện hành: `docs/project/governance/BACKLOG.md`.
- Baseline frontend chạy local: `apps/web/`.
- Trang tham khảo bố cục và thẩm mỹ: `web_tham_khao/index (2).html`.
- Dữ liệu đang hiển thị ở frontend là dữ liệu minh họa, không phải số liệu vận hành thật.

## Product Principles

- Ưu tiên khả năng quét nhanh và thao tác chính xác trong ca làm việc.
- Cho thấy nguồn gốc tồn kho theo sản phẩm, lô và vị trí.
- Phân quyền giúp giảm nhiễu giao diện nhưng quyền thực thi cuối cùng vẫn do backend kiểm soát.
- Trạng thái chứng từ và cảnh báo phải được hiểu ngay mà không dựa riêng vào màu sắc.
- Mọi màn hình phải đủ rõ để trình diễn độc lập trong buổi bảo vệ.

## Accessibility & Inclusion

Giao diện responsive, điều hướng được bằng bàn phím, có nhãn form rõ ràng, focus dễ nhận biết và không truyền đạt trạng thái chỉ bằng màu.
