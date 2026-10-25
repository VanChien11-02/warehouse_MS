# Phân công DBMS theo bốn luồng nghiệp vụ

> Trạng thái: **Đề xuất để bốn thành viên xác nhận**. Đây là việc cần làm và luyện vấn đáp từ hiện tại, không ghi nhận tác giả của code đã tích hợp. Nhóm chốt owner, reviewer và commit baseline trong `GOV-02`.

## Cách hiểu yêu cầu chia đều

Rubric DBMS330284 yêu cầu **toàn nhóm** tối thiểu 5 ràng buộc có ý nghĩa, 5 trigger, 5 view, 5 index, 5 stored procedure, 5 function, 5 nghiệp vụ transaction và 4 role/login. Không nhân các mức tối thiểu này lên bốn lần. Để mỗi người học đủ, mỗi thành viên phải trực tiếp kiểm tra hoặc cải thiện **ít nhất một** ví dụ của từng loại trong luồng mình sở hữu, có test và giải thích được khi vấn đáp.

| Kiến thức mỗi người phải nắm | Đầu ra cá nhân tối thiểu |
| --- | --- |
| ERD, chuẩn hóa, kiểu dữ liệu, PK/FK | Giải thích các bảng/quan hệ chính, phụ thuộc hàm, lý do đạt 3NF và khóa ghép nếu có. |
| Ràng buộc | Chọn một `CHECK`/`UNIQUE`/`DEFAULT` và một PK/FK; chạy ca hợp lệ và ca bị từ chối. |
| Trigger | Kiểm tra `inserted`/`deleted` nhiều dòng, rollback toàn lệnh và một ca hợp lệ. |
| View và function | Đối chiếu ít nhất một view và một UDF với bảng nguồn, ca rỗng/`NULL` và phiếu nháp. |
| Index | Lưu truy vấn thật, plan hoặc `STATISTICS IO` trước/sau trên cùng dữ liệu; giải thích chi phí ghi. |
| Procedure và T-SQL | Giải thích tham số, `TRY...CATCH`, `THROW`, `XACT_ABORT`, đường gọi từ API và một ca lỗi. |
| Transaction, đồng thời, phục hồi | Chứng minh commit, rollback, chống hoàn tất lặp; giải thích khóa/isolation và thử hai phiên hoặc tình huống khôi phục. |
| Bảo mật và tích hợp | Thử role được phép/bị từ chối ở SQL/API; lần theo màn hình → API → procedure/view → bảng. |

Không coi việc đứng tên object hiện hữu là đóng góp mới. Mỗi người **tự viết SQL test/bộ dữ liệu kiểm chứng** cho constraint, trigger, view, function và procedure mình nhận; tự chạy phép đo index và trình bày transaction. PR ghi rõ test hoặc cải tiến do mình làm. Chỉ sửa object production khi có lỗi hoặc cải tiến đã đo được; không tạo object dư thừa để lấy số lượng.

## Bốn luồng và khối lượng

| Thành viên | Luồng chính và backlog | Kịch bản demo của riêng mình | Phạm vi phụ trợ |
| --- | --- | --- | --- |
| TV1 Chiến | Danh mục, đối tác, kho → nhập lô (`CAT-01`, `LOC-01`, `INB-01`) | Tạo sản phẩm/NCC/vị trí → lập nhập → hoàn tất → lô/tồn tăng; phân bổ vượt lượng rollback. | Mapping NCC, sức chứa, bảo quản. |
| TV2 Thi | Tra tồn → xuất FEFO → báo cáo xuất (`INV-01`, `OUT-01`, `REP-01`) | Tra lô → xuất theo FEFO → tồn giảm và lịch sử đúng; lô hết hạn/sai FEFO bị từ chối. | Tồn theo lô/vị trí và query plan FEFO. |
| TV3 Trung | Chuyển vị trí → kiểm kê (`TRF-01`, `CNT-01`, `QA-03`) | Chuyển nguồn/đích nguyên tử → snapshot kiểm kê → điều chỉnh; đích đầy/snapshot cũ rollback. | Hai phiên cạnh tranh, thứ tự khóa. |
| TV4 Phát | Trả hàng → đối soát/audit/quyền (`RET-01`, `AUD-01`, `ACC-01`, `SEC-01`) | Trả tốt/hỏng từ phiếu xuất → đối soát, audit, kiểm role; trả vượt lượng bị từ chối. | Tài khoản, role và ma trận quyền dùng chung. |

