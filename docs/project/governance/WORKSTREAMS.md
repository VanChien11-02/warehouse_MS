# Kế hoạch phát triển song song theo luồng nghiệp vụ

> Trạng thái: **Draft để nhóm xác nhận**. Chỉ chuyển thành `Accepted` sau khi bốn thành viên chốt owner, reviewer, phạm vi và commit baseline. Ma trận object SQL, test và vấn đáp nằm trong [`DBMS_WORK_ASSIGNMENT.md`](DBMS_WORK_ASSIGNMENT.md).

## Bốn workstream

| Luồng | Owner đề xuất | Branch đề xuất | Module chính | Đầu ra xuyên suốt |
| --- | --- | --- | --- | --- |
| Danh mục → nhập lô | TV1 Chiến | `workstream/master-inbound` | `catalog`, `partner`, `warehouse`, `inbound` | Schema/ràng buộc, nhập tạo lô, API/UI, test rollback |
| Tồn → xuất FEFO | TV2 Thi | `workstream/inventory-outbound` | `inventory`, `outbound`, báo cáo xuất/hạn | Tra cứu tồn, xuất FEFO, API/UI, concurrency và hiệu năng |
| Chuyển → kiểm kê | TV3 Trung | `workstream/transfer-count` | `transfer`, `inventorycount`, báo cáo chênh lệch | Hai ghi sổ nguyên tử, snapshot, API/UI, test hai phiên |
| Trả hàng → đối soát và quyền | TV4 Phát | `workstream/return-security` | `returning`, `accounting`, `auth`, `audit` | Trả tốt/hỏng, đối soát, role/audit, API/UI, test quyền |

Owner chịu trách nhiệm đi hết yêu cầu → contract → SQL → backend → frontend → test → tài liệu của module. **Tất cả bốn người** phải làm và giải thích constraint, trigger, view, index, function, procedure, transaction, concurrency và quyền trong phạm vi được giao; không còn vai trò độc quyền theo một chủ đề rubric. Module cuối có phần nền tảng dùng chung, nhưng chỉ TV4 sửa cấu hình auth/role; các owner khác viết test quyền cho luồng của mình.

## Baseline trước khi tách branch

Nhóm chốt một commit/tag chung và ghi vào issue `GOV-02` sau khi review: ERD/tên bảng và cột; URL/JSON/lỗi API; trạng thái chứng từ; request/response P0; public interface Java; chữ ký procedure; cấu trúc thư mục và owner file dùng chung. Bản draft cần chốt tại [`../../../contracts/BASELINE.md`](../../../contracts/BASELINE.md). Bốn branch tạo từ **cùng commit**; không tạo branch từ trạng thái khác nhau rồi tự đổi contract.

## Ranh giới file và object

| Phạm vi | Owner chính | Quy tắc phối hợp |
| --- | --- | --- |
| `services/api/.../catalog`, `partner`, `warehouse`, `inbound` và SQL nhập | TV1 | Thay đổi danh mục/kho ảnh hưởng nghiệp vụ khác cần reviewer consumer. |
| `services/api/.../inventory`, `outbound` và SQL đọc tồn/xuất | TV2 | Tồn cuối cùng do database/backend xác nhận; thay đổi read model cần reviewer TV1/TV3/TV4. |
| `services/api/.../transfer`, `inventorycount` và SQL chuyển/kiểm kê | TV3 | Chỉ gọi public interface tồn; không import repository/module khác. |
| `services/api/.../returning`, `accounting`, `auth`, `audit` và SQL liên quan | TV4 | Ma trận quyền phải khớp contract, role SQL, Spring Security và test. |
| `contracts/`, `database/init.sql`, build/config gốc, router/app shell | Trưởng nhóm hoặc người được chỉ định | Chỉ sửa qua PR nhỏ có reviewer của module tiêu thụ; tránh nhiều branch cùng sửa file chung. |

Object SQL cụ thể và bài test thuộc từng người được liệt kê trong [`DBMS_WORK_ASSIGNMENT.md`](DBMS_WORK_ASSIGNMENT.md). Khi object như `TON_KHO`, view báo cáo hoặc trigger bảo vệ chung chạm nhiều luồng, owner object mở PR và mời các consumer review. Trigger chỉ bảo vệ dữ liệu, không tạo đường ghi sổ thứ hai bên cạnh procedure. Nên giữ một object chính trên một file; `init.sql` chỉ là điểm vào dựng database sạch.

Frontend baseline hiện dùng Vanilla JavaScript. `GOV-03` tách dần `apps/web/app.js` và `styles.css` theo core/feature, giữ hành vi đang chạy; owner cụ thể còn chờ nhóm chốt. Trước khi tách xong, thay đổi UI ở file chung phải qua PR nhỏ và reviewer liên quan. Không đổi framework trong kế hoạch này.

## Thứ tự tích hợp và PR

Các thành viên có thể chuẩn bị code/test song song trên contract đã chốt. Khi ghép bản chạy, thứ tự dependency là: danh mục/kho và auth → nhập/lô/tồn → xuất FEFO → chuyển/kiểm kê/trả hàng → báo cáo và đối soát. Đây là thứ tự tích hợp, không buộc người làm luồng sau chờ mới được bắt đầu.

- Mỗi PR hoàn thành một lát dọc hoặc một ca kiểm chứng; ghi owner, reviewer, acceptance criteria, mã `BR-*`, lệnh test và kết quả.
- Không merge branch workstream của người khác vào branch mình; đồng bộ từ nhánh tích hợp đã chốt. Không force-push branch dùng chung.
- API/schema thay đổi phải cập nhật contract, migration/script, test và tài liệu cùng PR. Module khác chỉ dùng public interface/DTO, không import repository hoặc JPA entity nội bộ.
- Trước bàn giao chạy `pwsh -File scripts/verify.ps1`; nếu có SQL Server, chạy gate DB và concurrency theo hướng dẫn. Chỉ ghi những kiểm tra đã chạy thật.
- Việc đứng tên object hiện hữu là **trách nhiệm kiểm chứng/bảo trì tiếp**, không phải bằng chứng đã tự viết; phụ lục báo cáo lấy PR/test và review thực tế.

## Việc nhóm cần xác nhận

- [ ] Bốn luồng, owner và cân bằng thời gian thực tế.
- [ ] Reviewer vòng đề xuất trong [`TEAM.md`](TEAM.md).
- [ ] Tên branch và nhánh tích hợp (`DEC-019`).
- [ ] Commit baseline và các mục `Cần chốt` trong contract.
- [ ] Người thực hiện `GOV-03` và owner file dùng chung.
