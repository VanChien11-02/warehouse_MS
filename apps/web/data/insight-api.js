export function createInsightApi(client) {
  const paths = { expiry: "/bao-cao/lo-sap-het-han", discrepancies: "/bao-cao/chenh-lech-kiem-ke", audit: "/audit" };
  return {
    query(kind, filters, page = 0) {
      return client.send(`${paths[kind]}?${new URLSearchParams({ ...filters, page, size: 20 })}`);
    },
    async overview(role) {
      const resources = role === "ADMIN"
        ? [["Nhân viên", "nhan-vien", "employees"], ["Tài khoản", "tai-khoan", "accounts"]]
        : role === "NVKHO"
          ? [["Dòng tồn theo lô/vị trí", "ton-kho", "inventory"], ["Phiếu nhập nháp", "phieu-nhap", "inbound"], ["Phiếu xuất nháp", "phieu-xuat", "outbound"]]
          : role === "KETOAN"
            ? [["Dòng tồn theo lô/vị trí", "ton-kho", "inventory"], ["Phiếu nhập", "phieu-nhap", "inbound"], ["Phiếu xuất", "phieu-xuat", "outbound"]]
            : [["Dòng tồn theo lô/vị trí", "ton-kho", "inventory"], ["Phiếu nhập nháp", "phieu-nhap", "inbound"],
              ["Phiếu xuất nháp", "phieu-xuat", "outbound"], ["Phiếu chuyển nháp", "phieu-chuyen", "transfer"],
              ["Phiếu kiểm kê nháp", "phieu-kiem-ke", "count"], ["Phiếu trả hàng nháp", "phieu-tra-hang", "return"]];
      return Promise.all(resources.map(async ([label, path, target]) => {
        try {
          const draftOnly = role !== "KETOAN" && path.startsWith("phieu-");
          const result = await client.send(`/${path}?page=0&size=1${draftOnly ? "&trangThai=NHAP" : ""}`);
          return { label, target, total: result.totalElements };
        } catch (error) {
          if (error.status === 401) throw error;
          return { label, target, error: error.message };
        }
      }));
    }
  };
}
