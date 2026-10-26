import { selectOptions } from "../data/master-api.js?v=session-shell-4";

export function createLiveInventory({ inventory, masters, products, escapeHtml, isAuthenticated, requireLogin }) {
  const view = document.querySelector("#inventoryView");
  const table = document.querySelector("#inventoryTable");
  const toolbar = view.querySelector(".data-toolbar");
  const refresh = document.querySelector("#refreshInventoryButton");
  let page = 0;
  let requestId = 0;
  let refsLoaded = false;
  let summaryMode = false;
  const cache = { warehouses: [], products: [], lots: [] };

  function syncFilterOptions() {
    const form = document.querySelector("#inventoryFilters");
    if (!form) return;
    const wh = form.elements.namedItem("maKho");
    const prod = form.elements.namedItem("maSanPham");
    const lot = form.elements.namedItem("maLo");
    if (wh) wh.innerHTML = selectOptions(cache.warehouses, "maKho", (w) => `${w.maKho} · ${w.tenKho}`, wh.value, "Tất cả kho", escapeHtml);
    if (prod) prod.innerHTML = selectOptions(cache.products, "maSanPham", (p) => `${p.maSanPham} · ${p.tenSanPham}`, prod.value, "Tất cả sản phẩm", escapeHtml);
    if (lot) lot.innerHTML = selectOptions(cache.lots, "maLo", (l) => `${l.maLo}${l.tenSanPham ? ` · ${l.tenSanPham}` : ""}`, lot.value, "Tất cả lô", escapeHtml);
  }

  async function loadRefs() {
    if (refsLoaded || !isAuthenticated()) return;
    refsLoaded = true;
    await Promise.all([
      masters?.warehouses?.all ? masters.warehouses.all().then((items) => { cache.warehouses = items; }).catch(() => {}) : Promise.resolve(),
      products?.all ? products.all().then((items) => { cache.products = items; }).catch(() => {}) : Promise.resolve(),
      inventory?.all ? inventory.all().then((items) => { cache.lots = items; }).catch(() => {}) : Promise.resolve()
    ]);
    syncFilterOptions();
  }

  function setMessage(message, error = false) {
    const node = document.querySelector("#inventoryMessage");
    node.textContent = message;
    node.hidden = !message;
    node.classList.toggle("text-danger", error);
  }

  function filters() {
    const form = document.querySelector("#inventoryFilters");
    return {
      maKho: form.elements.namedItem("maKho").value,
      maSanPham: form.elements.namedItem("maSanPham").value,
      maLo: form.elements.namedItem("maLo").value,
      hanSuDungTruoc: form.elements.namedItem("hanSuDungTruoc").value,
      chiKhaDung: form.elements.namedItem("chiKhaDung").checked
    };
  }

  function syncModeControls() {
    const toggle = document.querySelector("#toggleInventoryModeButton");
    const form = document.querySelector("#inventoryFilters");
    if (toggle) {
      toggle.textContent = summaryMode ? "Xem chi tiết theo lô" : "Tổng hợp theo SP";
    }
    if (form) {
      for (const name of ["maLo", "hanSuDungTruoc", "chiKhaDung"]) {
        const field = form.elements.namedItem(name)?.closest("label");
        if (field) field.hidden = summaryMode;
      }
    }
  }

  function showSummaryPage(result) {
    table.querySelector("thead").innerHTML =
      '<tr><th>Kho</th><th>Sản phẩm</th><th>Đơn vị tính</th><th class="number-cell">Tồn tại kho</th><th class="number-cell">Tổng tồn SP (toàn hệ thống)</th><th class="number-cell">Tổng giá trị tồn</th></tr>';
    table.querySelector("tbody").innerHTML = result.items.map((item) => `
      <tr>
        <td><span class="cell-primary">${escapeHtml(item.maKho)}</span><br>${escapeHtml(item.tenKho)}</td>
        <td><span class="cell-primary">${escapeHtml(item.maSanPham)}</span><br>${escapeHtml(item.tenSanPham)}</td>
        <td>${escapeHtml(item.maDonViTinh)}</td>
        <td class="number-cell"><strong>${escapeHtml(item.soLuongTon)} ${escapeHtml(item.maDonViTinh)}</strong></td>
        <td class="number-cell"><strong>${escapeHtml(item.tongTonToanHeThong ?? item.soLuongTon)} ${escapeHtml(item.maDonViTinh)}</strong></td>
        <td class="number-cell"><strong>${escapeHtml(item.giaTriTon)}</strong></td>
      </tr>`).join("");
    table.hidden = result.items.length === 0;
    document.querySelector("#inventoryEmpty").hidden = result.items.length !== 0;
    const pagination = document.querySelector("#inventoryPagination");
    pagination.hidden = result.totalElements === 0;
    document.querySelector("#inventoryRange").textContent =
      `Hiển thị ${result.page * result.size + 1}–${result.page * result.size + result.items.length} trong ${result.totalElements} dòng tổng hợp`;
    document.querySelector("#inventoryPrevious").disabled = result.page <= 0;
    document.querySelector("#inventoryNext").disabled = result.page + 1 >= result.totalPages;
  }

  function showPage(result) {
    if (!cache.lots.length && result.items?.length) {
      cache.lots = result.items;
      syncFilterOptions();
    }
    table.querySelector("thead").innerHTML =
      '<tr><th>Sản phẩm</th><th>Lô</th><th>Kho · vị trí</th><th>Hạn dùng</th><th class="number-cell">Số lượng</th><th class="number-cell">Giá trị tồn</th><th>Trạng thái</th><th>Phiếu nhập</th></tr>';
    table.querySelector("tbody").innerHTML = result.items.map((item) => `
      <tr><td><span class="cell-primary">${escapeHtml(item.maSanPham)}</span><br>${escapeHtml(item.tenSanPham)}</td>
      <td>${escapeHtml(item.maLo)}</td>
      <td>${escapeHtml(item.tenKho)} · ${escapeHtml(item.maViTri)}</td>
      <td>${escapeHtml(item.hanSuDung || "Không có")}</td>
      <td class="number-cell">${escapeHtml(item.soLuongTon)} ${escapeHtml(item.maDonViTinh)}</td>
      <td class="number-cell">${escapeHtml(item.giaTriTon)}</td>
      <td><span class="status ${item.khaDung ? "status-success" : "status-danger"}">${item.khaDung ? "Khả dụng" : "Không khả dụng"}</span></td>
      <td>${escapeHtml(item.maPhieuNhap)}</td></tr>`).join("");
    table.hidden = result.items.length === 0;
    document.querySelector("#inventoryEmpty").hidden = result.items.length !== 0;
    const pagination = document.querySelector("#inventoryPagination");
    pagination.hidden = result.totalElements === 0;
    document.querySelector("#inventoryRange").textContent =
      `Hiển thị ${result.page * result.size + 1}–${result.page * result.size + result.items.length} trong ${result.totalElements} dòng tồn`;
    document.querySelector("#inventoryPrevious").disabled = result.page <= 0;
    document.querySelector("#inventoryNext").disabled = result.page + 1 >= result.totalPages;
  }

  async function render(nextPage = page) {
    const current = ++requestId;
    page = nextPage;
    syncModeControls();
    if (!isAuthenticated()) {
      refresh.disabled = false;
      table.hidden = true;
      document.querySelector("#inventoryEmpty").hidden = true;
      document.querySelector("#inventoryPagination").hidden = true;
      setMessage("Đăng nhập để xem tồn kho.");
      return;
    }
    refresh.disabled = true;
    setMessage("Đang tải tồn kho...");
    loadRefs();
    try {
      const currentFilters = filters();
      if (summaryMode && inventory.summaryByProduct) {
        const result = await inventory.summaryByProduct({
          page, size: 20, maKho: currentFilters.maKho, maSanPham: currentFilters.maSanPham
        });
        if (current !== requestId) return;
        showSummaryPage(result);
      } else {
        const result = await inventory.list({ page, size: 20, ...currentFilters });
        if (current !== requestId) return;
        showPage(result);
      }
      setMessage("");
    } catch (error) {
      if (current !== requestId) return;
      table.hidden = true;
      document.querySelector("#inventoryEmpty").hidden = true;
      document.querySelector("#inventoryPagination").hidden = true;
      setMessage(error.message || "Không tải được tồn kho.", true);
      if (error.status === 401) requireLogin();
    } finally {
      if (current === requestId) refresh.disabled = false;
    }
  }

  function start() {
    view.querySelector(".inventory-summary").hidden = true;
    view.querySelector(".live-indicator").textContent = "Dữ liệu API";
    view.querySelector(".section-toolbar p").textContent = "Tồn theo lô và vị trí từ hệ thống; số khả dụng được kiểm tra lại khi ghi sổ.";
    refresh.insertAdjacentHTML("beforebegin",
      '<button class="button button-secondary" id="toggleInventoryModeButton" type="button">Tổng hợp theo SP</button>');
    toolbar.innerHTML = `<form id="inventoryFilters" class="filter-row">
      <label><span>Kho</span><select name="maKho"><option value="">Tất cả kho</option></select></label>
      <label><span>Sản phẩm</span><select name="maSanPham"><option value="">Tất cả sản phẩm</option></select></label>
      <label><span>Lô hàng</span><select name="maLo"><option value="">Tất cả lô</option></select></label>
      <label><span>Hạn đến ngày</span><input name="hanSuDungTruoc" type="date"></label>
      <label><span>Chỉ khả dụng</span><input name="chiKhaDung" type="checkbox"></label>
      <button class="button button-secondary" type="submit">Lọc tồn kho</button>
    </form>`;
    table.querySelector("thead").innerHTML = "<tr><th>Sản phẩm</th><th>Lô</th><th>Kho · vị trí</th><th>Hạn dùng</th><th class=\"number-cell\">Số lượng</th><th class=\"number-cell\">Giá trị tồn</th><th>Trạng thái</th><th>Phiếu nhập</th></tr>";
    table.insertAdjacentHTML("beforebegin", '<p class="list-message" id="inventoryMessage" role="status" aria-live="polite" hidden></p>');
    table.closest(".table-wrap").insertAdjacentHTML("afterend", `<div class="empty-state" id="inventoryEmpty" hidden><h3>Không có tồn phù hợp</h3><p>Thử thay đổi bộ lọc.</p></div>
      <footer class="pagination" id="inventoryPagination" hidden><span id="inventoryRange"></span><div><button id="inventoryPrevious" type="button" aria-label="Trang trước">‹</button><button id="inventoryNext" type="button" aria-label="Trang sau">›</button></div></footer>`);
    document.querySelector("#toggleInventoryModeButton").addEventListener("click", () => {
      summaryMode = !summaryMode;
      view.querySelector(".section-toolbar p").textContent = summaryMode
        ? "Tổng hợp tồn theo từng cặp (Kho, Sản phẩm) từ vw_TonKhoTheoSanPham và tổng tồn toàn hệ thống từ fn_TonTheoSanPham."
        : "Tồn theo lô và vị trí từ hệ thống; số khả dụng được kiểm tra lại khi ghi sổ.";
      render(0);
    });
    document.querySelector("#inventoryFilters").addEventListener("submit", (event) => {
      event.preventDefault();
      if (event.currentTarget.reportValidity()) render(0);
    });
    document.querySelector("#inventoryFilters").addEventListener("change", () => render(0));
    document.querySelector("#inventoryPrevious").addEventListener("click", () => render(page - 1));
    document.querySelector("#inventoryNext").addEventListener("click", () => render(page + 1));
    refresh.addEventListener("click", () => render(page));
  }

  return { start, render };
}
