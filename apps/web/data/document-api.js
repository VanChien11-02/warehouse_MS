export function createDocumentApi(client) {
  function resource(kind) {
    const path = kind === "inbound" ? "/phieu-nhap" : "/phieu-xuat";
    return {
      list(page = 0, size = 20) {
        return client.send(`${path}?page=${page}&size=${size}`);
      },
      get(code) {
        return client.send(`${path}/${encodeURIComponent(code)}`);
      },
      create(body) {
        return client.send(path, { method: "POST", body });
      },
      cancel(code) {
        return client.send(`${path}/${encodeURIComponent(code)}/huy`, { method: "POST" });
      },
      complete(code, body) {
        return client.send(`${path}/${encodeURIComponent(code)}/hoan-tat`, {
          method: "POST", ...(body === undefined ? {} : { body })
        });
      }
    };
  }
  return {
    inbound: resource("inbound"),
    outbound: {
      ...resource("outbound"),
      suggest(code, product, quantity) {
        const params = new URLSearchParams({ maSanPham: product, soLuong: String(quantity) });
        return client.send(`/phieu-xuat/${encodeURIComponent(code)}/goi-y-fefo?${params}`);
      }
    }
  };
}
