export const masterResources = {
  categories: "loai-san-pham", units: "don-vi-tinh", warehouses: "kho",
  zones: "khu-vuc", locations: "vi-tri", suppliers: "nha-cung-cap",
  recipients: "doi-tac-nhan-hang"
};

export function createMasterApi(client) {
  return Object.fromEntries(Object.entries(masterResources).map(([key, path]) => {
    const base = `/${path}`;
    const item = (code) => `${base}/${encodeURIComponent(code)}`;
    return [key, {
      list(page = 0, query = "", filters = {}) {
        const params = new URLSearchParams({ page, size: 20, q: query, ...filters });
        return client.send(`${base}?${params}`);
      },
      get: (code) => client.send(item(code)),
      create: (body) => client.send(base, { method: "POST", body }),
      update: (code, body) => client.send(item(code), { method: "PUT", body }),
      remove: (code) => client.send(item(code), { method: "DELETE" }),
      products: (code) => client.send(`${item(code)}/san-pham`),
      link: (code, product) => client.send(`${item(code)}/san-pham/${encodeURIComponent(product)}`, { method: "POST" }),
      unlink: (code, product) => client.send(`${item(code)}/san-pham/${encodeURIComponent(product)}`, { method: "DELETE" })
    }];
  }));
}