TV3 có hai thủ tục ghi sổ; TV4 có bảo mật và đối soát; TV1 có nhiều dữ liệu nền; TV2 có FEFO, tồn và báo cáo. Cân bằng theo **thời gian, độ khó, test và tài liệu**, không ép số bảng hoặc số dòng SQL bằng nhau. Cuối mỗi tuần so PR đã review, ca test và thời gian thực tế để chuyển việc phụ trợ nếu lệch.

## Object SQL để thực hành và bảo vệ

Các object sau **đã có trong repo**. Người nhận chịu trách nhiệm kiểm chứng và thay đổi có căn cứ trong PR tới, không nhận lại công lao của người viết trước. Object dùng chung có một owner, các module còn lại làm consumer/reviewer.

| TV | Ràng buộc/quan hệ | Trigger | View | Function | Index và truy vấn | Procedure/transaction |
| --- | --- | --- | --- | --- | --- | --- |
| TV1 | `CT_PHIEU_NHAP.SoLuong > 0`, FK lô → dòng nhập, hạn dùng lô | `trg_LoHang_GioiHanPhanBo`, `trg_LoaiSanPham_BaoVeBaoQuan` | `vw_LichSuNhapKho` | `fn_TonTheoLo` | `IX_PHIEU_NHAP_NGAY_MA`: phiếu nhập mới nhất | `sp_HoanTatPhieuNhap`: tạo lô, put-away, tăng tồn, ghi sổ cùng transaction |
| TV2 | `TON_KHO(MaViTri, MaLo)`, tồn không âm, xuất chỉ rõ lô/vị trí | `trg_TonKho_BaoVeViTri` | `vw_TonKhoChiTiet`, `vw_LichSuXuatKho`, `vw_LoSapHetHan` | `fn_TonKhaDungTaiViTri`, `fn_LoSapHetHan` | `IX_LO_HANG_SAN_PHAM_HAN` cho FEFO; `IX_TON_KHO_LO_VI_TRI` cho tồn | `sp_HoanTatPhieuXuat`: khóa tồn, kiểm FEFO, trừ tồn, chống lặp |
| TV3 | Nguồn khác đích, lượng chuyển dương, snapshot/lý do kiểm kê | `trg_ViTriKho_BaoVeTon` | `vw_ChenhLechKiemKe`, `vw_TonKhoTheoSanPham` | `fn_TonTheoSanPham` | `IX_BIEN_DONG_TON_KHO_NGAY`: biến động theo kỳ | `sp_HoanTatChuyenKho`, `sp_HoanTatKiemKe`: chuyển nguyên tử, điều chỉnh một lần |
| TV4 | FK trả → phiếu xuất, lượng trả dương, đối soát duy nhất theo phiếu | `trg_BienDongTonKho_DungChieu` | `vw_BienDongTonKhoChiTiet` | `fn_GiaTriTonKho` | `IX_PHIEU_TRA_HANG_PX` cho cộng dồn trả; `IX_DOI_SOAT_GIA_TRI_THOI_GIAN` cho đối soát | `sp_HoanTatTraHang`: trả tốt/hỏng, kiểm tổng trả, audit cùng transaction |

`IX_LICH_SU_THAO_TAC_THOI_GIAN` và bốn database role thuộc TV4; mọi người vẫn phải thử quyền của luồng mình. Trigger chỉ bảo vệ khi ghi, **không** cộng/trừ tồn lần thứ hai bên cạnh procedure. TV2 giữ contract tồn chung; thay đổi ảnh hưởng TV1/TV3/TV4 phải được họ review. Các view/function là read model, không thay thế transaction chứng từ.

