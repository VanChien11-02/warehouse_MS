# Product backlog hệ thống quản lý kho

Backlog này giữ phạm vi, ưu tiên và phụ thuộc. Trạng thái thực thi hằng ngày nên nằm trên GitHub Issues/Project.

Ưu tiên: `P0` bắt buộc cho luồng chính/rubric; `P1` cần cho bản cuối kỳ; `P2` chỉ thực hiện khi P0/P1 ổn định.

## Sprint 0 - Baseline và quản trị repository

Mục tiêu: có cấu trúc thống nhất, tài liệu nguồn rõ ràng và frontend demo được.

| ID | Backlog item | Ưu tiên | Owner | Phụ thuộc | Trạng thái/bằng chứng |
| --- | --- | ---: | --- | --- | --- |
| GOV-01 | Chuẩn hóa repository, README, AGENTS và scripts | P0 | Cần chốt | - | Đã có baseline local; chờ nhóm review |
| REQ-01 | Chốt phạm vi, actor và nghiệp vụ kho | P0 | Cần chốt | GOV-01 | ERD/nghiệp vụ đã có; chờ review |
| GOV-02 | Chốt bốn workstream và contract baseline liên module | P0 | Cần chốt | GOV-01, REQ-01 | `WORKSTREAMS.md` và `contracts/BASELINE.md` chuyển từ Draft sang Accepted; owner/reviewer/branch được xác nhận |
| GOV-03 | Tách frontend baseline theo core/feature | P0 | Cần chốt | GOV-02 | Giữ nguyên hành vi hiện tại; mỗi workstream có thư mục JS/CSS riêng và không phải cùng sửa `app.js`/`styles.css` lớn |
| GOV-04 | Review bộ context dùng để build | P0 | Cần chốt | GOV-02 | Project context, architecture, module, business rules, API catalog, schema plan, build guide và open decisions được nhóm review; nội dung Draft không bị hiểu là Accepted |
| FE-01 | Dashboard và khung module frontend | P0 | Cần chốt | REQ-01 | Baseline Vanilla JS chạy local |
| QA-00 | Kiểm tra baseline trên máy thành viên khác | P1 | Cần chốt | FE-01, GOV-03 | Chưa có bằng chứng |

## Sprint 1 - CSDL và backend nền tảng

Mục tiêu: dựng SQL Server và Spring Boot, đăng nhập thật và CRUD danh mục qua API.

| ID | Backlog item | Ưu tiên | Owner | Phụ thuộc | Tiêu chí chấp nhận |
| --- | --- | ---: | --- | --- | --- |
| DB-01 | Chốt physical schema và data dictionary | P0 | Cần chốt | GOV-02 | PK/FK/type/null/check/default/unique rõ; mapping SQL ↔ Java/JSON rõ; script tạo từ database sạch |
| BE-01 | Khởi tạo Spring Boot API | P0 | Cần chốt | DB-01 | Java 21, Maven Wrapper, SQL Server config mẫu, health check và test chạy |
| SEC-01 | Đăng nhập và bốn role | P0 | TV4 Phát | BE-01 | Mật khẩu hash; Admin/QuanLyKho/NhanVienKho/KeToan bị giới hạn đúng quyền |
| CAT-01 | API và UI danh mục sản phẩm | P0 | Cần chốt | BE-01 | CRUD, tìm kiếm, lỗi mã trùng/validation có cấu trúc |
| LOC-01 | Kho, khu vực và vị trí | P0 | Cần chốt | BE-01 | CRUD và kiểm tra sức chứa/loại bảo quản |
| FE-02 | Tách adapter dữ liệu mẫu/API | P0 | Cần chốt | CAT-01 | Chuyển demo/API bằng cấu hình; có loading/error/empty |
| QA-01 | Test nền tảng và traceability | P1 | Cần chốt | SEC-01, CAT-01 | Test auth, quyền, validation và contract |

