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
    code("maKho", "Mã kho", { immutable: true }), { key: "loaiKhuVuc", label: "Loại bảo quản", options: storage, required: true, immutable: true }] },
  locations: { title: "Vị trí trong kho", fields: [code("maViTri", "Mã vị trí"), name("tenViTri", "Tên vị trí"),
    code("maKhuVuc", "Mã khu vực"), { key: "sucChua", label: "Sức chứa", type: "number", min: 0, required: true },
    { key: "loaiViTri", label: "Loại vị trí", options: ["Lưu trữ", "Lấy hàng", "Hư hỏng"], required: true }] },
  suppliers: { title: "Nhà cung cấp", fields: [code("maNhaCungCap", "Mã nhà cung cấp"), name("tenNhaCungCap", "Tên nhà cung cấp"), ...contact], mapping: true },
  recipients: { title: "Đối tác nhận hàng", fields: [code("maDoiTacNhanHang", "Mã đối tác"), name("tenDoiTac", "Tên đối tác"),
    name("loaiDoiTac", "Loại đối tác", { max: 50 }), ...contact], mapping: true }
};

export function createLiveMasters({ masters, getRole, requireLogin, escapeHtml: esc, showToast }) {
  const view = document.createElement("section");
  view.id = "liveMasterView";
  view.className = "view";
  view.hidden = true;
  const dialog = document.createElement("dialog");
  dialog.className = "identity-dialog";
  let mode = "categories", page = 0, generation = 0, editing = null, busy = false;
  const find = (selector) => view.querySelector(selector);
  const writable = () => ["ADMIN", "QLKHO"].includes(getRole());
  const config = () => masterScreens[mode];
  const message = (text, error = false) => {
    find("[data-message]").textContent = text;
    find("[data-message]").classList.toggle("text-danger", error);
  };

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
    const products = await masters[mode].products(editing);
    dialog.querySelector("[data-mappings]").innerHTML = products.length ? products.map((product) =>
      `<li>${esc(product)} <button type="button" class="row-action" data-unlink="${esc(product)}" aria-label="Bỏ liên kết ${esc(product)}"><svg aria-hidden="true"><use href="#icon-trash"/></svg></button></li>`).join("") : "<li>Chưa liên kết sản phẩm.</li>";
  }

  async function open(item = null) {
    editing = item?.[config().fields[0].key] || null;
    const canWrite = writable();
    dialog.innerHTML = `<div class="identity-dialog-content"><div class="panel-heading"><h2>${esc(config().title)}</h2>
      <button type="button" class="button button-quiet" data-close aria-label="Đóng">Đóng</button></div>
      <form><div class="form-grid">${config().fields.map((f, i) => `<label class="field"><span>${esc(f.label)}${f.required ? " *" : ""}</span>
        ${f.options ? `<select name="${f.key}">${!f.required ? '<option value="">Không yêu cầu</option>' : ""}${f.options.map((v) => `<option>${esc(v)}</option>`).join("")}</select>`
        : `<input name="${f.key}" type="${f.type || "text"}" ${f.max ? `maxlength="${f.max}"` : ""} ${f.pattern ? `pattern="${f.pattern}"` : ""} ${f.type === "number" ? `min="${f.min}" step="1"` : ""}>`}
        ${editing && (i === 0 || f.immutable) ? '<small>Không đổi sau khi tạo</small>' : ""}</label>`).join("")}</div>
      <div class="toolbar-actions"><button class="button button-primary" type="submit" ${canWrite ? "" : "hidden"}>Lưu</button>
      <button class="button button-quiet text-danger" type="button" data-delete ${editing && canWrite ? "" : "hidden"}>Xóa</button></div></form>
      ${editing && config().mapping ? `<section class="mapping-section"><h3>Sản phẩm liên kết</h3><ul data-mappings></ul>
        ${canWrite ? '<form data-link-form><label class="field"><span>Mã sản phẩm</span><input name="product" maxlength="6" pattern="[A-Za-z0-9]{1,6}" required></label><button class="button button-secondary" type="submit">Liên kết</button></form>' : ""}</section>` : ""}
      <p data-error role="alert" class="text-danger"></p></div>`;
    config().fields.forEach((f, index) => {
      const input = dialog.querySelector(`[name="${f.key}"]`);
      if (item) input.value = item[f.key] ?? "";
      input.required = !!f.required;
      input.disabled = !canWrite || !!editing && (index === 0 || f.immutable);
    });
    dialog.showModal();
    if (editing && config().mapping) {
      try { await mappings(); } catch (error) { dialog.querySelector("[data-error]").textContent = error.message; }
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
      ${["zones", "locations"].includes(mode) ? '<label class="field"><span>Mã kho</span><input data-filter="maKho" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label>' : ""}
      ${mode === "locations" ? '<label class="field"><span>Mã khu vực</span><input data-filter="maKhuVuc" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label>' : ""}
      <button class="button button-secondary" type="submit">Tìm kiếm</button></form><p data-message role="status" aria-live="polite"></p>
      <div class="table-wrap"><table><thead></thead><tbody></tbody></table></div><footer class="pagination"><span data-range></span><div>
      <button data-prev aria-label="Trang trước">&lt;</button><button data-next aria-label="Trang sau">&gt;</button></div></footer>`;
    load(0);
  }

  function start() {
    document.querySelector("#mainContent").append(view);
    document.body.append(dialog);
    view.addEventListener("submit", (event) => { event.preventDefault(); if (event.target.reportValidity()) load(0); });
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
