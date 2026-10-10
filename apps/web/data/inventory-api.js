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
    }
  };
}
