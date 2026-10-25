export const masterResources = {
  categories: "loai-san-pham", units: "don-vi-tinh", warehouses: "kho",
  zones: "khu-vuc", locations: "vi-tri", suppliers: "nha-cung-cap",
  recipients: "doi-tac-nhan-hang"
};

export const masterPrefixes = {
  categories: "LSP", units: "DVT", warehouses: "KHO",
  zones: "KV", locations: "VT", suppliers: "NCC",
  recipients: "DT"
};

export function nextCode(prefix, items = [], key = null) {
  const cleanPrefix = String(prefix || "MA").trim().toUpperCase();
  const digits = Math.max(1, 6 - cleanPrefix.length);
  const pattern = new RegExp(`^${cleanPrefix}(\\d+)$`, "i");
  const used = new Set();
  let max = 0;
  for (const item of items || []) {
    const raw = String(key ? item?.[key] ?? "" : Array.isArray(item) ? item[0] ?? "" : item ?? "").trim().toUpperCase();
    if (!raw) continue;
    used.add(raw);
    const match = raw.match(pattern);
    if (match) max = Math.max(max, Number(match[1]));
  }
  let next = max + 1;
  let candidate = `${cleanPrefix}${String(next).padStart(digits, "0")}`;
  while (used.has(candidate)) {
    next += 1;
    candidate = `${cleanPrefix}${String(next).padStart(digits, "0")}`;
  }
  return candidate.slice(0, 6);
}

export function selectOptions(items = [], valueKey, labelFn, selectedValue = "", placeholder = "", esc = (v) => String(v ?? "")) {
  const current = String(selectedValue ?? "").trim();
  const seen = new Set();
  const options = [];
  if (placeholder !== null) {
    options.push(`<option value="">${esc(placeholder)}</option>`);
  }
  for (const item of items || []) {
    const val = String(valueKey ? item?.[valueKey] ?? "" : item ?? "").trim();
    if (!val || seen.has(val)) continue;
    seen.add(val);
    const label = labelFn ? labelFn(item) : val;
    options.push(`<option value="${esc(val)}"${val === current ? " selected" : ""}>${esc(label)}</option>`);
  }
  if (current && !seen.has(current)) {
    options.push(`<option value="${esc(current)}" selected>${esc(current)}</option>`);
  }
  return options.join("");
}

export function createMasterApi(client) {
  return Object.fromEntries(Object.entries(masterResources).map(([key, path]) => {
    const base = `/${path}`;
    const item = (code) => `${base}/${encodeURIComponent(code)}`;
    return [key, {
      list(page = 0, query = "", filters = {}) {
        const params = new URLSearchParams({ page, size: 20, q: query, ...filters });
        return client.send(`${base}?${params}`);
      },
      async all(filters = {}) {
        const items = [];
        let page = 0;
        let totalPages = 1;
        do {
          const params = new URLSearchParams({ page, size: 100, q: "", ...filters });
          const response = await client.send(`${base}?${params}`);
          items.push(...(response?.items || []));
          totalPages = response?.totalPages || 0;
          page += 1;
        } while (page < totalPages && page < 20);
        return items;
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
