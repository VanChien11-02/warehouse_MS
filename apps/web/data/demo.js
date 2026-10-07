export const listConfigs = {
  products: {
    title: "Danh sách sản phẩm",
    description: "Tra cứu và quản lý danh mục hàng hóa.",
    addLabel: "Thêm sản phẩm",
    columns: ["Mã sản phẩm", "Tên sản phẩm", "Loại", "Đơn vị", "Giá bán", "Trạng thái"],
    rows: [
      ["SP0001", "Sữa tươi tiệt trùng", "Thực phẩm lạnh", "Thùng", "325.000 ₫", "Đang hoạt động"],
      ["SP0002", "Nước ép cam 1L", "Đồ uống", "Thùng", "365.000 ₫", "Đang hoạt động"],
      ["SP0003", "Bánh quy bơ", "Bánh kẹo", "Hộp", "56.000 ₫", "Đang hoạt động"],
      ["SP0004", "Cà phê rang xay", "Đồ uống", "Gói", "99.000 ₫", "Đang hoạt động"],
      ["SP0005", "Dầu ăn hướng dương", "Thực phẩm", "Chai", "72.000 ₫", "Đang hoạt động"],
      ["SP0006", "Mì Ý số 5", "Thực phẩm", "Gói", "39.000 ₫", "Chờ xử lý"],
      ["SP0007", "Nước khoáng 500ml", "Đồ uống", "Thùng", "118.000 ₫", "Đang hoạt động"],
      ["SP0008", "Khăn giấy hộp", "Gia dụng", "Hộp", "31.000 ₫", "Đang hoạt động"],
      ["SP0009", "Bột giặt 3kg", "Gia dụng", "Túi", "168.000 ₫", "Đang hoạt động"],
      ["SP0010", "Sữa chua uống", "Thực phẩm lạnh", "Thùng", "286.000 ₫", "Ngừng hoạt động"],
      ["SP0011", "Nước tương đậm đặc", "Gia vị", "Chai", "42.000 ₫", "Đang hoạt động"]
    ]
  },
  categories: {
    title: "Loại sản phẩm",
    description: "Phân nhóm sản phẩm theo tính chất và điều kiện bảo quản.",
    addLabel: "Thêm loại",
    columns: ["Mã loại", "Tên loại", "Số sản phẩm", "Điều kiện bảo quản", "Cập nhật", "Trạng thái"],
    rows: [
      ["LSP001", "Thực phẩm lạnh", "28", "2–8°C", "28/09/2026", "Đang hoạt động"],
      ["LSP002", "Đồ uống", "34", "Nhiệt độ thường", "21/09/2026", "Đang hoạt động"],
      ["LSP003", "Bánh kẹo", "18", "Khô ráo", "18/09/2026", "Đang hoạt động"],
      ["LSP004", "Gia dụng", "25", "Nhiệt độ thường", "12/09/2026", "Đang hoạt động"],
      ["LSP005", "Gia vị", "23", "Khô ráo", "05/09/2026", "Đang hoạt động"]
    ]
  },
  units: {
    title: "Đơn vị tính",
    description: "Danh mục đơn vị sử dụng trên sản phẩm và chứng từ.",
    addLabel: "Thêm đơn vị",
    columns: ["Mã đơn vị", "Tên đơn vị", "Ký hiệu", "Số sản phẩm", "Cập nhật", "Trạng thái"],
    rows: [
      ["DVT01", "Thùng", "thùng", "42", "28/09/2026", "Đang hoạt động"],
      ["DVT02", "Hộp", "hộp", "21", "27/09/2026", "Đang hoạt động"],
      ["DVT03", "Chai", "chai", "24", "26/09/2026", "Đang hoạt động"],
      ["DVT04", "Gói", "gói", "31", "20/09/2026", "Đang hoạt động"],
      ["DVT05", "Kilôgam", "kg", "10", "18/09/2026", "Đang hoạt động"]
    ]
  },
  warehouses: {
    title: "Danh sách kho",
    description: "Quản lý kho và mức sử dụng sức chứa.",
    addLabel: "Thêm kho",
    columns: ["Mã kho", "Tên kho", "Địa chỉ", "Khu vực", "Sử dụng", "Trạng thái"],
    rows: [
      ["K01", "Kho trung tâm", "Thủ Đức, TP.HCM", "8 khu", "82%", "Đang hoạt động"],
      ["K02", "Kho lạnh", "Thủ Đức, TP.HCM", "3 khu", "68%", "Đang hoạt động"],
      ["K03", "Kho hàng trả", "Dĩ An, Bình Dương", "2 khu", "31%", "Đang hoạt động"],
      ["K04", "Kho miền Tây", "Cái Răng, Cần Thơ", "5 khu", "—", "Chờ xử lý"]
    ]
  },
  zones: {
    title: "Khu vực kho",
    description: "Bố trí khu vực theo loại hàng và điều kiện bảo quản.",
    addLabel: "Thêm khu vực",
    columns: ["Mã khu vực", "Tên khu vực", "Thuộc kho", "Loại bảo quản", "Vị trí", "Trạng thái"],
    rows: [
      ["KV-A", "Khu A · Hàng nhanh", "K01", "Nhiệt độ thường", "24", "Đang hoạt động"],
      ["KV-B", "Khu B · Hàng khô", "K01", "Khô ráo", "32", "Đang hoạt động"],
      ["KV-C", "Khu C · Dự phòng", "K01", "Nhiệt độ thường", "16", "Đang hoạt động"],
      ["KV-L1", "Lạnh 1 · Sữa", "K02", "2–8°C", "18", "Đang hoạt động"],
      ["KV-QA", "Khu cách ly", "K03", "Riêng biệt", "14", "Đang hoạt động"]
    ]
  },
  locations: {
    title: "Vị trí trong kho",
    description: "Theo dõi sức chứa và tình trạng từng ô kệ.",
    addLabel: "Thêm vị trí",
    columns: ["Mã vị trí", "Khu vực", "Loại kệ", "Đang chứa", "Sức chứa", "Trạng thái"],
    rows: [
      ["A-01-03", "KV-A", "Kệ pallet", "480", "600", "Đang hoạt động"],
      ["A-02-01", "KV-A", "Kệ pallet", "510", "600", "Đang hoạt động"],
      ["B-04-02", "KV-B", "Kệ tầng", "276", "300", "Chờ xử lý"],
      ["B-06-04", "KV-B", "Kệ tầng", "132", "300", "Đang hoạt động"],
      ["L1-02-01", "KV-L1", "Kệ lạnh", "188", "240", "Đang hoạt động"],
      ["QA-01-01", "KV-QA", "Ô cách ly", "26", "100", "Đang hoạt động"]
    ]
  },
  suppliers: {
    title: "Nhà cung cấp",
    description: "Quản lý thông tin nguồn hàng nhập kho.",
    addLabel: "Thêm nhà cung cấp",
    columns: ["Mã NCC", "Tên nhà cung cấp", "Liên hệ", "Khu vực", "Công nợ", "Trạng thái"],
    rows: [
      ["NCC001", "Vinamilk miền Nam", "028 5415 5555", "TP.HCM", "0 ₫", "Đang hoạt động"],
      ["NCC002", "Thực phẩm Á Châu", "028 3728 1919", "Bình Dương", "82.500.000 ₫", "Đang hoạt động"],
      ["NCC003", "Nông sản Đà Lạt", "0263 3822 188", "Lâm Đồng", "24.200.000 ₫", "Đang hoạt động"],
      ["NCC004", "Gia dụng Minh Khang", "028 6258 2204", "TP.HCM", "0 ₫", "Chờ xử lý"]
    ]
  },
  recipients: {
    title: "Đối tác nhận hàng",
    description: "Quản lý khách hàng và điểm nhận hàng xuất kho.",
    addLabel: "Thêm đối tác",
    columns: ["Mã đối tác", "Tên đối tác", "Liên hệ", "Khu vực", "Phiếu gần nhất", "Trạng thái"],
    rows: [
      ["DT001", "Siêu thị An Phú", "0903 118 229", "TP.HCM", "PX-260928", "Đang hoạt động"],
      ["DT002", "Cửa hàng Minh Long", "0908 621 442", "Bình Dương", "PX-260922", "Đang hoạt động"],
      ["DT003", "Đại lý Thành Công", "0917 803 114", "Đồng Nai", "PX-260921", "Đang hoạt động"],
      ["DT004", "Chuỗi Xanh Market", "0932 014 441", "Long An", "—", "Chờ xử lý"]
    ]
  },
  employees: {
    title: "Danh sách nhân viên",
    description: "Hồ sơ nhân sự có liên quan đến vận hành hệ thống.",
    addLabel: "Thêm nhân viên",
    columns: ["Mã NV", "Họ tên", "Bộ phận", "Số điện thoại", "Ca làm việc", "Trạng thái"],
    rows: [
      ["NV001", "Trần Minh", "Quản trị hệ thống", "0901 112 233", "Hành chính", "Đang hoạt động"],
      ["NV012", "Nguyễn Trung", "Quản lý kho", "0908 245 511", "Ca sáng", "Đang hoạt động"],
      ["NV018", "Phạm Lan", "Nhân viên kho", "0935 502 186", "Ca sáng", "Đang hoạt động"],
      ["NV021", "Lê Duy", "Nhân viên kho", "0912 848 920", "Ca chiều", "Đang hoạt động"],
      ["NV024", "Võ Thảo", "Nhân viên kho", "0906 441 370", "Ca chiều", "Chờ xử lý"]
    ]
  },
  accounts: {
    title: "Tài khoản đăng nhập",
    description: "Quản lý trạng thái truy cập và vai trò; mật khẩu không hiển thị.",
    addLabel: "Tạo tài khoản",
    columns: ["Tên đăng nhập", "Nhân viên", "Vai trò", "Đăng nhập cuối", "Xác thực", "Trạng thái"],
    rows: [
      ["admin.minh", "NV001 · Trần Minh", "Quản trị viên", "02/10/2026 08:02", "Mật khẩu", "Đang hoạt động"],
      ["qlkho.trung", "NV012 · Nguyễn Trung", "Quản lý kho", "02/10/2026 07:21", "Mật khẩu", "Đang hoạt động"],
      ["nvkho.lan", "NV018 · Phạm Lan", "Nhân viên kho", "02/10/2026 06:58", "Mật khẩu", "Đang hoạt động"],
      ["nvkho.duy", "NV021 · Lê Duy", "Nhân viên kho", "01/10/2026 13:02", "Mật khẩu", "Đang hoạt động"],
      ["nvkho.thao", "NV024 · Võ Thảo", "Nhân viên kho", "Chưa đăng nhập", "Chưa kích hoạt", "Chờ xử lý"]
    ]
  },
  permissions: {
    title: "Quyền hạn hệ thống",
    description: "Ma trận hiển thị phục vụ thiết kế; backend vẫn là nguồn sự thật phân quyền.",
    addLabel: "Thêm vai trò",
    columns: ["Vai trò", "Phạm vi", "Xem", "Tạo", "Hoàn tất", "Trạng thái"],
    rows: [
      ["Quản trị viên", "Nhân viên, tài khoản, quyền", "Có", "Có", "—", "Đang hoạt động"],
      ["Quản lý kho", "Danh mục, kho, đối tác, chứng từ, báo cáo", "Có", "Có", "Có", "Đang hoạt động"],
      ["Nhân viên kho", "Nhập, xuất, tra cứu tồn", "Có", "Có", "Theo phân công", "Đang hoạt động"],
      ["Kế toán", "Phạm vi chưa chốt trong UI", "Chờ chốt", "Chờ chốt", "Chờ chốt", "Chờ xử lý"]
    ]
  }
};

