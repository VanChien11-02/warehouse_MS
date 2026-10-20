export function createReportApi(client) {
  return {
    movements({ from, to, page = 0, size = 20, warehouse = "", product = "" }) {
      const params = new URLSearchParams({
        tuNgay: from,
        denNgay: to,
        page: String(page),
        size: String(size)
      });
      if (warehouse) params.set("maKho", warehouse.trim());
      if (product) params.set("maSanPham", product.trim());
      return client.send(`/bao-cao/nhap-xuat?${params}`);
    }
  };
}
