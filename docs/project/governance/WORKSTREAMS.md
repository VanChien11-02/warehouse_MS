# Kế hoạch phát triển song song theo workstream

> Trạng thái: **Draft để nhóm thảo luận**. Chỉ chuyển thành `Accepted` sau khi bốn thành viên xác nhận owner, reviewer, phạm vi và baseline contract.

## Mục tiêu

Cho phép bốn thành viên phát triển song song theo module dọc mà không cần chia dự án thành nhiều đợt bàn giao. Mỗi owner chịu trách nhiệm từ database, backend, contract, frontend đến test trong phạm vi của mình.

Việc phát triển song song chỉ bắt đầu sau khi nhóm chốt một commit baseline chung. Baseline này không cần chứa toàn bộ nghiệp vụ, nhưng phải khóa tên, ranh giới module và các interface công khai để tránh mỗi branch tự đặt một kiểu.

## Bốn workstream đề xuất

```text
Nhóm 4 thành viên
├─ TV4 Phát: Nền tảng, xác thực và phân quyền
├─ TV1 Chiến: Danh mục, đối tác và cấu trúc kho
├─ TV2 Thi: Nhập kho, lô hàng và tra cứu tồn
└─ TV3 Trung: Xuất kho và kiểm soát biến động tồn
```

| Workstream | Owner đề xuất | Branch làm việc | Module nhỏ | Đầu ra xuyên suốt |
| --- | --- | --- | --- | --- |
| Nền tảng và bảo mật | TV4 Phát | `workstream/platform-security` | Nhân viên, tài khoản, đăng nhập, role, audit, Spring Security, app shell | SQL security, Auth API, UI đăng nhập/quản trị và test quyền |
| Danh mục và cấu trúc kho | TV1 Chiến | `workstream/master-data-warehouse` | Loại sản phẩm, đơn vị tính, sản phẩm, nhà cung cấp, đối tác, kho, khu vực, vị trí | Schema/ràng buộc, CRUD API/UI, view/index và test validation |
| Nhập kho và tồn | TV2 Thi | `workstream/inbound-inventory` | Phiếu nhập, chi tiết nhập, lô hàng, put-away, tồn theo lô/vị trí, báo cáo tồn | Procedure/function, API/UI nhập-tồn và test hoàn tất lặp |
| Xuất và kiểm soát tồn | TV3 Trung | `workstream/outbound-stock-control` | Xuất FEFO, chuyển kho, kiểm kê, trả hàng | Transaction/procedure, API/UI và test rollback/concurrency |

Workstream cuối có nhiều nghiệp vụ hơn. Owner thực hiện theo thứ tự `Xuất kho → Chuyển kho → Kiểm kê → Trả hàng`; `Kiểm kê` và `Trả hàng` không được làm chậm luồng P0 nhập-tồn-xuất.

## Hai trục trách nhiệm

Owner module chịu trách nhiệm làm cho luồng của mình chạy được. Trách nhiệm rubric trong [`TEAM.md`](TEAM.md) là trục chuyên môn thứ hai, dùng để tạo template và review chéo:

| Thành viên | Module dọc sở hữu | Trách nhiệm chuyên môn xuyên suốt |
| --- | --- | --- |
| TV1 | Danh mục và cấu trúc kho | Constraint, trigger, view, index |
| TV2 | Nhập kho và tồn | Stored procedure, function, `TRY...CATCH` |
| TV3 | Xuất và kiểm soát tồn | Transaction, rollback, concurrency |
| TV4 | Nền tảng và bảo mật | Login, role, permission, audit |

Trách nhiệm chuyên môn không cho phép một thành viên tự sửa file thuộc workstream khác. Khi cần thay đổi, owner module viết thay đổi hoặc hai người thống nhất một PR nhỏ có đồng tác giả/reviewer rõ ràng.

## Baseline bắt buộc trước khi tách branch

Trưởng nhóm tạo một commit/tag baseline sau khi nhóm chốt các mục sau:

1. ERD, tên bảng/cột và data dictionary tối thiểu.
2. Quy ước URL, JSON, ngày giờ, phân trang và lỗi API.
3. Trạng thái chứng từ và chuyển trạng thái hợp lệ.
4. Request/response và mã lỗi của các luồng P0.
5. Chữ ký interface Java được dùng giữa các module.
6. Chữ ký stored procedure hoàn tất chứng từ.
7. Cấu trúc thư mục theo feature và owner của các file dùng chung.

