import { masterPrefixes, nextCode, selectOptions } from "../data/master-api.js?v=session-shell-4";

const code = (key, label, extra = {}) => ({ key, label, required: true, max: 6, pattern: "[A-Za-z0-9]{1,6}", ...extra });
const name = (key, label, extra = {}) => ({ key, label, required: true, max: 255, ...extra });
const storage = ["Khô", "Mát", "Đông lạnh"];
const contact = [
  { key: "diaChi", label: "Địa chỉ", max: 500 },
  { key: "soDienThoai", label: "Số điện thoại", max: 20, type: "tel" },
  { key: "email", label: "Email", max: 255, type: "email" }
];

export const masterScreens = {
  categories: { title: "Loại sản phẩm", fields: [code("maLoai", "Mã loại"), name("tenLoai", "Tên loại"),
    { key: "yeuCauBaoQuan", label: "Yêu cầu bảo quản", options: storage }, { key: "moTa", label: "Mô tả", max: 1000 }] },
  units: { title: "Đơn vị tính", fields: [code("maDonViTinh", "Mã đơn vị"), name("tenDonViTinh", "Tên đơn vị", { max: 100 })] },
  warehouses: { title: "Các kho", fields: [code("maKho", "Mã kho"), name("tenKho", "Tên kho"), { key: "diaChi", label: "Địa chỉ", max: 255 }] },
  zones: { title: "Khu vực kho", fields: [code("maKhuVuc", "Mã khu vực"), name("tenKhuVuc", "Tên khu vực"),
    code("maKho", "Kho", { immutable: true, ref: "warehouses" }), { key: "loaiKhuVuc", label: "Loại bảo quản", options: storage, required: true, immutable: true }] },
  locations: { title: "Vị trí trong kho", fields: [code("maViTri", "Mã vị trí"), name("tenViTri", "Tên vị trí"),
    code("maKhuVuc", "Khu vực", { ref: "zones" }), { key: "sucChua", label: "Sức chứa", type: "number", min: 0, required: true },
    { key: "loaiViTri", label: "Loại vị trí", options: ["Lưu trữ", "Lấy hàng", "Hư hỏng"], required: true }] },
  suppliers: { title: "Nhà cung cấp", fields: [code("maNhaCungCap", "Mã nhà cung cấp"), name("tenNhaCungCap", "Tên nhà cung cấp"), ...contact], mapping: true },
  recipients: { title: "Đối tác nhận hàng", fields: [code("maDoiTacNhanHang", "Mã đối tác"), name("tenDoiTac", "Tên đối tác"),
    name("loaiDoiTac", "Loại đối tác", { max: 50 }), ...contact], mapping: true }
};

