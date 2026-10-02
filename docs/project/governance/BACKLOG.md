# Product backlog hệ thống quản lý kho

Backlog này giữ phạm vi, ưu tiên và phụ thuộc. Trạng thái thực thi hằng ngày nên nằm trên GitHub Issues/Project.

Ưu tiên: `P0` bắt buộc cho luồng chính/rubric; `P1` cần cho bản cuối kỳ; `P2` chỉ thực hiện khi P0/P1 ổn định.

## Sprint 0 - Baseline và quản trị repository

Mục tiêu: có cấu trúc thống nhất, tài liệu nguồn rõ ràng và frontend demo được.

| ID | Backlog item | Ưu tiên | Owner | Phụ thuộc | Trạng thái/bằng chứng |
| --- | --- | ---: | --- | --- | --- |
| GOV-01 | Chuẩn hóa repository, README, AGENTS và scripts | P0 | Cần chốt | - | Đã có baseline local; chờ nhóm review |
| REQ-01 | Chốt phạm vi, actor và nghiệp vụ kho | P0 | Cần chốt | GOV-01 | ERD/nghiệp vụ đã có; chờ review |
| FE-01 | Dashboard và khung module frontend | P0 | Cần chốt | REQ-01 | Baseline Vanilla JS chạy local |
| QA-00 | Kiểm tra baseline trên máy thành viên khác | P1 | Cần chốt | FE-01 | Chưa có bằng chứng |

## Sprint 1 - CSDL và backend nền tảng

Mục tiêu: dựng SQL Server và Spring Boot, đăng nhập thật và CRUD danh mục qua API.

| ID | Backlog item | Ưu tiên | Owner | Phụ thuộc | Tiêu chí chấp nhận |
| --- | --- | ---: | --- | --- | --- |
| DB-01 | Chốt physical schema và data dictionary | P0 | Cần chốt | REQ-01 | PK/FK/type/null/check/default/unique rõ; script tạo từ database sạch |
| BE-01 | Khởi tạo Spring Boot API | P0 | Cần chốt | DB-01 | Java 21, Maven Wrapper, SQL Server config mẫu, health check và test chạy |
| SEC-01 | Đăng nhập và bốn role | P0 | TV4 Phát | BE-01 | Mật khẩu hash; Admin/QuanLyKho/NhanVienKho/KeToan bị giới hạn đúng quyền |
| CAT-01 | API và UI danh mục sản phẩm | P0 | Cần chốt | BE-01 | CRUD, tìm kiếm, lỗi mã trùng/validation có cấu trúc |
| LOC-01 | Kho, khu vực và vị trí | P0 | Cần chốt | BE-01 | CRUD và kiểm tra sức chứa/loại bảo quản |
| FE-02 | Tách adapter dữ liệu mẫu/API | P0 | Cần chốt | CAT-01 | Chuyển demo/API bằng cấu hình; có loading/error/empty |
| QA-01 | Test nền tảng và traceability | P1 | Cần chốt | SEC-01, CAT-01 | Test auth, quyền, validation và contract |

## Sprint 2 - Nhập, tồn và xuất kho

Mục tiêu: hoàn thành luồng nhập lô → tồn theo vị trí → xuất FEFO.

| ID | Backlog item | Ưu tiên | Owner | Phụ thuộc | Tiêu chí chấp nhận |
| --- | --- | ---: | --- | --- | --- |
| INB-01 | Transaction hoàn tất phiếu nhập | P0 | Cần chốt | CAT-01, LOC-01 | Tạo lô, đưa vào vị trí, tăng tồn nguyên tử; chống hoàn tất hai lần |
| INV-01 | Tra cứu tồn theo sản phẩm/lô/vị trí | P0 | Cần chốt | INB-01 | Lọc kho, vị trí, hạn; truy được chứng từ nguồn |
| OUT-01 | Transaction hoàn tất phiếu xuất | P0 | Cần chốt | INV-01 | Chọn lô còn hạn theo FEFO, trừ đúng vị trí, không âm tồn |
| REP-01 | Báo cáo nhập-xuất-tồn | P0 | Cần chốt | OUT-01 | Báo cáo phản ánh ngay giao dịch đã hoàn tất |
| QA-02 | E2E nhập → tồn → xuất → báo cáo | P0 | Cần chốt | REP-01 | Test dữ liệu sạch, rollback lỗi và payload/API thật |

## Sprint 3 - Chuyển kho, kiểm kê và trả hàng

| ID | Backlog item | Ưu tiên | Owner | Phụ thuộc | Tiêu chí chấp nhận |
| --- | --- | ---: | --- | --- | --- |
| TRF-01 | Chuyển lô giữa hai vị trí | P0 | Cần chốt | INV-01 | Giảm nguồn/tăng đích nguyên tử, kiểm tra sức chứa |
| CNT-01 | Kiểm kê và duyệt điều chỉnh | P0 | Cần chốt | INV-01 | Lưu snapshot hệ thống, chênh lệch và điều chỉnh một lần |
| RET-01 | Trả hàng sau xuất | P1 | Cần chốt | OUT-01 | Không trả vượt lượng xuất; phân loại tốt/hư hỏng và nhập đúng vị trí |
| AUD-01 | Nhật ký thao tác | P1 | Cần chốt | SEC-01 | Ghi tài khoản, thời gian, hành động và dữ liệu trước/sau phù hợp |
| QA-03 | Test concurrency và phục hồi lỗi | P0 | TV3 Trung | OUT-01, TRF-01, CNT-01 | Hai phiên đồng thời không làm âm tồn; rollback không để dữ liệu dở dang |

## Workstream rubric xuyên suốt

| ID | Nội dung | Owner hiện tại | Điều kiện hoàn thành |
| --- | --- | --- | --- |
| DB-R01 | Constraint, trigger, view, index | TV1 Chiến | Đủ số lượng, có ý nghĩa và test/minh chứng |
| DB-R02 | Stored procedure và function | TV2 Thi | Đủ số lượng, xử lý lỗi và được ứng dụng gọi |
| DB-R03 | Transaction và concurrency | TV3 Trung | 5 nghiệp vụ, rollback và demo tranh chấp |
| DB-R04 | Login, role và quyền | TV4 Phát | 4 role, ma trận quyền và GRANT/REVOKE/DENY |

## Sprint 4 - Hoàn thiện và bảo vệ

| ID | Backlog item | Ưu tiên | Owner | Phụ thuộc | Tiêu chí chấp nhận |
| --- | --- | ---: | --- | --- | --- |
| PERF-01 | Hoàn thiện index và đo hiệu năng | P0 | TV1 Chiến | Dữ liệu demo đủ lớn | Lưu query/plan hoặc số đo trước-sau |
| DOC-01 | Báo cáo, sơ đồ và traceability | P0 | Cả nhóm | QA-03 | Yêu cầu → thiết kế → code → test có liên kết |
| REL-01 | Bản chạy sạch và kịch bản demo | P0 | Cả nhóm | DOC-01 | Setup mới chạy được DB/API/web; mỗi thành viên demo phần mình |

## Icebox

- Barcode/scanner phần cứng.
- Mobile native.
- Đồng bộ offline nhiều thiết bị.
- Đa doanh nghiệp/đa chi nhánh phức tạp.
- Tích hợp vận chuyển, thanh toán hoặc kế toán bên ngoài.
