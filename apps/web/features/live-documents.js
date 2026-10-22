import { documentScreens, draftBody, actualBody } from "../data/document-models.js?v=session-shell-4";

export function createLiveDocuments({ documents, isAuthenticated, getRole, requireLogin, escapeHtml: esc }) {
  let mode = "inbound", current = null, pending = false, page = 0, generation = 0, reconciliationTicket = 0;
  const view = document.createElement("section");
  view.className = "view"; view.id = "liveDocumentView"; view.hidden = true;
  const el = (id) => view.querySelector(`#${id}`);
  const screen = () => documentScreens[mode];
  const writable = () => isAuthenticated() && (getRole() === "QLKHO" ||
    getRole() === "NVKHO" && ["inbound", "outbound"].includes(mode));
  const editable = () => writable() && (!current || current.trangThai === "NHAP");
  const code = () => current?.[screen().code];
  function message(text, error = false) {
    el("liveDocMessage").textContent = text;
    el("liveDocMessage").classList.toggle("text-danger", error);
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
    for (const input of el("liveDocAllocations").querySelectorAll("input")) input.disabled = !editable();
    for (const button of el("liveDocAllocations").querySelectorAll("button")) button.hidden = !editable();
  }
  const trash = '<svg aria-hidden="true"><use href="#icon-trash"/></svg>';
  function input(key, type, value = "", persisted = false) {
    const shared = `name="${key}" data-type="${type || "code"}" data-persisted="${persisted}" aria-label="${esc(key)}"`;
    if (type === "condition") return `<select ${shared}><option${value === "Tốt" ? " selected" : ""}>Tốt</option><option${value === "Hư hỏng" ? " selected" : ""}>Hư hỏng</option></select>`;
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
    el("liveDocAllocations").insertAdjacentHTML("beforeend", `<tr>${[["maSanPham"], ["maViTri"], ["soLuong", "quantity"]].map(([key, type]) => `<td>${input(key, type, part[key])}</td>`).join("")}
      <td><input name="ngaySanXuat" type="date" aria-label="Ngày sản xuất" value="${esc(part.ngaySanXuat || "")}"></td>
      <td><input name="hanSuDung" type="date" aria-label="Hạn sử dụng" value="${esc(part.hanSuDung || "")}"></td>
      <td><button type="button" class="row-action" data-remove aria-label="Xóa phân bổ">${trash}</button></td></tr>`);
    actions();
  }
  const rows = (id) => [...el(id).rows].map((row) => Object.fromEntries([...row.querySelectorAll("input, select")].map((i) => [i.name, i.value])));
  function display(data, allocations = null) {
    reconciliationTicket++;
    current = data;
    el("liveDocState").textContent = `${code()} · ${data.trangThai} · ${data.chiTiet.length} dòng`;
    el("liveDocLoadCode").value = code();
    el("liveDocPartner").value = data[screen().partner] || "";
    el("liveDocNote").value = data.ghiChu || "";
    el("liveDocRows").replaceChildren();
    for (const line of data.chiTiet) addLine(line, true);
    el("liveDocAllocations").replaceChildren();
    if (mode === "inbound" && data.trangThai === "NHAP") {
      for (const part of allocations || data.chiTiet) addAllocation(part);
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
    el("liveDocForm").reset();
    el("liveDocLoadCode").value = "";
    el("liveDocState").textContent = writable() ? "Phiếu mới" : "Chọn phiếu trong danh sách để xem";
    el("liveDocRows").replaceChildren(); el("liveDocAllocations").replaceChildren();
    el("liveDocFefoResult").replaceChildren();
    if (mode !== "count" && writable()) addLine();
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
    const allocations = rows("liveDocAllocations");
    const body = draftBody(mode, el("liveDocPartner").value, el("liveDocNote").value, lines, !!current);
    const data = current ? await documents[mode].update(code(), body) : await documents[mode].create(body);
    display(data, mode === "inbound" && allocations.length ? allocations : null);
  }
  function show(nextMode) {
    if (pending) return;
    generation++; mode = nextMode;
    el("liveDocTitle").textContent = screen().title;
    el("liveDocPartnerLabel").textContent = screen().label || "";
    el("liveDocPartner").required = !!screen().partner;
    el("liveDocHead").innerHTML = `<tr>${screen().fields.map(([, label]) => `<th>${esc(label)}</th>`).join("")}<th></th></tr>`;
    el("liveDocStatus").value = "";
    reset(); loadList(0);
  }
  function start() {
    view.innerHTML = `<div class="section-toolbar"><h2 id="liveDocTitle"></h2><button class="button button-primary" id="liveDocNew">Phiếu mới</button></div>
      <div class="live-filters"><label class="field"><span>Trạng thái</span><select id="liveDocStatus"><option value="">Tất cả</option><option value="NHAP">Nháp</option><option value="DA_HOAN_THANH">Đã hoàn thành</option><option value="DA_HUY">Đã hủy</option></select></label><button class="button button-secondary" id="liveDocRefresh">Làm mới</button>
      <label class="field"><span>Mã phiếu</span><input id="liveDocLoadCode" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label><button class="button button-secondary" id="liveDocLoad">Tải phiếu</button></div>
      <div class="table-wrap"><table><thead><tr><th>Mã phiếu</th><th>Thời điểm tạo</th><th>Trạng thái</th><th>Nhân viên</th><th>Chi tiết</th></tr></thead><tbody id="liveDocListRows"></tbody></table></div>
      <footer class="pagination"><span id="liveDocRange"></span><div><button id="liveDocPrevious" aria-label="Trang trước">&lt;</button><button id="liveDocNext" aria-label="Trang sau">&gt;</button></div></footer>
      <section class="live-document-editor"><h3 id="liveDocState">Phiếu mới</h3><p id="liveDocMessage" role="status" aria-live="polite"></p>
      <form id="liveDocForm"><div class="form-grid"><label class="field" id="liveDocPartnerField"><span id="liveDocPartnerLabel"></span><input id="liveDocPartner" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label>
      <label class="field"><span>Ghi chú</span><textarea id="liveDocNote" maxlength="1000" rows="2"></textarea></label></div>
      <div class="table-wrap"><table class="live-lines"><thead id="liveDocHead"></thead><tbody id="liveDocRows"></tbody></table></div>
      <button class="button button-secondary" id="liveDocAdd" type="button">Thêm dòng</button>
      <div class="toolbar-actions live-document-actions"><button class="button button-primary" id="liveDocSave" type="submit">Lưu nháp</button>
      <button class="button button-primary" id="liveDocCreateCount" type="button">Tạo phiếu kiểm kê</button>
      <button class="button button-primary" id="liveDocComplete" type="button">Hoàn tất</button><button class="button button-quiet" id="liveDocCancel" type="button">Hủy nháp</button></div></form>
      <section id="liveDocAllocationSection" class="mapping-section"><h3>Phân bổ nhập kho</h3><div class="table-wrap"><table class="live-lines"><thead><tr><th>Sản phẩm</th><th>Vị trí</th><th>Số lượng</th><th>Ngày sản xuất</th><th>Hạn sử dụng</th><th></th></tr></thead><tbody id="liveDocAllocations"></tbody></table></div><button class="button button-secondary" id="liveDocAddAllocation">Thêm phân bổ</button></section>
      <section id="liveDocFefo" class="mapping-section"><h3>Gợi ý FEFO</h3><form id="liveDocFefoForm" class="live-filters"><label class="field"><span>Sản phẩm</span><input name="product" maxlength="6" pattern="[A-Za-z0-9]{1,6}" required></label>
      <label class="field"><span>Số lượng</span><input name="quantity" type="number" min="1" step="1" required></label><button class="button button-secondary" type="submit">Tra cứu FEFO</button></form><div id="liveDocFefoResult"></div></section>
      <section id="liveDocReconciliation" class="mapping-section" hidden><h3>Đối soát giá trị</h3><p id="liveDocReconciliationState" role="status" aria-live="polite"></p>
      <form id="liveDocReconciliationForm" class="live-reconciliation-form" hidden><label class="field"><span>Giá trị kế toán đối soát (₫)</span><input name="giaTriDoiSoat" type="number" min="0" step="0.0001" required></label>
      <label class="field"><span>Ghi chú sai lệch</span><textarea name="ghiChu" maxlength="1000" rows="2" placeholder="Bắt buộc nếu giá trị không khớp"></textarea></label>
      <button class="button button-primary" type="submit">Xác nhận đối soát</button></form></section></section>`;
    document.querySelector("#mainContent").append(view);
    el("liveDocNew").addEventListener("click", reset);
    el("liveDocRefresh").addEventListener("click", () => loadList(0));
    el("liveDocStatus").addEventListener("change", () => loadList(0));
    el("liveDocPrevious").addEventListener("click", () => loadList(page - 1));
    el("liveDocNext").addEventListener("click", () => loadList(page + 1));
    function load(codeValue) { if (codeValue) run(async () => { display(await documents[mode].get(codeValue)); message(""); }); }
    el("liveDocLoad").addEventListener("click", () => { if (el("liveDocLoadCode").reportValidity()) load(el("liveDocLoadCode").value.trim()); });
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
  function clear() { generation++; current = null; if (!pending) reset(); }
  return { start, show, clear, isBusy: () => pending, viewId: view.id };
}
