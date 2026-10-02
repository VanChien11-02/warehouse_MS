HỆ THỐNG QUẢN LÝ KHO HÀNG 

**1. Xác định nghiệp vụ** 

   - Quản lý sản phẩm 

   - Quản lý nhà cung cấp 

   - Quản lý kho 

   - Quản lý vị trí 

   - Nhập kho 

   - Xuất kho 

   - Quản lý tồn kho 

   - Quản lý nhân viên 

   - Quản lý tài khoản 

   - Báo cáo thống kê 

   - Quản lý đối tác nhận hàng 

   - Quản lý lịch sử thao tác 

# **2. Xác định Actor, use case** 

Quản trị viên (Quản lý tài khoản, Quản lý nhân viên, Phân quyền) 

Quản lý kho (Quản lý sản phẩm, Quản lý nhà cung cấp, Quản lý đối tác nhận hàng, Lập phiếu nhập, Lập phiếu xuất, Xem báo cáo tồn kho, phân loại sản phẩm) 

Nhân viên kho (Nhập kho, Xuất kho, Tra cứu tồn kho) 

Đơn vị nhận hàng � Phiếu xuất � Chi tiết phiếu xuất � Sản phẩm 

|STT|<br>Bảng|Mục đích|
|---|---|---|
|1|<sup>`LoaiSanPham`</sup>|Nhóm/phân loạisảnphẩm|
|2|<sup>`SanPham`</sup>|Thông tinsảnphẩm|
|3|<sup>`DonViTinh`</sup>|Đơn vị tính của sản phẩm|
|4|<sup>`NhaCungCap`</sup>|Nhà cung cấp|
|5|<sup>`NhaCungCap_SanPham`</sup>|Quan hệ cung cấp sản phẩm|
|6|<sup>`DoiTacNhanHang`</sup>|Đối tác nhận hàngxuất kho|
|7|<sup>`DoiTacNhanHang_SanPham`</sup>|Quan hệnhận sảnphẩm|
|8|<sup>`NhanVien`</sup>|Nhân viên|
|9|<sup>`TaiKhoan`</sup>|Tài khoản đăngnhập|
|10|<sup>`Role`</sup>|Quyền hạn|
|11|<sup>`Kho`</sup>|Các kho|
|12|<sup>`ViTriKho`</sup>|Vịtrí trongkho|
|13|<sup>`KhuVuc`</sup>|Khu vực kho|
|14|<sup>`TonKho`</sup>|Số lượng hàng hóa tồn trong<br>kho|
|15|<sup>`PhieuNhap`</sup>|Phiếu nhậpkho|



|STT|<br>Bảng|Mục đích<br>|
|---|---|---|
|16|<sup>`ChiTietPhieuNhap`</sup>|Các sảnphẩm trong phiếu nhập|
|17|<sup>`PhieuXuat`</sup>|Phiếu xuất kho|
|18|<sup>`ChiTietPhieuXuat`</sup>|Các sảnphẩm trong phiếu xuất|
|19|<sup>`LoHang`</sup>|Lô hàngnhậpxuất|
|20|<sup>`PhieuKiemKe`</sup>|Phiếu kiểm kê hànghóa|
|21|<sup>`ChiTietKiemKe`</sup>|Kiểm kê lô hàng|
|22|<sup>`PhieuTraHang`</sup>|Phiếu trả hàng|
|23|<sup>`ChiTietPhieuTraHang`</sup>|Hoàn trả lô hàng|



# **3. Mô tả bảng** 

|SanPham||||
|---|---|---|---|
|MaSP|Mã sản phẩm|Char(6)|Primary key, not null|
|TenSP|Tên sản phẩm|Nvarchar(255)|Not null|
|MaLoai|Mã loại sản phẩm|Char(6)|Foreign key, not null|
|MaDVT|Mã đơn vị tính|Char(6)|Foreign key, not null|
|GiaNhap|Giá nhập hàng|Decimal(12, 2)|Check>=0, not null|
|GiaBan|Giá xuất hàng|Decimal(12, 2)|Check>=0, not null|



|NhaCungCap||||
|---|---|---|---|
|MaNCC|Mã nhà cung cấp<br>|Char(6)|Primary key, not null|
|TenNCC|Tên nhà cung cấp|Nvarchar(255)|Notnull|
|DiaChi|Địa chỉ nhà cung<br>cấp<br>|Nvarchar(255)||
|SDT|Số điện thoại nhà<br>cung cấp<br>|Varchar(20)||
|Email|Email nhà cung cấp|Varchar(100)||



|NhaCungCap|_SanPham|||
|---|---|---|---|
|MaNCC|Mã nhà cung cấp|Char(6)|PK = {MaNCC, MaSP}|
|MaSP|Mã sản phẩm|Char(6)|FK1 = MaNCC<br>FK2=MaSP|



|DoiTacNhanHang||||
|---|---|---|---|
|MaDTNH|Mã đối tác nhận<br>hàng|Char(6)|Primary key, not null|



