# Danh mục module và dependency

> Trạng thái: **Draft kỹ thuật**, dùng để chia phạm vi build. Tên package/route chi tiết chỉ trở thành bắt buộc khi code và contract tương ứng được Accepted.

## Danh mục module

| Module | Workstream | Trách nhiệm | Bảng chính | Phụ thuộc trực tiếp |
| --- | --- | --- | --- | --- |
| `auth` | Platform/security | Nhân viên, tài khoản, đăng nhập, role và principal | `NHAN_VIEN`, `TAI_KHOAN`, `ROLE` | - |
| `audit` | Platform/security | Lưu và tra cứu thao tác quan trọng | `LICH_SU_THAO_TAC` | auth |
| `catalog` | Master data | Loại SP, đơn vị tính, sản phẩm | `LOAI_SAN_PHAM`, `DON_VI_TINH`, `SAN_PHAM` | - |
| `partner` | Master data | Nhà cung cấp, đối tác nhận hàng và sản phẩm liên kết | `NHA_CUNG_CAP`, `DOI_TAC_NHAN_HANG`, hai bảng liên kết | catalog |
| `warehouse` | Master data | Kho, khu vực, vị trí và sức chứa | `KHO`, `KHU_VUC`, `VI_TRI_KHO` | - |
| `inbound` | Inbound/inventory | Phiếu nhập, chi tiết, tạo lô và put-away | `PHIEU_NHAP`, `CT_PHIEU_NHAP`, `LO_HANG` | catalog, partner, warehouse, auth |
| `inventory` | Inbound/inventory | Tồn theo lô/vị trí và truy vấn tồn | `TON_KHO` | inbound, warehouse |
| `outbound` | Outbound/control | Phiếu xuất, FEFO và trừ tồn | `PHIEU_XUAT`, `CT_PHIEU_XUAT` | catalog, partner, inventory, auth |
| `transfer` | Outbound/control | Chuyển lô giữa vị trí | `PHIEU_CHUYEN_KHO`, `CT_PHIEU_CHUYEN_KHO` | inventory, warehouse, auth |
| `inventorycount` | Outbound/control | Kiểm kê, snapshot và điều chỉnh | `PHIEU_KIEM_KE`, `CT_KIEM_KE` | inventory, warehouse, auth |
| `returning` | Outbound/control | Trả hàng dựa trên phiếu xuất gốc | `PHIEU_TRA_HANG`, `CT_PHIEU_TRA_HANG` | outbound, inventory, warehouse, auth |
| `reporting` | Inbound/inventory | Tồn, nhập-xuất, hạn dùng, chênh lệch | View/query model, không sở hữu transaction table | inventory, inbound, outbound, inventorycount |

## Public surface dự kiến

| Module cung cấp | Public query/use case | Consumer chính |
| --- | --- | --- |
| auth | current user, role/permission check | mọi module có bảo vệ quyền |
| catalog | snapshot sản phẩm đang hoạt động | inbound, outbound, reporting |
| partner | snapshot nhà cung cấp/đối tác hợp lệ | inbound, outbound |
| warehouse | snapshot vị trí và sức chứa | inbound, inventory, transfer, count, returning |
| inbound | tạo/sửa nháp, hoàn tất phiếu nhập | web, reporting |
| inventory | truy vấn tồn theo sản phẩm/lô/vị trí | outbound, transfer, count, reporting |
| outbound | gợi ý FEFO, hoàn tất phiếu xuất | web, returning, reporting |
| transfer | hoàn tất chuyển kho | web, reporting |
| inventorycount | hoàn tất kiểm kê | web, reporting |
| returning | hoàn tất trả hàng | web, reporting |
| reporting | các read model báo cáo | web, role kế toán/quản lý |
| audit | ghi/tra cứu audit phù hợp quyền | use case quan trọng, admin |

## Quy tắc module

- Module sở hữu bảng và package của mình; consumer không đọc repository nội bộ.
- Query chéo module dùng public port/DTO hoặc database view đã được owner chấp nhận.
- Ghi tồn chỉ đi qua use case/procedure nghiệp vụ tương ứng.
- Không tạo hai DTO công khai khác tên nhưng cùng nghĩa cho mã sản phẩm, vị trí, lô hoặc trạng thái.
- Không tạo package dùng chung để chứa toàn bộ entity/service. `shared` chỉ dành cho kiểu kỹ thuật thật sự chung như error envelope, clock hoặc pagination.

## Ma trận quyền mức module

Ma trận dưới đây là baseline để thiết kế, chưa thay thế test security chi tiết.

| Module | Admin | QuanLyKho | NhanVienKho | KeToan |
| --- | --- | --- | --- | --- |
| Auth/account | Quản trị | Xem hồ sơ cần thiết | Xem hồ sơ mình | Xem hồ sơ mình |
| Catalog/partner | CRUD | CRUD | Đọc | Đọc |
| Warehouse topology | CRUD | CRUD | Đọc | Đọc |
| Inbound/outbound/transfer | Xem/quản trị | Lập và hoàn tất | Lập/thao tác theo quyền | Xem |
| Inventory count | Xem/quản trị | Lập và hoàn tất | Nhập kết quả theo quyền | Xem |
| Returning | Xem/quản trị | Lập và hoàn tất | Tiếp nhận theo quyền | Xem |
| Reporting | Xem | Xem | Xem giới hạn | Xem giá trị |
| Audit | Xem | Xem giới hạn | Không hoặc chỉ thao tác mình | Không hoặc xem giới hạn |

Các ô còn mơ hồ phải được cụ thể hóa trong contract Session/RBAC và security test trước khi endpoint tương ứng được Accepted.

## Definition of module complete

Một module chỉ được coi là hoàn thành khi có:

1. Contract endpoint/DTO và role được Accepted.
2. Schema/object SQL cần thiết dựng được từ database sạch.
3. Backend controller → application service → adapter đúng ranh giới.
4. Frontend dùng API adapter, có loading/empty/error/success.
5. Test thành công, validation, quyền và rollback phù hợp.
6. Bằng chứng demo và liên kết backlog/requirement.