Nội dung draft để chốt nằm tại [`contracts/BASELINE.md`](../../../contracts/BASELINE.md). Sau khi baseline được chấp nhận, bốn branch phải được tạo từ đúng cùng commit đó.

## Ranh giới sở hữu file

| Phạm vi | Owner chính | Quy tắc |
| --- | --- | --- |
| `services/api/.../auth`, cấu hình security và lỗi HTTP chung | TV4 | Module khác chỉ dùng public interface/DTO |
| `services/api/.../catalog`, `partner`, `warehouse` | TV1 | Không truy cập repository từ module khác |
| `services/api/.../inbound`, `inventory`, `reporting` | TV2 | Tồn cuối cùng do database/backend xác nhận |
| `services/api/.../outbound`, `transfer`, `inventorycount`, `returning` | TV3 | Mọi ghi sổ dùng transaction và chống xử lý lặp |
| `contracts/` | Trưởng nhóm + hai phía dùng contract | Thay đổi public contract phải được duyệt trước khi code phụ thuộc |
| `database/init.sql`, build/config gốc, router/app shell | Trưởng nhóm hoặc người được chỉ định | Không để nhiều branch sửa song song |

Database nên dùng một file cho một table/procedure/view/index và chia tiếp theo module. Không gom mọi object vào một script lớn ngoài `init.sql`, vì file lớn sẽ trở thành điểm xung đột của cả nhóm.

## Frontend cần tách trước khi phát triển song song

Baseline hiện tập trung phần lớn hành vi trong `apps/web/app.js` và style trong `apps/web/styles.css`. Trước khi bốn người cùng sửa UI, cần tách dần thành cấu trúc tương đương:

```text
apps/web/
├─ index.html
├─ app.js                       bootstrap tạm thời
├─ src/
│  ├─ core/
│  │  ├─ api-client.js
│  │  ├─ router.js
│  │  ├─ session.js
│  │  └─ errors.js
│  └─ features/
│     ├─ auth/
│     ├─ master-data/
│     ├─ inbound-inventory/
│     └─ outbound-control/
└─ styles/
   ├─ tokens.css
   ├─ components.css
   └─ features/
```

Việc tách file phải giữ nguyên hành vi baseline và được thực hiện trong backlog `GOV-03`. Không đồng thời đổi framework.

## Quy tắc phối hợp tối thiểu

- Branch workstream là vùng làm việc của một owner, không phải nơi gom một PR khổng lồ.
- Mỗi PR chỉ nên hoàn thành một module nhỏ hoặc một lát dọc có thể kiểm tra.
- Không merge trực tiếp branch workstream của người này vào branch workstream của người khác.
- Thay đổi breaking ở schema/API/interface phải cập nhật contract và được duyệt trước khi code phụ thuộc được merge.
- Không import repository, JPA entity hoặc implementation nội bộ của module khác.
- Các branch đồng bộ thường xuyên từ nhánh tích hợp đã thống nhất; không force-push branch dùng chung.
- Trước khi bàn giao chạy `pwsh -File scripts/verify.ps1` và ghi kết quả thật.

## Thứ tự tích hợp, không phải thứ tự phát triển

Bốn người có thể code cùng lúc bằng contract/stub. Khi ghép bản chạy, thứ tự an toàn là:

1. Nền tảng/security và danh mục/cấu trúc kho.
2. Nhập kho, tạo lô và tồn.
3. Xuất kho FEFO.
4. Chuyển kho, kiểm kê, trả hàng và báo cáo hoàn thiện.

Đây chỉ là thứ tự ghép dependency, không yêu cầu thành viên sau phải chờ thành viên trước mới bắt đầu code.

## Các quyết định cần nhóm xác nhận

- [ ] Đồng ý bốn workstream và owner đề xuất.
- [ ] Đồng ý tên bốn branch hoặc chọn tên khác.
- [ ] Chọn nhánh tích hợp: `main` trực tiếp qua PR hay thêm `develop`.
- [ ] Chốt các mục đang đánh dấu `Cần chốt` trong contract baseline.
- [ ] Chỉ định reviewer chính cho từng workstream.
- [ ] Chọn người thực hiện `GOV-03` trước khi frontend được sửa song song.