|TenDoiTac|Tên đối tác nhận<br>hàng<br>|Nvarchar(255)|Not null|
|---|---|---|---|
|LoaiDoiTac|Loại dối tác|Nvarchar(100)||
|DiaChi|Địa chỉđốitác|Nvarchar(255)||
|SDT|Số điện thoại|Varchar(20)||
|Email|Email bên đối tác|Nvarchar(100)||
|DoiTacNhanHang||||
|<br>MaDTNH|Mã đối tác nhận<br>hàng|Char(6)|PK = {MaDTNH,<br>MaSP}|
|MaSP|Mã sản phẩm|Char(6)|FK1 = MaNCC<br>FK2=MaSP|
|NhanVien||||
|MaNV|Mã nhân viên|Char(6)|Primary key, not null|
|TenNV|Tên nhân viên|Nvarchar(255)|Not null|
|SDT|Số điện thoại|Varchar(20)||
|GioiTinh|Giới tính|Nvarchar(10)||
|NgaySinh|Ngày sinh|Date||
|DiaChi|Địa chỉ|Nvarchar(255)||
|Luong|lương|Decimal(12, 2)|Check>=0, not null|
|NVL|Ngày vào làm|Date|Default getdate()|



|PhieuNhap||||
|---|---|---|---|
|MaPN|Mã phiếu nhập|Char(6)|Primary key, not null|
|NgayNhap|Ngày nhập<br>|date||
|MaNCC|Mã nhà cung cấp|Char(6)|Foreign key, not null|
|MaNV|Mã nhân viên|Char(6)|Foreign key, not null|



|ChiTietPhieuNhap||||
|---|---|---|---|
|MaPN|Mã phiếu nhập|Char(6)|PK = {MaPN, MaSP}|
|MaSP|Mã sản phẩm<br>|Char(6)|FK1 = MaPN<br>FK2=MaSP|
|SoLuong|Số lượng hàng nhập<br>kho|int|Not null|
|DonGiaNhap|Đơn giá nhập hàng|Decimal(12, 2)|Check>=0, not null|



|TrangThai|Trạng thái hàng hóa|Nvarchar(50)|Check in (N‘Chờ nhập’,<br>N‘Đã nhập’, N‘Đã hủy’)|
|---|---|---|---|



|PhieuXuat||||
|---|---|---|---|
|MaPX|Mã phiếuxuất<br>|Char(6)|Primarykey,notnull|
|NgayXuat|Ngày xuất<br>|date||
|MaDTNH|Mã đối tác nhận<br>hàng|Char(6)|Foreign key, not null|
|MaNV|Mã nhân viên|Char(6)|Foreign key, not null|



|TaiKhoan||||
|---|---|---|---|
|MaTK|Mã tài khoản|Char(6)|Primary key, not null|
|MaNV|Mãnhânviên|Char(6)|Foreign key,notnull|
|TenTK|Tên tài khoản<br>|Nvarchar(255)|Not null, unique|
|MatKhau|Mật khẩu|Varchar(100)|Not null|
|MaRole|Mã role|Char(6)|Foreign key, not null|



|Role||||
|---|---|---|---|
|MaRole|Mã role|Char(6)|Primary key, not null|
|TenRole|Quyền hạn tài<br>khoản|<br>Nvarchar(100)|<br>Check in(N‘Admin’,<br>N‘Quản lý kho’, N‘Nhân<br>viên kho’, N’Kế toán’)|
|MoTa|Mô tả tài khoản|Text||



|DonViTinh||||
|---|---|---|---|
|MaDVT|Mã đơn vị tính|Char(6)|Primary key, not null|
|TenDVT|Tên đơn vị tính|Nvarchar(100)|Not null|



|Kho||||
|---|---|---|---|
|MaKho|Mã kho|Char(6)|Primary key, not null|
|TenKho|Tên kho|Nvarchar(255)|Not null, unique|
|DiaChi|Địa chỉ kho|Nvarchar(255)||



|LoaiSanPham||||
|---|---|---|---|
|MaLoai|Mã loại sản phẩm|Char(6)|Primary key, not null|
|TenLoai|Tên loại sản phẩm|Nvarchar(255)|Not null|
|MoTa|Mô tả loại sản phẩm|Text||
|YeuCauBaoQuan|Điều kiện bảo quản<br>yêu cầu|Nvarchar(20)|Check in (N'Khô', N'Mát',<br>N'Đông lạnh')|



|KhuVuc||||
|---|---|---|---|
|MaKhuVuc|Mã khu vực|Char(6)|Primary key, not null|
|MaKho|Mã kho|Char(6)|Foreign key, not null|
|TenKhuVuc|Tên khu vực|Nvarchar(255)|Not null|
|LoaiKhuVuc|Loại khu vực|Nvarchar(20)|Check in (N'Khô', N'Mát',<br>N'Đông lạnh'), not null|



