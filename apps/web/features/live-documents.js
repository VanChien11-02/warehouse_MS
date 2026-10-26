import { documentScreens, draftBody, actualBody } from "../data/document-models.js?v=inbound-drafts-1";
import { nextCode, selectOptions } from "../data/master-api.js?v=session-shell-4";
import { createLiveInboundHistory } from "./live-inbound-history.js?v=inbound-history-2";

const docPrefixes = { inbound: "PN", outbound: "PX", transfer: "PC", count: "KK", return: "TH" };

export function createLiveDocuments({ documents, masters, products, inventory, isAuthenticated, getRole, requireLogin, escapeHtml: esc }) {
  let mode = "inbound", current = null, pending = false, page = 0, generation = 0, reconciliationTicket = 0;
  const cache = { products: [], locations: [], suppliers: [], recipients: [], stocks: [], outbounds: [], listItems: [], sourceLines: [] };
  const view = document.createElement("section");
  view.className = "view"; view.id = "liveDocumentView"; view.hidden = true;
  const el = (id) => view.querySelector(`#${id}`);
  const screen = () => documentScreens[mode];
  const writable = () => isAuthenticated() && (getRole() === "QLKHO" ||
    getRole() === "NVKHO" && ["inbound", "outbound"].includes(mode));
  const editable = () => writable() && (!current || current.trangThai === "NHAP");
  const code = () => current?.[screen().code];
  const history = createLiveInboundHistory({ api: documents.inbound, escapeHtml: esc, requireLogin,
    onOpen: (receipt) => {
      showTab(false);
      run(async () => { display(await documents.inbound.get(receipt)); message(""); el("liveDocState").scrollIntoView({ block: "start" }); });
    }
  });
  function showTab(showHistory) {
    el("liveDocWorkspace").hidden = showHistory;
    el("liveDocHistory").hidden = !showHistory;
    for (const [id, selected] of [["liveDocTabDocuments", !showHistory], ["liveDocTabHistory", showHistory]]) {
      el(id).setAttribute("aria-selected", String(selected));
      el(id).tabIndex = selected ? 0 : -1;
    }
    history.show(showHistory);
  }
  function message(text, error = false) {
    el("liveDocMessage").textContent = text;
    el("liveDocMessage").classList.toggle("text-danger", error);
  }
  function productOptions(selected = "") {
    return selectOptions(cache.products, "maSanPham", (p) => `${p.maSanPham} · ${p.tenSanPham}`, selected, "Chọn sản phẩm", esc);
  }
  function locationOptions(selected = "") {
    return selectOptions(cache.locations, "maViTri", (l) => `${l.maViTri} · ${l.tenViTri}${l.maKho ? ` (${l.maKho})` : ""}`, selected, "Chọn vị trí", esc);
  }
  function lotOptions(selected = "") {
    const source = mode === "return" && cache.sourceLines.length
      ? cache.sourceLines.map((line) => ({
        maLo: line.maLo,
        label: `${line.maLo} · Vị trí ${line.maViTri} (Đã xuất: ${line.soLuong})`
      }))
      : cache.stocks.map((s) => ({
        maLo: s.maLo,
        label: `${s.maLo} · ${s.maSanPham} - ${s.tenSanPham} (${s.maViTri} · Tồn: ${s.soLuongTon})`
      }));
    return selectOptions(source, "maLo", (item) => item.label, selected, "Chọn mã lô", esc);
  }
  function partnerOptions(selected = "") {
    if (mode === "inbound") {
      return selectOptions(cache.suppliers, "maNhaCungCap", (s) => `${s.maNhaCungCap} · ${s.tenNhaCungCap}`, selected, "Chọn nhà cung cấp", esc);
    }
    if (mode === "outbound") {
      return selectOptions(cache.recipients, "maDoiTacNhanHang", (r) => `${r.maDoiTacNhanHang} · ${r.tenDoiTac}`, selected, "Chọn đối tác nhận", esc);
    }
    if (mode === "count") {
      return selectOptions(cache.locations, "maViTri", (l) => `${l.maViTri} · ${l.tenViTri}${l.maKho ? ` (${l.maKho})` : ""}`, selected, "Chọn vị trí kiểm kê", esc);
    }
    if (mode === "return") {
      return selectOptions(cache.outbounds, "maPhieuXuat", (o) => `${o.maPhieuXuat}${o.maDoiTacNhanHang ? ` · ${o.maDoiTacNhanHang}` : ""}`, selected, "Chọn phiếu xuất gốc", esc);
    }
    return '<option value="">Không yêu cầu</option>';
  }
  function syncCodeDisplay() {
    const autoCode = code() || nextCode(docPrefixes[mode] || "PN", cache.listItems, screen().code);
    if (el("liveDocCode")) el("liveDocCode").value = code() || `${autoCode} (Tự tạo)`;
    if (!current) {
      el("liveDocState").textContent = writable() ? `Phiếu mới · Mã tự tạo: ${autoCode}` : "Chọn phiếu trong danh sách để xem";
    }
  }
  function syncSelects() {
    if (el("liveDocPartner") && screen().partner) {
      const currentPartner = el("liveDocPartner").value || current?.[screen().partner] || "";
      el("liveDocPartner").innerHTML = partnerOptions(currentPartner);
    }
    if (el("liveDocLoadCode")) {
      const selectedDoc = el("liveDocLoadCode").value || code() || "";
      el("liveDocLoadCode").innerHTML = selectOptions(cache.listItems, screen().code,
        (item) => `${item[screen().code]} · ${item.trangThai}`, selectedDoc, "Chọn mã phiếu...", esc);
    }
    for (const select of view.querySelectorAll('#liveDocRows select, #liveDocAllocations select, #liveDocFefoForm select')) {
      const val = select.value;
      if (select.name === "maSanPham" || select.name === "product") select.innerHTML = productOptions(val);
      else if (select.name === "maLo") select.innerHTML = lotOptions(val);
      else if (["maViTri", "maViTriNguon", "maViTriDich"].includes(select.name)) select.innerHTML = locationOptions(val);
    }
    syncCodeDisplay();
    actions();
  }
  async function loadReferences() {
    if (!isAuthenticated()) return;
    const tasks = [];
    if (products?.all) tasks.push(products.all().then((items) => { cache.products = items; }).catch(() => {}));
    if (masters?.locations?.all) tasks.push(masters.locations.all().then((items) => { cache.locations = items; }).catch(() => {}));
    if (mode === "inbound" && masters?.suppliers?.all) tasks.push(masters.suppliers.all().then((items) => { cache.suppliers = items; }).catch(() => {}));
    if (mode === "outbound" && masters?.recipients?.all) tasks.push(masters.recipients.all().then((items) => { cache.recipients = items; }).catch(() => {}));
    if (["outbound", "transfer", "count", "return"].includes(mode) && inventory?.all) {
      tasks.push(inventory.all({ chiKhaDung: mode === "outbound" }).then((items) => { cache.stocks = items; }).catch(() => {}));
    }
    if (mode === "return" && documents?.outbound?.all) {
      tasks.push(documents.outbound.all({ trangThai: "DA_HOAN_THANH" }).then((items) => { cache.outbounds = items; }).catch(() => {}));
    }
    await Promise.all(tasks);
    syncSelects();
  }
  function actions() {
    const draft = current?.trangThai === "NHAP";
    el("liveDocForm").hidden = !current && !writable();
    el("liveDocSave").hidden = !editable() || mode === "count" && !current;
    el("liveDocCreateCount").hidden = mode !== "count" || !!current || !writable();
    el("liveDocComplete").hidden = !draft || getRole() !== "QLKHO";
    el("liveDocCancel").hidden = !draft || !writable();
    el("liveDocAdd").hidden = !editable() || mode === "count" && !current;
    el("liveDocAllocationSection").hidden = mode !== "inbound" || !editable();
    el("liveDocAddAllocation").hidden = !editable();
    el("liveDocFefo").hidden = mode !== "outbound" || !draft || !writable();
    el("liveDocNew").hidden = !writable();
    el("liveDocReconciliation").hidden = !current || current.trangThai !== "DA_HOAN_THANH"
      || !["inbound", "outbound"].includes(mode) || !["QLKHO", "KETOAN"].includes(getRole());
    el("liveDocPartnerField").hidden = !screen().partner;
    el("liveDocPartner").disabled = !editable() || !!current && ["return", "count"].includes(mode);
    el("liveDocNote").disabled = !editable() || mode === "count" && !!current;
    for (const input of el("liveDocRows").querySelectorAll("input, select")) {
      input.disabled = !editable() || input.dataset.type === "snapshot" || mode === "count" && input.name === "maLo" && input.dataset.persisted === "true";
    }
    for (const button of el("liveDocRows").querySelectorAll("button")) button.hidden = !editable() || mode === "count";
    for (const input of el("liveDocAllocations").querySelectorAll("input, select")) input.disabled = !editable();
    for (const button of el("liveDocAllocations").querySelectorAll("button")) button.hidden = !editable();
  }
  const trash = '<svg aria-hidden="true"><use href="#icon-trash"/></svg>';
  function input(key, type, value = "", persisted = false) {
    const shared = `name="${key}" data-type="${type || "code"}" data-persisted="${persisted}" aria-label="${esc(key)}"`;
    if (type === "condition") return `<select ${shared}><option${value === "Tốt" ? " selected" : ""}>Tốt</option><option${value === "Hư hỏng" ? " selected" : ""}>Hư hỏng</option></select>`;
    if (key === "maSanPham") return `<select ${shared} required>${productOptions(value)}</select>`;
    if (key === "maLo") return `<select ${shared} required>${lotOptions(value)}</select>`;
    if (["maViTri", "maViTriNguon", "maViTriDich"].includes(key)) return `<select ${shared} required>${locationOptions(value)}</select>`;
    const number = ["quantity", "actual", "snapshot", "money"].includes(type);
    return `<input ${shared} value="${esc(value ?? "")}" ${type !== "reason" ? "required" : ""}
      ${number ? `type="number" min="${type === "quantity" ? 1 : 0}" step="${type === "money" ? "0.0001" : "1"}"` : `maxlength="${type === "reason" ? 500 : 6}" ${type === "reason" ? "" : 'pattern="[A-Za-z0-9]{1,6}"'}`}>`;
  }
  function addLine(line = {}, persisted = false) {
    el("liveDocRows").insertAdjacentHTML("beforeend", `<tr>${screen().fields.map(([key, , type]) =>
      `<td>${input(key, type, line[key] ?? (type === "snapshot" ? 0 : ""), persisted)}</td>`).join("")}<td><button type="button" class="row-action" data-remove aria-label="Xóa dòng">${trash}</button></td></tr>`);
    actions();
  }
  function addAllocation(part = {}) {
    const defaultLoc = part.maViTri ?? cache.locations[0]?.maViTri ?? "";
    el("liveDocAllocations").insertAdjacentHTML("beforeend", `<tr>${[["maSanPham"], ["maViTri"], ["soLuong", "quantity"]].map(([key, type]) =>
      `<td>${input(key, type, key === "maViTri" ? defaultLoc : part[key])}</td>`).join("")}
      <td><input name="ngaySanXuat" type="date" aria-label="Ngày sản xuất" value="${esc(part.ngaySanXuat || "")}"></td>
      <td><input name="hanSuDung" type="date" aria-label="Hạn sử dụng" value="${esc(part.hanSuDung || "")}"></td>
      <td><button type="button" class="row-action" data-remove aria-label="Xóa phân bổ">${trash}</button></td></tr>`);
    actions();
  }
  const rows = (id) => [...el(id).rows].map((row) => Object.fromEntries([...row.querySelectorAll("input, select")].map((i) => [i.name, i.value])));
  function display(data) {
    reconciliationTicket++;
    current = data;
    el("liveDocState").textContent = `${code()} · ${data.trangThai} · ${data.chiTiet.length} dòng`;
    if (el("liveDocCode")) el("liveDocCode").value = code();
    el("liveDocLoadCode").innerHTML = selectOptions(cache.listItems, screen().code,
      (item) => `${item[screen().code]} · ${item.trangThai}`, code(), "Chọn mã phiếu...", esc);
    if (screen().partner) {
      el("liveDocPartner").innerHTML = partnerOptions(data[screen().partner] || "");
    }
    el("liveDocNote").value = data.ghiChu || "";
    el("liveDocRows").replaceChildren();
    for (const line of data.chiTiet) addLine(line, true);
    el("liveDocAllocations").replaceChildren();
    if (mode === "inbound" && data.trangThai === "NHAP") {
      for (const part of data.phanBo ?? data.chiTiet) addAllocation(part);
    }
    actions();
    if (!el("liveDocReconciliation").hidden) loadReconciliation(data, reconciliationTicket);
  }
  async function loadReconciliation(document, ticket) {
    const kind = mode === "inbound" ? "NHAP" : "XUAT";
    const documentCode = document[screen().code];
    el("liveDocReconciliationState").textContent = "Đang kiểm tra trạng thái đối soát...";
    el("liveDocReconciliationForm").hidden = true;
    try {
      const result = await documents.reconciliation.get(kind, documentCode);
      if (ticket !== reconciliationTicket) return;
      el("liveDocReconciliationState").textContent = result.trangThai === "KHOP"
        ? `Đã khớp · Giá trị phiếu ${result.giaTriChungTu} · Kế toán ${result.maTaiKhoanKeToan}`
        : `Có chênh lệch ${result.chenhLech} · ${result.ghiChu || "Chưa có ghi chú"}`;
    } catch (error) {
      if (ticket !== reconciliationTicket) return;
      if (error.status === 404) {
        el("liveDocReconciliationState").textContent = "Chưa đối soát giá trị.";
        el("liveDocReconciliationForm").hidden = getRole() !== "KETOAN";
      } else {
        el("liveDocReconciliationState").textContent = error.message || "Không tải được trạng thái đối soát.";
        if (error.status === 401) requireLogin();
      }
    }
  }
  function reset() {
    reconciliationTicket++;
    current = null;
    cache.sourceLines = [];
    el("liveDocForm").reset();
    if (screen().partner) el("liveDocPartner").innerHTML = partnerOptions("");
    el("liveDocLoadCode").value = "";
    el("liveDocRows").replaceChildren(); el("liveDocAllocations").replaceChildren();
    el("liveDocFefoResult").replaceChildren();
    if (mode !== "count" && writable()) addLine();
    syncCodeDisplay();
    message(""); actions();
  }
  async function loadList(nextPage = page) {
    const ticket = ++generation;
    page = nextPage;
    el("liveDocListRows").replaceChildren();
    el("liveDocRange").textContent = "Đang tải...";
    el("liveDocPrevious").disabled = el("liveDocNext").disabled = true;
    try {
      const filters = el("liveDocStatus").value ? { trangThai: el("liveDocStatus").value } : {};
      const result = await documents[mode].list(page, 10, filters);
      if (ticket !== generation) return;
      cache.listItems = result.items || [];
      syncCodeDisplay();
      el("liveDocLoadCode").innerHTML = selectOptions(cache.listItems, screen().code,
        (item) => `${item[screen().code]} · ${item.trangThai}`, code() || "", "Chọn mã phiếu...", esc);
      el("liveDocListRows").innerHTML = result.items.map((item) => `<tr><td>${esc(item[screen().code])}</td>
        <td>${esc(item[screen().date] || "—")}</td><td>${esc(item.trangThai)}</td><td>${esc(item.maNhanVien)}</td>
        <td><button class="row-action" data-load="${esc(item[screen().code])}" aria-label="Mở ${esc(item[screen().code])}"><svg aria-hidden="true"><use href="#icon-chevron"/></svg></button></td></tr>`).join("");
      el("liveDocRange").textContent = result.items.length ? `${result.totalElements} phiếu · trang ${page + 1}/${result.totalPages}` : "Không có chứng từ phù hợp.";
      el("liveDocPrevious").disabled = page === 0;
      el("liveDocNext").disabled = page + 1 >= result.totalPages;
    } catch (error) { if (ticket === generation) { el("liveDocRange").textContent = error.message; if (error.status === 401) requireLogin(); } }
  }
  async function run(action) {
    if (pending) return;
    pending = true;
    // A frozen form keeps asynchronous responses bound to the values that were submitted.
    view.inert = true;
    message("Đang xử lý...");
    try { await action(); } catch (error) { message(error.message || "Không thực hiện được thao tác.", true); if (error.status === 401) requireLogin(); }
    finally { pending = false; view.inert = false; actions(); }
  }
  function validLines() {
    const body = el("liveDocRows");
    if (!body.rows.length) { message("Cần ít nhất một dòng chi tiết.", true); return false; }
    const invalid = body.querySelector(":invalid");
    if (invalid) { invalid.reportValidity(); return false; }
    return true;
  }
  async function save() {
    const lines = rows("liveDocRows");
    if (mode === "count") {
      // Each accepted line remains saved if a later line fails; the document is still a draft.
      for (const line of lines) {
        if (line.soLuongThucTe === "") throw new Error("Nhập số lượng thực tế cho mọi dòng.");
        if (Number(line.soLuongThucTe) !== Number(line.soLuongHeThong) && !line.lyDoChenhLech.trim()) throw new Error(`Nhập lý do chênh lệch cho lô ${line.maLo}.`);
      }
      for (const line of lines) await documents.count.setActual(code(), line.maLo, actualBody(line));
      display(await documents.count.get(code()));
      return;
    }
    const allocations = mode === "inbound" ? rows("liveDocAllocations") : null;
    const body = draftBody(mode, el("liveDocPartner").value, el("liveDocNote").value,
      lines, !!current, allocations);
    const data = current ? await documents[mode].update(code(), body) : await documents[mode].create(body);
    display(data);
  }
  function show(nextMode) {
    if (pending) return;
    generation++; mode = nextMode;
    cache.listItems = [];
    cache.sourceLines = [];
    el("liveDocTitle").textContent = screen().title;
    el("liveDocPartnerLabel").textContent = screen().label || "";
    el("liveDocPartner").required = !!screen().partner;
    el("liveDocHead").innerHTML = `<tr>${screen().fields.map(([, label]) => `<th>${esc(label)}</th>`).join("")}<th></th></tr>`;
    el("liveDocStatus").value = "";
    el("liveDocTabs").hidden = mode !== "inbound" || !["QLKHO", "KETOAN"].includes(getRole());
    if (!el("liveDocTabs").hidden) {
      el("liveDocWorkspace").setAttribute("role", "tabpanel");
      el("liveDocWorkspace").setAttribute("aria-labelledby", "liveDocTabDocuments");
    } else {
      el("liveDocWorkspace").removeAttribute("role");
      el("liveDocWorkspace").removeAttribute("aria-labelledby");
    }
    showTab(false);
    reset();
    loadReferences();
    loadList(0);
  }
  function start() {
    view.innerHTML = `<div class="section-toolbar"><h2 id="liveDocTitle"></h2><button class="button button-primary" id="liveDocNew">Phiếu mới</button></div>
      <div id="liveDocTabs" class="document-tabs" role="tablist" aria-label="Tra cứu nhập kho" hidden><button id="liveDocTabDocuments" type="button" role="tab" aria-selected="true" aria-controls="liveDocWorkspace">Phiếu nhập</button><button id="liveDocTabHistory" type="button" role="tab" aria-selected="false" aria-controls="liveDocHistory" tabindex="-1">Lịch sử nhập kho</button></div>
      <div id="liveDocWorkspace">
      <div class="live-filters"><label class="field"><span>Trạng thái</span><select id="liveDocStatus"><option value="">Tất cả</option><option value="NHAP">Nháp</option><option value="DA_HOAN_THANH">Đã hoàn thành</option><option value="DA_HUY">Đã hủy</option></select></label><button class="button button-secondary" id="liveDocRefresh">Làm mới</button>
      <label class="field"><span>Mã phiếu</span><select id="liveDocLoadCode"><option value="">Chọn mã phiếu...</option></select></label><button class="button button-secondary" id="liveDocLoad">Tải phiếu</button></div>
      <div class="table-wrap"><table><thead><tr><th>Mã phiếu</th><th>Thời điểm tạo</th><th>Trạng thái</th><th>Nhân viên</th><th>Chi tiết</th></tr></thead><tbody id="liveDocListRows"></tbody></table></div>
      <footer class="pagination"><span id="liveDocRange"></span><div><button id="liveDocPrevious" aria-label="Trang trước">&lt;</button><button id="liveDocNext" aria-label="Trang sau">&gt;</button></div></footer>
      <section class="live-document-editor"><h3 id="liveDocState">Phiếu mới</h3><p id="liveDocMessage" role="status" aria-live="polite"></p>
      <form id="liveDocForm"><div class="form-grid"><label class="field"><span>Mã phiếu</span><input id="liveDocCode" readonly></label><label class="field" id="liveDocPartnerField"><span id="liveDocPartnerLabel"></span><select id="liveDocPartner"></select></label>
      <label class="field"><span>Ghi chú</span><textarea id="liveDocNote" maxlength="1000" rows="2"></textarea></label></div>
      <div class="table-wrap"><table class="live-lines"><thead id="liveDocHead"></thead><tbody id="liveDocRows"></tbody></table></div>
      <button class="button button-secondary" id="liveDocAdd" type="button">Thêm dòng</button>
      <div class="toolbar-actions live-document-actions"><button class="button button-primary" id="liveDocSave" type="submit">Lưu nháp</button>
      <button class="button button-primary" id="liveDocCreateCount" type="button">Tạo phiếu kiểm kê</button>
      <button class="button button-primary" id="liveDocComplete" type="button">Hoàn tất</button><button class="button button-quiet" id="liveDocCancel" type="button">Hủy nháp</button></div></form>
      <section id="liveDocAllocationSection" class="mapping-section"><h3>Phân bổ nhập kho</h3><div class="table-wrap"><table class="live-lines"><thead><tr><th>Sản phẩm</th><th>Vị trí</th><th>Số lượng</th><th>Ngày sản xuất</th><th>Hạn sử dụng</th><th></th></tr></thead><tbody id="liveDocAllocations"></tbody></table></div><button class="button button-secondary" id="liveDocAddAllocation">Thêm phân bổ</button></section>
      <section id="liveDocFefo" class="mapping-section"><h3>Gợi ý FEFO</h3><form id="liveDocFefoForm" class="live-filters"><label class="field"><span>Sản phẩm</span><select name="product" required><option value="">Chọn sản phẩm</option></select></label>
      <label class="field"><span>Số lượng</span><input name="quantity" type="number" min="1" step="1" required></label><button class="button button-secondary" type="submit">Tra cứu FEFO</button></form><div id="liveDocFefoResult"></div></section>
      <section id="liveDocReconciliation" class="mapping-section" hidden><h3>Đối soát giá trị</h3><p id="liveDocReconciliationState" role="status" aria-live="polite"></p>
      <form id="liveDocReconciliationForm" class="live-reconciliation-form" hidden><label class="field"><span>Giá trị kế toán đối soát (₫)</span><input name="giaTriDoiSoat" type="number" min="0" step="0.0001" required></label>
      <label class="field"><span>Ghi chú sai lệch</span><textarea name="ghiChu" maxlength="1000" rows="2" placeholder="Bắt buộc nếu giá trị không khớp"></textarea></label>
      <button class="button button-primary" type="submit">Xác nhận đối soát</button></form></section></section></div>
      <section id="liveDocHistory" role="tabpanel" aria-labelledby="liveDocTabHistory" hidden></section>`;
    document.querySelector("#mainContent").append(view);
    history.start(el("liveDocHistory"));
    el("liveDocTabDocuments").addEventListener("click", () => showTab(false));
    el("liveDocTabHistory").addEventListener("click", () => showTab(true));
    el("liveDocTabs").addEventListener("keydown", (event) => {
      if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
      event.preventDefault();
      const showHistory = event.key === "End" || (event.key !== "Home" && event.target.id === "liveDocTabDocuments");
      showTab(showHistory);
      el(showHistory ? "liveDocTabHistory" : "liveDocTabDocuments").focus();
    });
    el("liveDocNew").addEventListener("click", () => { showTab(false); reset(); });
    el("liveDocRefresh").addEventListener("click", () => loadList(0));
    el("liveDocStatus").addEventListener("change", () => loadList(0));
    el("liveDocPrevious").addEventListener("click", () => loadList(page - 1));
    el("liveDocNext").addEventListener("click", () => loadList(page + 1));
    function load(codeValue) { if (codeValue) run(async () => { display(await documents[mode].get(codeValue)); message(""); }); }
    el("liveDocLoad").addEventListener("click", () => { if (el("liveDocLoadCode").value) load(el("liveDocLoadCode").value.trim()); });
    el("liveDocLoadCode").addEventListener("change", () => { if (el("liveDocLoadCode").value) load(el("liveDocLoadCode").value.trim()); });
    el("liveDocPartner").addEventListener("change", async () => {
      if (mode === "return" && el("liveDocPartner").value) {
        try {
          const outboundDoc = await documents.outbound.get(el("liveDocPartner").value);
          cache.sourceLines = outboundDoc.chiTiet || [];
          syncSelects();
        } catch { cache.sourceLines = []; }
      }
    });
    el("liveDocRows").addEventListener("change", (event) => {
      const target = event.target;
      const row = target.closest("tr");
      if (!row) return;
      if (target.name === "maSanPham") {
        const prod = cache.products.find((p) => p.maSanPham === target.value);
        const priceInput = row.querySelector('[name="donGiaNhap"]');
        if (prod && priceInput && (!priceInput.value || Number(priceInput.value) === 0)) {
          priceInput.value = String(prod.giaNhapMacDinh ?? 0);
        }
      } else if (target.name === "maLo") {
        const stock = cache.stocks.find((s) => s.maLo === target.value)
          || cache.sourceLines.find((s) => s.maLo === target.value);
        if (stock) {
          const locSelect = row.querySelector('[name="maViTri"], [name="maViTriNguon"]');
          if (locSelect && stock.maViTri) {
            locSelect.innerHTML = locationOptions(stock.maViTri);
            locSelect.value = stock.maViTri;
          }
          const priceInput = row.querySelector('[name="donGiaXuat"]');
          const prod = cache.products.find((p) => p.maSanPham === stock.maSanPham);
          if (prod && priceInput && (!priceInput.value || Number(priceInput.value) === 0)) {
            priceInput.value = String(prod.giaBanMacDinh ?? 0);
          }
        }
      }
    });
    el("liveDocListRows").addEventListener("click", (event) => { const button = event.target.closest("[data-load]"); if (button) load(button.dataset.load); });
    el("liveDocAdd").addEventListener("click", () => { if (editable()) addLine(); });
    el("liveDocAddAllocation").addEventListener("click", () => { if (editable()) addAllocation(); });
    view.addEventListener("click", (event) => { const button = event.target.closest("[data-remove]"); if (button && editable()) button.closest("tr").remove(); });
    el("liveDocForm").addEventListener("submit", (event) => {
      event.preventDefault(); if (!editable() || !validLines()) return;
      run(async () => { await save(); message("Đã lưu phiếu nháp."); await loadList(0); });
    });
    el("liveDocCreateCount").addEventListener("click", () => {
      if (!writable() || current || !el("liveDocPartner").reportValidity()) return;
      run(async () => { display(await documents.count.create(draftBody("count", el("liveDocPartner").value, el("liveDocNote").value, []))); message("Đã tạo phiếu kiểm kê."); await loadList(0); });
    });
    el("liveDocComplete").addEventListener("click", () => {
      if (!current || getRole() !== "QLKHO" || current.trangThai !== "NHAP" || !validLines() || !el("liveDocForm").reportValidity()) return;
      const allocations = rows("liveDocAllocations");
      if (mode === "inbound") {
        const invalid = el("liveDocAllocations").querySelector(":invalid");
        if (invalid) { invalid.reportValidity(); return; }
        if (!allocations.length) { message("Cần phân bổ vị trí nhập kho.", true); return; }
      }
      run(async () => {
        await save();
        const body = mode === "inbound" ? { phanBo: allocations.map((part) => ({ ...part, soLuong: Number(part.soLuong), ngaySanXuat: part.ngaySanXuat || null, hanSuDung: part.hanSuDung || null })) } : undefined;
        await documents[mode].complete(code(), body);
        display(await documents[mode].get(code())); message("Đã hoàn tất và ghi sổ."); await loadList(0);
      });
    });
    el("liveDocCancel").addEventListener("click", () => {
      if (!editable() || !current || !confirm(`Hủy phiếu ${code()}?`)) return;
      run(async () => { display(await documents[mode].cancel(code())); message("Đã hủy phiếu nháp."); await loadList(0); });
    });
    el("liveDocFefoForm").addEventListener("submit", (event) => {
      event.preventDefault(); if (!current || !writable()) return;
      run(async () => {
        const form = event.target;
        const result = await documents.outbound.suggest(code(), form.elements.product.value.trim(), Number(form.elements.quantity.value));
        el("liveDocFefoResult").textContent = `${result.phanBo.map((p) => `${p.maLo} / ${p.maViTri}: ${p.soLuong}`).join("; ") || "Không có tồn phù hợp"}. Thiếu: ${result.soLuongThieu}.`;
        message("");
      });
    });
    el("liveDocReconciliationForm").addEventListener("submit", (event) => {
      event.preventDefault();
      if (getRole() !== "KETOAN" || !current || current.trangThai !== "DA_HOAN_THANH"
        || !["inbound", "outbound"].includes(mode) || !event.target.reportValidity()) return;
      const form = event.target;
      const kind = mode === "inbound" ? "NHAP" : "XUAT";
      const currentCode = code();
      run(async () => {
        await documents.reconciliation.create(kind, currentCode, {
          giaTriDoiSoat: Number(form.elements.giaTriDoiSoat.value),
          ghiChu: form.elements.ghiChu.value.trim() || null
        });
        await loadReconciliation(current, reconciliationTicket);
        message("Đã ghi nhận đối soát giá trị.");
      });
    });
  }
  function clear() { generation++; current = null; history.clear(); if (!pending) reset(); }
  return { start, show, clear, isBusy: () => pending, viewId: view.id };
}
