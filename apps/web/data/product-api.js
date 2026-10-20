export function createProductApi(client) {
  async function all(path) {
    const items = [];
    let page = 0;
    let totalPages;
    do {
      const response = await client.send(`${path}?page=${page}&size=100`);
      items.push(...response.items);
      totalPages = response.totalPages;
      page += 1;
    } while (page < totalPages);
    return items;
  }

  return {
    list(page, size, query = "") {
      const params = new URLSearchParams({ page: String(page), size: String(size), q: query });
      return client.send(`/san-pham?${params}`);
    },
    get(code) {
      return client.send(`/san-pham/${encodeURIComponent(code)}`);
    },
    create(product) {
      return client.send("/san-pham", { method: "POST", body: product });
    },
    update(code, product) {
      return client.send(`/san-pham/${encodeURIComponent(code)}`, {
        method: "PUT", body: product
      });
    },
    remove(code) {
      return client.send(`/san-pham/${encodeURIComponent(code)}`, { method: "DELETE" });
    },
    async references() {
      const [categories, units] = await Promise.all([
        all("/loai-san-pham"),
        all("/don-vi-tinh")
      ]);
      return { categories, units };
    }
  };
}
