# Bản đồ tài liệu

Tài liệu trong `docs/` là nguồn hiện hành của dự án quản lý kho. Nội dung trong `references/` chỉ dùng tham khảo cách tổ chức và không được tự động xem là yêu cầu nghiệp vụ.

## Kiến trúc và dữ liệu

- [`architecture/database/ERD_VA_NGHIEP_VU.md`](architecture/database/ERD_VA_NGHIEP_VU.md): ERD, quy tắc dữ liệu và danh sách nghiệp vụ.
- [`architecture/database/mermaid-diagram.png`](architecture/database/mermaid-diagram.png): ảnh ERD tham khảo hiện tại.
- [`architecture/adr/0001-repository-layout.md`](architecture/adr/0001-repository-layout.md): quyết định cấu trúc repository.
- [`architecture/adr/0002-technology-stack.md`](architecture/adr/0002-technology-stack.md): quyết định công nghệ frontend/backend/database.

## Quản lý dự án

- [`project/governance/BACKLOG.md`](project/governance/BACKLOG.md): phạm vi, ưu tiên và phụ thuộc.
- [`project/governance/TEAM.md`](project/governance/TEAM.md): phân công hiện tại theo rubric và module.
- [`project/governance/SCRUM.md`](project/governance/SCRUM.md): Ready, Done, nhánh và Pull Request.

GitHub Issues/Project giữ trạng thái làm việc hằng ngày. Backlog Markdown chỉ giữ phạm vi, ưu tiên và quan hệ phụ thuộc để không phải cập nhật trạng thái ở hai nơi.

## Kiểm thử

- [`testing/README.md`](testing/README.md): chiến lược test và bằng chứng cần lưu.

## Tài liệu nguồn

- [`reference/HỆ THỐNG QUẢN LÝ KHO HÀNG.docx.pdf`](reference/HỆ%20THỐNG%20QUẢN%20LÝ%20KHO%20HÀNG.docx.pdf): thiết kế bảng ban đầu.
- [`reference/HuongDan_Project_Rubric_DBMS330284.docx (1).pdf`](reference/HuongDan_Project_Rubric_DBMS330284.docx%20%281%29.pdf): yêu cầu và rubric môn học.

## Khi tài liệu mâu thuẫn

Ưu tiên quyết định mới nhất của nhóm, `AGENTS.md` gần phạm vi sửa, backlog/ADR hiện hành, ERD/contract đã review, code/test đã tích hợp, sau cùng mới đến tài liệu tham khảo.

Không sửa tài liệu nguồn PDF hoặc project tham khảo để làm như thể quyết định cũ chưa từng tồn tại. Ghi quyết định mới bằng ADR/backlog và cập nhật liên kết từ tài liệu hiện hành.