export const inventoryRows = [
  ["SP0001 · Sữa tươi tiệt trùng", "LO240108", "A-01-03", "14/10/2026", 48, 12, 36, "Sắp hết hạn"],
  ["SP0003 · Bánh quy bơ", "LO240112", "B-04-02", "20/10/2026", 72, 8, 64, "Sắp hết hạn"],
  ["SP0002 · Nước ép cam 1L", "LO240119", "A-02-01", "27/10/2026", 135, 20, 115, "Sắp hết hạn"],
  ["SP0004 · Cà phê rang xay", "LO240126", "B-06-04", "20/12/2026", 120, 0, 120, "Khả dụng"],
  ["SP0007 · Nước khoáng 500ml", "LO240131", "A-03-02", "18/04/2027", 420, 120, 300, "Khả dụng"],
  ["SP0008 · Khăn giấy hộp", "LO240204", "B-01-01", "—", 260, 0, 260, "Khả dụng"],
  ["SP0009 · Bột giặt 3kg", "LO240218", "B-02-03", "—", 18, 4, 14, "Dưới định mức"]
];

export const countRows = [
  ["SP0001 · Sữa tươi", "LO240108", "A-01-03", 48, 47],
  ["SP0002 · Nước ép cam", "LO240119", "A-02-01", 135, 138],
  ["SP0003 · Bánh quy bơ", "LO240112", "B-04-02", 72, 70],
  ["SP0004 · Cà phê rang xay", "LO240126", "B-06-04", 120, 120],
  ["SP0007 · Nước khoáng", "LO240131", "A-03-02", 420, 418],
  ["SP0008 · Khăn giấy hộp", "LO240204", "B-01-01", 260, 260]
];

export const reportData = [
  ["SP0001", "Sữa tươi tiệt trùng", 82, 120, 154, 48, "Thùng"],
  ["SP0002", "Nước ép cam 1L", 110, 180, 155, 135, "Thùng"],
  ["SP0003", "Bánh quy bơ", 96, 80, 104, 72, "Hộp"],
  ["SP0004", "Cà phê rang xay", 118, 60, 58, 120, "Gói"],
  ["SP0007", "Nước khoáng 500ml", 360, 240, 180, 420, "Thùng"]
];

export const documentProducts = [
  ["SP0001", "Sữa tươi tiệt trùng", 285000],
  ["SP0002", "Nước ép cam 1L", 310000],
  ["SP0003", "Bánh quy bơ", 42000],
  ["SP0004", "Cà phê rang xay", 78000],
  ["SP0007", "Nước khoáng 500ml", 94000]
];