export function createLiveMasters({ masters, products: productApi, getRole, requireLogin, escapeHtml: esc, showToast }) {
  const view = document.createElement("section");
  view.id = "liveMasterView";
  view.className = "view";
  view.hidden = true;
  const dialog = document.createElement("dialog");
  dialog.className = "identity-dialog";
  let mode = "categories", page = 0, generation = 0, editing = null, busy = false;
  const cache = { warehouses: [], zones: [], products: [], current: [] };
  const find = (selector) => view.querySelector(selector);
  const writable = () => ["ADMIN", "QLKHO"].includes(getRole());
  const config = () => masterScreens[mode];
  const message = (text, error = false) => {
    find("[data-message]").textContent = text;
    find("[data-message]").classList.toggle("text-danger", error);
  };

  function refOptions(refType, selected = "") {
    if (refType === "warehouses") {
      return selectOptions(cache.warehouses, "maKho", (w) => `${w.maKho} · ${w.tenKho}`, selected, "Chọn kho", esc);
    }
    if (refType === "zones") {
      return selectOptions(cache.zones, "maKhuVuc", (z) => `${z.maKhuVuc} · ${z.tenKhuVuc}${z.maKho ? ` (${z.maKho})` : ""}`, selected, "Chọn khu vực", esc);
    }
    return "";
  }

  async function refreshRefs() {
    const tasks = [];
    if (["zones", "locations"].includes(mode) && masters.warehouses?.all) {
      tasks.push(masters.warehouses.all().then((items) => { cache.warehouses = items; }).catch(() => {}));
    }
    if (mode === "locations" && masters.zones?.all) {
      tasks.push(masters.zones.all().then((items) => { cache.zones = items; }).catch(() => {}));
    }
    if (config().mapping && productApi?.all) {
      tasks.push(productApi.all().then((items) => { cache.products = items; }).catch(() => {}));
    }
    await Promise.all(tasks);
    const warehouseFilter = view.querySelector('[data-filter="maKho"]');
    if (warehouseFilter) {
      const val = warehouseFilter.value;
      warehouseFilter.innerHTML = selectOptions(cache.warehouses, "maKho", (w) => `${w.maKho} · ${w.tenKho}`, val, "Tất cả kho", esc);
    }
    const zoneFilter = view.querySelector('[data-filter="maKhuVuc"]');
    if (zoneFilter) {
      const val = zoneFilter.value;
      zoneFilter.innerHTML = selectOptions(cache.zones, "maKhuVuc", (z) => `${z.maKhuVuc} · ${z.tenKhuVuc}`, val, "Tất cả khu vực", esc);
    }
  }

  async function load(nextPage = page) {
    const ticket = ++generation;
    page = nextPage;
    find("tbody").replaceChildren();
    find("[data-range]").textContent = "";
    find("[data-prev]").disabled = find("[data-next]").disabled = true;
    message("Đang tải dữ liệu...");
    try {
      const filters = {};
      for (const input of view.querySelectorAll("[data-filter]")) if (input.value.trim()) filters[input.dataset.filter] = input.value.trim();
      const result = await masters[mode].list(page, find("[data-search]").value.trim(), filters);
      if (ticket !== generation) return;
      cache.current = result.items || [];
      if (mode === "warehouses") cache.warehouses = cache.current;
      if (mode === "zones") cache.zones = cache.current;
      const fields = config().fields;
      find("thead").innerHTML = `<tr>${fields.map((f) => `<th>${esc(f.label)}</th>`).join("")}<th>Chi tiết</th></tr>`;
      find("tbody").innerHTML = result.items.map((item) => `<tr>${fields.map((f) => `<td>${esc(item[f.key] ?? "—")}</td>`).join("")}
        <td><button class="row-action" data-open="${esc(item[fields[0].key])}" aria-label="Mở ${esc(item[fields[0].key])}"><svg aria-hidden="true"><use href="#icon-chevron"/></svg></button></td></tr>`).join("");
      find("[data-range]").textContent = `${result.totalElements} bản ghi · trang ${page + 1}/${Math.max(1, result.totalPages)}`;
      find("[data-prev]").disabled = page === 0;
      find("[data-next]").disabled = page + 1 >= result.totalPages;
      message(result.items.length ? "" : "Không có bản ghi phù hợp.");
    } catch (error) { if (ticket === generation) { message(error.message, true); if (error.status === 401) requireLogin(); } }
  }

  async function mappings() {
    const linked = await masters[mode].products(editing);
    dialog.querySelector("[data-mappings]").innerHTML = linked.length ? linked.map((product) => {
      const info = cache.products.find((p) => p.maSanPham === product);
      const label = info ? `${product} · ${info.tenSanPham}` : product;
      return `<li>${esc(label)} <button type="button" class="row-action" data-unlink="${esc(product)}" aria-label="Bỏ liên kết ${esc(product)}"><svg aria-hidden="true"><use href="#icon-trash"/></svg></button></li>`;
    }).join("") : "<li>Chưa liên kết sản phẩm.</li>";
    const productSelect = dialog.querySelector('[data-link-form] [name="product"]');
    if (productSelect) {
      const available = cache.products.filter((p) => !linked.includes(p.maSanPham));
      productSelect.innerHTML = selectOptions(available.length ? available : cache.products, "maSanPham",
        (p) => `${p.maSanPham} · ${p.tenSanPham}`, "", "Chọn sản phẩm", esc);
    }
  }

  async function open(item = null) {
    const codeKey = config().fields[0].key;
    const prefix = masterPrefixes[mode] || "MA";
    editing = item?.[codeKey] || null;
    const initialCode = editing || nextCode(prefix, cache.current, codeKey);
    const canWrite = writable();
    dialog.innerHTML = `<div class="identity-dialog-content"><div class="panel-heading"><h2>${esc(config().title)}</h2>
      <button type="button" class="button button-quiet" data-close aria-label="Đóng">Đóng</button></div>
      <form><div class="form-grid">${config().fields.map((f, i) => `<label class="field"><span>${esc(f.label)}${f.required ? " *" : ""}</span>
        ${f.options ? `<select name="${f.key}">${!f.required ? '<option value="">Không yêu cầu</option>' : ""}${f.options.map((v) => `<option>${esc(v)}</option>`).join("")}</select>`
        : f.ref ? `<select name="${f.key}">${refOptions(f.ref, item?.[f.key] ?? "")}</select>`
        : `<input name="${f.key}" type="${f.type || "text"}" ${f.max ? `maxlength="${f.max}"` : ""} ${f.pattern ? `pattern="${f.pattern}"` : ""} ${f.type === "number" ? `min="${f.min}" step="1"` : ""}>`}
        ${i === 0 ? `<small>${editing ? "Không đổi sau khi tạo" : "Mã tự động tạo"}</small>` : editing && f.immutable ? '<small>Không đổi sau khi tạo</small>' : ""}</label>`).join("")}</div>
      <div class="toolbar-actions"><button class="button button-primary" type="submit" ${canWrite ? "" : "hidden"}>Lưu</button>
      <button class="button button-quiet text-danger" type="button" data-delete ${editing && canWrite ? "" : "hidden"}>Xóa</button></div></form>
      ${editing && config().mapping ? `<section class="mapping-section"><h3>Sản phẩm liên kết</h3><ul data-mappings></ul>
        ${canWrite ? `<form data-link-form><label class="field"><span>Sản phẩm</span><select name="product" required>${selectOptions(cache.products, "maSanPham", (p) => `${p.maSanPham} · ${p.tenSanPham}`, "", "Chọn sản phẩm", esc)}</select></label><button class="button button-secondary" type="submit">Liên kết</button></form>` : ""}</section>` : ""}
      <p data-error role="alert" class="text-danger"></p></div>`;
    config().fields.forEach((f, index) => {
      const input = dialog.querySelector(`[name="${f.key}"]`);
      if (item) input.value = item[f.key] ?? "";
      else if (index === 0) input.value = initialCode;
      else if (f.ref && input.options.length > 1 && !input.value) input.selectedIndex = 1;
      input.required = !!f.required;
      input.disabled = !canWrite || !!editing && (index === 0 || f.immutable);
    });
    dialog.showModal();
    dialog.querySelectorAll("input:not([disabled]), select:not([disabled])")[editing ? 0 : 1]?.focus();
    if (!editing && masters[mode]?.all) {
      masters[mode].all().then((allItems) => {
        const codeInput = dialog.querySelector(`[name="${codeKey}"]`);
        if (codeInput && (!codeInput.value || codeInput.value === initialCode)) {
          codeInput.value = nextCode(prefix, allItems, codeKey);
        }
      }).catch(() => {});
    }
    for (const f of config().fields.filter((field) => field.ref)) {
      if (masters[f.ref]?.all) {
        masters[f.ref].all().then((items) => {
          cache[f.ref] = items;
          const select = dialog.querySelector(`[name="${f.key}"]`);
          if (!select) return;
          const currentVal = select.value || item?.[f.key] || "";
          select.innerHTML = refOptions(f.ref, currentVal);
          if (!editing && !select.value && select.options.length > 1) select.selectedIndex = 1;
        }).catch(() => {});
      }
    }
    if (editing && config().mapping) {
      try {
        if (productApi?.all && !cache.products.length) {
          cache.products = await productApi.all().catch(() => []);
        }
        await mappings();
      } catch (error) { dialog.querySelector("[data-error]").textContent = error.message; }
    }
  }

  async function mutate(action) {
    if (busy || !writable()) return;
    busy = true;
    dialog.querySelector("[data-error]").textContent = "";
    const buttons = [...dialog.querySelectorAll("button")];
    buttons.forEach((b) => { b.disabled = true; });
    try { await action(); } catch (error) {
      dialog.querySelector("[data-error]").textContent = error.message;
      if (error.status === 401) requireLogin();
    } finally { busy = false; buttons.forEach((b) => { b.disabled = false; }); }
  }

  function show(nextMode) {
    if (busy) return;
    generation++;
    if (dialog.open) dialog.close();
    mode = nextMode;
    view.innerHTML = `<div class="section-toolbar"><h2>${esc(config().title)}</h2><button class="button button-primary" data-add ${writable() ? "" : "hidden"}>Thêm mới</button></div>
      <form class="live-filters"><label class="field"><span>Tìm mã hoặc tên</span><input data-search maxlength="100" type="search"></label>
      ${["zones", "locations"].includes(mode) ? `<label class="field"><span>Kho</span><select data-filter="maKho">${selectOptions(cache.warehouses, "maKho", (w) => `${w.maKho} · ${w.tenKho}`, "", "Tất cả kho", esc)}</select></label>` : ""}
      ${mode === "locations" ? `<label class="field"><span>Khu vực</span><select data-filter="maKhuVuc">${selectOptions(cache.zones, "maKhuVuc", (z) => `${z.maKhuVuc} · ${z.tenKhuVuc}`, "", "Tất cả khu vực", esc)}</select></label>` : ""}
      <button class="button button-secondary" type="submit">Tìm kiếm</button></form><p data-message role="status" aria-live="polite"></p>
      <div class="table-wrap"><table><thead></thead><tbody></tbody></table></div><footer class="pagination"><span data-range></span><div>
      <button data-prev aria-label="Trang trước">&lt;</button><button data-next aria-label="Trang sau">&gt;</button></div></footer>`;
    refreshRefs();
    load(0);
  }

  function start() {
    document.querySelector("#mainContent").append(view);
    document.body.append(dialog);
    view.addEventListener("submit", (event) => { event.preventDefault(); if (event.target.reportValidity()) load(0); });
    view.addEventListener("change", (event) => {
      if (event.target.matches("[data-filter]")) {
        if (event.target.dataset.filter === "maKho" && mode === "locations") {
          const selectedWarehouse = event.target.value;
          const zoneFilter = view.querySelector('[data-filter="maKhuVuc"]');
          if (zoneFilter) {
            const zones = selectedWarehouse ? cache.zones.filter((z) => z.maKho === selectedWarehouse) : cache.zones;
            zoneFilter.innerHTML = selectOptions(zones, "maKhuVuc", (z) => `${z.maKhuVuc} · ${z.tenKhuVuc}`, "", "Tất cả khu vực", esc);
          }
        }
        load(0);
      }
    });
    view.addEventListener("click", async (event) => {
      const button = event.target.closest("button");
      if (!button || busy) return;
      if (button.hasAttribute("data-add")) open();
      if (button.hasAttribute("data-prev")) load(page - 1);
      if (button.hasAttribute("data-next")) load(page + 1);
      if (button.dataset.open) {
        const ticket = generation;
        try { const item = await masters[mode].get(button.dataset.open); if (ticket === generation) open(item); }
        catch (error) { message(error.message, true); if (error.status === 401) requireLogin(); }
      }
    });
    dialog.addEventListener("cancel", (event) => { if (busy) event.preventDefault(); });
    dialog.addEventListener("click", (event) => {
      const button = event.target.closest("button");
      if (!button) return;
      if (button.hasAttribute("data-close")) dialog.close();
      if (button.hasAttribute("data-delete") && confirm(`Xóa ${editing}?`)) mutate(async () => {
        await masters[mode].remove(editing); dialog.close(); showToast("Đã xóa bản ghi."); await load(0);
      });
      if (button.dataset.unlink) mutate(async () => { await masters[mode].unlink(editing, button.dataset.unlink); await mappings(); });
    });
    dialog.addEventListener("submit", (event) => {
      event.preventDefault();
      if (!event.target.reportValidity()) return;
      if (event.target.hasAttribute("data-link-form")) {
        mutate(async () => { await masters[mode].link(editing, event.target.elements.product.value.trim()); await mappings(); event.target.reset(); });
        return;
      }
      const body = {};
      config().fields.forEach((f) => {
        const input = dialog.querySelector(`[name="${f.key}"]`);
        if (!input.disabled) body[f.key] = f.type === "number" ? Number(input.value) : input.value.trim() || null;
      });
      mutate(async () => {
        if (editing) await masters[mode].update(editing, body); else await masters[mode].create(body);
        dialog.close(); showToast("Đã lưu bản ghi."); await load(0);
      });
    });
  }
  function clear() { generation++; if (dialog.open) dialog.close(); view.replaceChildren(); }
  return { start, show, clear, viewId: view.id };
}
