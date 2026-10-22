export const roleProfiles = {
  manager: {
    label: "Quản lý kho",
    name: "Nguyễn Trung",
    initials: "NT",
    primaryAction: "Lập phiếu nhập",
    primaryView: "inbound",
    pages: ["dashboard", "products", "categories", "units", "warehouses", "zones", "locations", "inventory", "suppliers", "recipients", "inbound", "outbound", "transfer", "count", "return", "reports"]
  },
  staff: {
    label: "Nhân viên kho",
    name: "Phạm Lan",
    initials: "PL",
    primaryAction: "Lập phiếu xuất",
    primaryView: "outbound",
    pages: ["dashboard", "inventory", "inbound", "outbound"]
  },
  admin: {
    label: "Quản trị viên",
    name: "Trần Minh",
    initials: "TM",
    primaryAction: "Tạo tài khoản",
    primaryView: "accounts",
    pages: ["dashboard", "employees", "accounts", "permissions"]
  }
};

// Pages currently backed by the API. The server remains the authority for every request.
const apiPagesByRole = {
  ADMIN: ["dashboard", "employees", "accounts", "permissions"],
  QLKHO: [...roleProfiles.manager.pages, "expiry", "discrepancies"],
  NVKHO: ["dashboard", "inventory", "inbound", "outbound"],
  KETOAN: ["dashboard", "inventory", "inbound", "outbound", "transfer", "count", "return", "reports", "discrepancies"]
};

export function apiPagesForRole(role) {
  return Object.hasOwn(apiPagesByRole, role) ? apiPagesByRole[role] : [];
}

export function apiLandingPageForRole(role) {
  return apiPagesForRole(role)[0] || "products";
}

export const navDefinition = [
  {
    label: "Tổng quan",
    icon: "grid",
    items: [{ id: "dashboard", label: "Bảng điều khiển", icon: "grid" }]
  },
  {
    label: "Quản lý hàng hóa",
    icon: "box",
    items: [
      { id: "products", label: "Sản phẩm", icon: "box" },
      { id: "categories", label: "Loại sản phẩm", icon: "box" },
      { id: "units", label: "Đơn vị tính", icon: "box" }
    ]
  },
  {
    label: "Quản lý kho bãi",
    icon: "warehouse",
    items: [
      { id: "warehouses", label: "Các kho", icon: "warehouse" },
      { id: "zones", label: "Khu vực kho", icon: "warehouse" },
      { id: "locations", label: "Vị trí trong kho", icon: "warehouse" },
      { id: "inventory", label: "Tồn kho", icon: "chart", badge: "7" }
    ]
  },
  {
    label: "Quản lý đối tác",
    icon: "users",
    items: [
      { id: "suppliers", label: "Nhà cung cấp", icon: "users" },
      { id: "recipients", label: "Đối tác nhận hàng", icon: "users" }
    ]
  },
  {
    label: "Quản lý giao dịch",
    icon: "file",
    items: [
      { id: "inbound", label: "Phiếu nhập kho", icon: "file", badge: "3" },
      { id: "outbound", label: "Phiếu xuất kho", icon: "file", badge: "2" },
      { id: "transfer", label: "Phiếu chuyển kho", icon: "file" },
      { id: "count", label: "Phiếu kiểm kê", icon: "file" },
      { id: "return", label: "Phiếu trả hàng", icon: "file" },
      { id: "reports", label: "Báo cáo tồn kho", icon: "chart" },
      { id: "expiry", label: "Lô sắp hết hạn", icon: "chart" },
      { id: "discrepancies", label: "Chênh lệch kiểm kê", icon: "chart" }
    ]
  },
  {
    label: "Hệ thống",
    icon: "shield",
    items: [
      { id: "employees", label: "Nhân viên", icon: "users" },
      { id: "accounts", label: "Tài khoản đăng nhập", icon: "shield" },
      { id: "permissions", label: "Quyền hạn", icon: "shield" },
      { id: "audit", label: "Nhật ký thao tác", icon: "shield" }
    ]
  }
];

export const pageMeta = {
  dashboard: ["Tổng quan kho", "Theo dõi vận hành trong ngày"],
  products: ["Sản phẩm", "Danh mục hàng hóa và giá mặc định"],
  categories: ["Loại sản phẩm", "Phân nhóm hàng hóa phục vụ tra cứu"],
  units: ["Đơn vị tính", "Chuẩn hóa đơn vị trên chứng từ"],
  warehouses: ["Danh sách kho", "Quản lý các địa điểm lưu trữ"],
  zones: ["Khu vực kho", "Phân chia khu vực theo điều kiện bảo quản"],
  locations: ["Vị trí trong kho", "Theo dõi sức chứa và trạng thái từng vị trí"],
  inventory: ["Tra cứu tồn kho", "Số lượng theo sản phẩm, lô và vị trí"],
  suppliers: ["Nhà cung cấp", "Quản lý nguồn hàng nhập kho"],
  recipients: ["Đối tác nhận hàng", "Quản lý nơi nhận hàng xuất kho"],
  inbound: ["Phiếu nhập kho", "Lập chứng từ tiếp nhận hàng hóa"],
  outbound: ["Phiếu xuất kho", "Lập chứng từ xuất theo nguyên tắc FEFO"],
  transfer: ["Phiếu chuyển kho", "Điều chuyển hàng giữa hai vị trí"],
  count: ["Phiếu kiểm kê", "Đối chiếu số lượng thực tế và hệ thống"],
  return: ["Phiếu trả hàng", "Tiếp nhận và phân loại hàng trả"],
  reports: ["Báo cáo tồn kho", "Tổng hợp nhập — xuất — tồn"],
  employees: ["Nhân viên", "Hồ sơ nhân sự được cấp quyền hệ thống"],
  accounts: ["Tài khoản đăng nhập", "Trạng thái truy cập và vai trò"],
  permissions: ["Quyền hạn", "Ma trận quyền theo vai trò"],
  expiry: ["Lô sắp hết hạn", "Hạn dùng theo lô và vị trí"],
  discrepancies: ["Chênh lệch kiểm kê", "Đối chiếu các phiếu đã hoàn tất"],
  audit: ["Nhật ký thao tác", "Lịch sử giao dịch và quản trị"]
};