## Bài test và câu hỏi vấn đáp

| TV | Thành công | Lỗi/rollback | Đồng thời/quyền | Câu hỏi bắt buộc |
| --- | --- | --- | --- | --- |
| TV1 | Nhập nhiều lô/vị trí, tồn và sổ tăng đúng | Hai lô vượt lượng hoặc vị trí quá sức chứa, không để lô/tồn dở dang | Hai lần hoàn tất cùng phiếu chỉ một lần thành công | Vì sao FK/CHECK không đủ kiểm tổng phân bổ? Trigger nhiều dòng xử lý thế nào? |
| TV2 | Xuất hai lô FEFO, báo cáo phản ánh commit | Hết hạn/sai FEFO/thiếu tồn, toàn phiếu rollback | Hai phiên xuất cùng tồn không làm âm; role sai bị chặn | Vì sao khóa lúc đọc-kiểm tra-cập nhật? Index FEFO giảm logical reads ra sao? |
| TV3 | Chuyển nguồn/đích, kiểm kê có chênh lệch hợp lệ | Đích đầy hoặc snapshot cũ, nguồn/đích không đổi | Chuyển ngược chiều hoặc xuất/chuyển cạnh tranh | Thứ tự khóa tránh deadlock thế nào? Vì sao kiểm kê cần snapshot? |
| TV4 | Trả tốt/hỏng, đối soát và audit có actor | Trả quá lượng hoặc hoàn tất lặp không tăng tồn | Kế toán chỉ đối soát phiếu đã hoàn tất; role khác bị từ chối | Audit khác sổ biến động thế nào? `GRANT`, `REVOKE`, `DENY` khác nhau ra sao? |

Mỗi người lưu trong issue/PR: **mã `BR-*` → object/contract → lệnh test và kết quả → ảnh/plan nếu là index → giải thích rollback/quyền → câu hỏi tự luyện**. Với phục hồi (WAL, lịch trình khả phục hồi, redo/undo), dùng lỗi transaction của chính luồng để giải thích nguyên lý; không nói đã thử crash recovery nếu chưa có test.

## Phối hợp và nghiệm thu

1. Cả nhóm chốt bảng, reviewer và commit baseline trước khi tách branch. Reviewer vòng đề xuất: TV1 được TV2 review; TV2 được TV3 review; TV3 được TV4 review; TV4 được TV1 review.
2. PR ghi owner, reviewer, acceptance criteria, file/object, mã `BR-*`, ca thành công/thất bại. Sửa API/schema đi kèm contract, migration hoặc `init.sql`, test và tài liệu trong cùng PR.
3. Chạy kiểm tra hẹp khi làm và `pwsh -File scripts/verify.ps1` trước bàn giao. Nếu có SQL Server, chạy thêm `-WithDatabase` và kịch bản concurrency. Ghi đúng lệnh/kết quả.
4. Diễn tập vấn đáp xoay vòng: mỗi người demo luồng mình; người kế tiếp hỏi object SQL; người tiếp nữa hỏi rollback/quyền. Tất cả phải hiểu E2E nhập → tồn → xuất → báo cáo.
5. Phụ lục báo cáo chỉ ghi đóng góp đã có PR/test và reviewer xác nhận. Đối chiếu lại số bảng, object và khả năng UI với code hiện tại vì DOCX nguồn có chỗ mô tả phiên bản cũ.

Nguồn đối chiếu: rubric DBMS330284 trong học liệu nhóm cung cấp; [`BACKLOG.md`](BACKLOG.md), [`../../requirements/BUSINESS_RULES.md`](../../requirements/BUSINESS_RULES.md), [`../../../database/SCHEMA_PLAN.md`](../../../database/SCHEMA_PLAN.md) và object SQL hiện có. Các bài giảng về tạo lập CSDL, T-SQL, procedure, function, trigger, view, index, transaction, điều khiển đồng thời và phục hồi là danh mục ôn tập; yêu cầu cụ thể theo rubric và quyết định hiện hành của nhóm.
