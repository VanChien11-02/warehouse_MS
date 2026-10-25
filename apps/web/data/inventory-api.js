export function createInventoryApi(client) {
  return {
    list({ page = 0, size = 20, maKho = "", maSanPham = "", maLo = "",
      hanSuDungTruoc = "", chiKhaDung = false } = {}) {
      const params = new URLSearchParams({ page: String(page), size: String(size) });
      if (maKho) params.set("maKho", maKho.trim());
      if (maSanPham) params.set("maSanPham", maSanPham.trim());
      if (maLo) params.set("maLo", maLo.trim());
      if (hanSuDungTruoc) params.set("hanSuDungTruoc", hanSuDungTruoc);
      if (chiKhaDung) params.set("chiKhaDung", "true");
      return client.send(`/ton-kho?${params}`);
    },
    async all(filters = {}) {
      const items = [];
      let page = 0;
      let totalPages = 1;
      do {
        const response = await this.list({ ...filters, page, size: 100 });
        items.push(...(response?.items || []));
        totalPages = response?.totalPages || 0;
        page += 1;
      } while (page < totalPages && page < 20);
      return items;
    }
  };
}