|ViTriKho||||
|---|---|---|---|
|MaViTri|Mã vị trí kho|Char(6)|Primary key, not null|
|MaKhuVuc|Mã khu vực|Char(6)|Foreign key, not null|
|TenViTri|Vị trí kho|Nvarchar(255)|Not null|
|SucChua|Sức chứa của vị trí|Int|Check >= 0|



|LoaiViTri|Loại vị trí|Nvarchar(20)|Check in (N'Lưu trữ',<br>|
|---|---|---|---|
||||N'Lấy hàng', N'Hư hỏng'),<br>not null|



|LoHang||||
|---|---|---|---|
|MaLo|Mã lô hàng|Char(6)|Primary key, not null|
|MaPN|Mã phiếu nhập|Char(6)|Foreign key (cùng MaSP)<br>→ ChiTietPhieuNhap, not<br>null|
|MaSP|Mã sản phẩm|Char(6)|Foreign key (cùng MaPN)<br>→ ChiTietPhieuNhap, not<br>null|
|NgaySanXuat|Ngày sản xuất|Date||
|HanSuDung|Hạn sử dụng|Date|Not null|
|SoLuongNhap|Số lượng nhập ban<br>đầu của lô|Int|Check >= 0, not null|



|TonKho||||
|---|---|---|---|
|MaViTri|Mã vị trí kho|Char(6)|PK = {MaViTri, MaLo},<br>Foreign key|
|MaLo|Mã lô hàng|Char(6)|PK = {MaViTri, MaLo},<br>Foreign key|
|SoLuongTon|Số lượng còn lại của lô,<br>tại vị trí này|<br>Int|Check >= 0, not null|



|ChiTietPhieuXuat||||
|---|---|---|---|
|MaPX|Mã phiếu xuất|Char(6)|PK = {MaPX, MaLo},<br>Foreign key|



|MaLo|Mã lô hàng xuất|Char(6)|PK = {MaPX, MaLo},<br>Foreign key|
|---|---|---|---|
|SoLuong|Số lượng hàng xuất kho|Int|Not null|
|DonGiaXuat|Đơn giá xuất hàng|Decimal(12,2)|Check >= 0, not null|
|TrangThai|Trạng thái hàng hóa|Nvarchar(50)|Check in (N'Chờ xuất',<br>N'Đã xuất', N'Đã hủy')|



|PhieuChuyenKho<br>MaPCK|Mã phiếu chuyển kho|Char(6)|Primary key, not null|
|---|---|---|---|
|NgayChuyen|Ngày chuyển|Date|Not null|
|MaNV|Mã nhân viên thực hiện|Char(6)|Foreign key, not null|



|ChiTietPhieuChuy|enKho|||
|---|---|---|---|
|MaPCK|Mã phiếu chuyển kho|Char(6)|PK = {MaPCK, MaLo}<br>FK1 = MaPCK|
|MaLo|Mã lô hàng được<br>chuyển|Char(6)|<br>FK2 = MaLo|
|MaViTriNguon|Vị trí nguồn|Char(6)|Foreign key, not null|
|MaViTriDich|Vị trí đích|Char(6)|Foreign key, not null|
|SoLuong|Số lượng chuyển|Int|Check > 0, not null|



|PhieuKiemKe||||
|---|---|---|---|
|MaPKK|Mã phiếu kiểm kê|Char(6)|Primary key, not null|
|NgayKiemKe|Ngày kiểm kê|Date|Not null|



|MaNV<br>MaViTri|Mã nhân viên kiểm kê<br>Vị trí được kiểm kê|Char(6)<br>Char(6)|Foreign key, not null<br>Foreign key, not null|
|---|---|---|---|



|ChiTietKiemKe||||
|---|---|---|---|
|MaPKK|Mã phiếu kiểm kê|Char(6)|PK = {MaPKK, MaLo},<br>Foreign key|
|MaLo|Mã lô hàng|Char(6)|PK = {MaPKK, MaLo},<br>Foreign key|
|SoLuongHeThong|Số lượng hệ thống ghi<br>nhận|Int|Check >= 0, not null|
|SoLuongThucTe|Số lượng đếm thực tế|Int|Check >= 0, not null|



|PhieuTraHang||||
|---|---|---|---|
|MaPTH|Mã phiếu trả hàng|Char(6)|Primary key, not null|
|NgayTra|Ngày trả|Date|Not null|
|MaDTNH|Mã đối tác trả hàng|Char(6)|Foreign key, not null|
|MaNV|Mã nhân viên tiếp nhận|Char(6)|Foreign key, not null|



|ChiTietPhieuTr|aHang|||
|---|---|---|---|
|MaPTH|Mã phiếu trả hàng|Char(6)|PK = {MaPTH, MaLo},<br>Foreign key|
|MaLo|Mã lô hàng trả|Char(6)|PK = {MaPTH, MaLo},<br>Foreign key|
|SoLuong|Số lượng trả|Int|Check > 0, not null|
|TinhTrang|Tình trạng hàng trả|Nvarchar(20)|Check in (N'Tốt', N'Hư<br>hỏng'), not null|