Phần bổ sung theo yêu cầu đồng bộ demo/API (2026-10-22), thuộc SEC-01, CAT-01,
LOC-01, FE-02 và các item chứng từ/reporting bên dưới: Admin có ma trận quyền
từ `/api/quyen-han` và gán vai trò qua tài khoản; Quản lý kho có đầy đủ danh mục,
kho/khu vực/vị trí, đối tác/mapping và năm luồng chứng từ nhiều dòng qua API.
Quyết định phân vai tiếp theo cùng ngày: Admin chỉ quản lý nhân viên, tài khoản,
quyền hạn; Nhân viên kho chỉ quản lý tồn và phiếu nhập/xuất; Quản lý kho giữ
phạm vi đã tích hợp. Kế toán đối soát giá trị phiếu nhập/xuất đã hoàn tất theo
quyết định ACC-01 bên dưới. Dashboard API hiển thị dữ liệu
thật và lối vào theo vai trò. Endpoint đọc audit đang tạm đóng chờ phân vai.
Acceptance: phân trang/lọc; CRUD theo contract; sửa/hủy chỉ khi nháp; chốt bởi
QLKHO; kiểm kê lấy snapshot từ server; có loading/empty/error; không rơi về dữ
liệu demo trong chế độ API. Owner triển khai: backend/frontend; reviewer tích
hợp: chủ repository. Bằng chứng và giới hạn nằm trong
[`../../testing/LOCAL_EVIDENCE.md`](../../testing/LOCAL_EVIDENCE.md).

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
| DB-R01 | Constraint, trigger, view, index | Cả bốn owner theo luồng | Đủ số lượng toàn nhóm; mỗi người có object, test và giải thích index trong luồng mình |
| DB-R02 | Stored procedure và function | Cả bốn owner theo luồng | Đủ số lượng toàn nhóm; mỗi người kiểm chứng procedure/function, lỗi và đường gọi từ ứng dụng |
| DB-R03 | Transaction và concurrency | Cả bốn owner theo luồng | Năm nghiệp vụ ghi sổ toàn nhóm; mỗi người có ca commit, rollback, chống lặp và hai phiên/quyền phù hợp |
| DB-R04 | Login, role và quyền | TV4 giữ cấu hình chung; cả bốn kiểm thử theo luồng | Bốn role, ma trận quyền và GRANT/REVOKE/DENY; mỗi người chứng minh cho phép/từ chối trong module mình |

Chi tiết object, ca demo và bằng chứng cá nhân nằm trong [`DBMS_WORK_ASSIGNMENT.md`](DBMS_WORK_ASSIGNMENT.md); trạng thái là đề xuất đến khi nhóm chốt `GOV-02`. Không suy ra tác giả code đã tích hợp từ bảng owner mới.

Bổ sung theo quyết định mới nhất ngày 2026-10-25 (DB-R01/INB-01): bỏ giao diện
và API thực hành trigger. Luồng hoàn tất nhập thật dùng trigger để chặn lượng
lô vượt dòng nhập, procedure chặn phân bổ thiếu và đảm bảo transaction. UI
hiển thị lỗi nghiệp vụ và cho sửa nháp; không cho sửa phiếu hoàn tất. Tiêu chí:
10 so với 6+5 nhận lỗi trigger 51820/HTTP 422; 6+3 bị procedure chặn; 6+4 ghi sổ
đúng một lần; lỗi không để lại lô, tồn, sổ hay audit COMPLETE. Trigger chiều
giảm dòng vẫn bảo vệ cấp bảng, không tạo đường sửa chứng từ trái nghiệp vụ
để trình diễn. Owner triển khai: module nhập; reviewer: chủ repository. Xem
[ADR 0008](../../architecture/adr/0008-inbound-integrity-boundary.md).
Quyết định tiếp theo cùng ngày thay trigger chiều giảm dòng bằng
`trg_LoaiSanPham_BaoVeBaoQuan`: loại đã có lô không đổi yêu cầu bảo quản;
tên/mô tả vẫn sửa được, loại chưa có lô đổi được. Tiêu chí: gỡ trigger cũ ở
database sạch và volume cũ; lỗi thật từ form Loại sản phẩm; UPDATE nhiều dòng
rollback nguyên tử; nhập và quyền hiện tại vẫn đạt. Xem
[ADR 0009](../../architecture/adr/0009-category-storage-history-guard.md).

## Sprint 4 - Hoàn thiện và bảo vệ

