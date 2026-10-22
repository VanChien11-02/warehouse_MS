export function createDocumentApi(client) {
  function resource(kind) {
    const path = { inbound: "/phieu-nhap", outbound: "/phieu-xuat", transfer: "/phieu-chuyen",
      count: "/phieu-kiem-ke", return: "/phieu-tra-hang" }[kind];
    return {
      list(page = 0, size = 20, filters = {}) {
        const params = new URLSearchParams({ page, size, ...filters });
        return client.send(`${path}?${params}`);
      },
      get(code) {
        return client.send(`${path}/${encodeURIComponent(code)}`);
      },
      create(body) {
        return client.send(path, { method: "POST", body });
      },
      update(code, body) {
        return client.send(`${path}/${encodeURIComponent(code)}`, { method: "PUT", body });
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
    reconciliation: {
      get(kind, code) {
        return client.send(`/doi-soat-gia-tri/${kind}/${encodeURIComponent(code)}`);
      },
      create(kind, code, body) {
        return client.send(`/doi-soat-gia-tri/${kind}/${encodeURIComponent(code)}`, { method: "POST", body });
      }
    },
    inbound: resource("inbound"),
    transfer: resource("transfer"),
    return: resource("return"),
    count: {
      ...resource("count"),
      setActual(code, lot, body) {
        return client.send(`/phieu-kiem-ke/${encodeURIComponent(code)}/chi-tiet/${encodeURIComponent(lot)}`, { method: "PUT", body });
      }
    },
    outbound: {
      ...resource("outbound"),
      suggest(code, product, quantity) {
        const params = new URLSearchParams({ maSanPham: product, soLuong: String(quantity) });
        return client.send(`/phieu-xuat/${encodeURIComponent(code)}/goi-y-fefo?${params}`);
      }
    }
  };
}