Điều chỉnh DOC-01/DB-R01/DB-R02/DB-R03 theo giải thích mới nhất: cần minh
chứng hành vi SQL, không dừng ở tra metadata. Bộ SSMS gồm fixture HS0001,
SELECT xem actual plan, INSERT/UPDATE gây lỗi hai trigger, EXEC6+5 rollback,
EXEC6+4 commit, view/function và chống ghi sổ lặp. Có file dọn đúng fixture;
không đổi object ứng dụng. Hướng dẫn `docs/development/TV1_DEMO_HANH_VI_SSMS.md`.

Bổ sung DOC-01/DB-R01/DB-R02/DB-R03 ngày 2026-10-25: theo yêu cầu học vấn
đáp, đối chiếu bài giảng trong thư mục utexlms do Project Owner cung cấp và
soạn mẫu SQL ngắn cho TV1. Tách lệnh chứng minh object hiện có với mẫu CREATE
để luyện trên bản sao; phân biệt transaction với object lưu trong database.
Tài liệu `docs/development/TV1_HOC_SQL_SSMS.md` và script chỉ đọc
`database/study/01_tv1_kiem_tra_ssms.sql`; không thay SQL/UI nghiệp vụ.

Bổ sung INB-01/INV-01/DB-R01 ngày 2026-10-25: API lịch sử nhập đọc trực tiếp
`vw_LichSuNhapKho` và tab Lịch sử nhập kho trong màn phiếu nhập. Giữ quyền
SQL hiện có QLKHO/KETOAN; lọc mã phiếu/sản phẩm/nhà cung cấp/ngày hoàn tất,
phân trang theo lô; mở chứng từ gốc, giữ nháp khi chuyển tab. Acceptance:
nháp/rollback không xuất hiện, hoàn tất 6+4 có hai dòng và giá trị đúng;
loading/empty/error/retry, role/validation, desktop/mobile. View đã tồn tại,
không đổi schema. Contract tại `contracts/inbound-completion.md`.

Bổ sung INB-01/DB-R02/DB-R03 ngày 2026-10-25: rút gọn thủ tục nhập để trình
bày theo năm bước, không đổi contract hoặc bỏ kiểm tra nghiệp vụ. Gom kiểm
tra đơn vị, chuyển ngày một lần; giữ khóa, thứ tự tạo lô/tồn/sổ và rollback
6+5. Migration 031 cập nhật database hiện có; test 009 bổ sung ngày và hai
chiều trộn đơn vị. Kịch bản thuyết trình tại
[`../../development/INBOUND_WALKTHROUGH.md`](../../development/INBOUND_WALKTHROUGH.md).

### ACC-01 - Đối soát giá trị cho Kế toán

Quyết định Project Owner 2026-10-22: Kế toán xem chứng từ, tồn và báo cáo;
được xác nhận giá trị khớp hoặc ghi nhận chênh lệch trên phiếu nhập/xuất **đã
hoàn tất**. Bản ghi đối soát riêng, tối đa một lần mỗi phiếu, có người/thời điểm
và audit; không thay đổi tồn hoặc trạng thái ghi sổ. Acceptance: API từ chối
phiếu nháp/đối soát lặp và role khác; UI chỉ hiện hành động cho Kế toán; schema
sạch/migration và test theo [`../../../contracts/accounting-reconciliation.md`](../../../contracts/accounting-reconciliation.md).

| ID | Backlog item | Ưu tiên | Owner | Phụ thuộc | Tiêu chí chấp nhận |
| --- | --- | ---: | --- | --- | --- |
| PERF-01 | Hoàn thiện index và đo hiệu năng | P0 | Cả bốn owner theo luồng; TV2 tổng hợp | Dữ liệu demo đủ lớn | Mỗi người lưu query/plan hoặc logical reads trước-sau cho index mình nhận; TV2 tổng hợp kết quả |
| DOC-01 | Báo cáo, sơ đồ và traceability | P0 | Cả nhóm | QA-03 | Yêu cầu → thiết kế → code → test có liên kết |
| REL-01 | Bản chạy sạch và kịch bản demo | P0 | Cả nhóm | DOC-01 | Setup mới chạy được DB/API/web; mỗi thành viên demo phần mình |

## Icebox

- Barcode/scanner phần cứng.
- Mobile native.
- Đồng bộ offline nhiều thiết bị.
- Đa doanh nghiệp/đa chi nhánh phức tạp.
- Tích hợp vận chuyển, thanh toán hoặc kế toán bên ngoài.
