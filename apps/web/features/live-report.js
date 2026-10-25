import { selectOptions } from "../data/master-api.js?v=session-shell-4";

export function createLiveReport({ reports, masters, products, escapeHtml, isAuthenticated, requireLogin }) {
  const view = document.querySelector("#reportsView");
  const table = view.querySelector("table");
  const button = document.querySelector("#runReportButton");
  let page = 0;
  let requestId = 0;
  let refsLoaded = false;
  const cache = { warehouses: [], products: [] };

  function syncFilterOptions() {
    const wh = document.querySelector("#reportWarehouse");
    const prod = document.querySelector("#reportProduct");
    if (wh) wh.innerHTML = selectOptions(cache.warehouses, "maKho", (w) => `${w.maKho} · ${w.tenKho}`, wh.value, "Tất cả kho", escapeHtml);
    if (prod) prod.innerHTML = selectOptions(cache.products, "maSanPham", (p) => `${p.maSanPham} · ${p.tenSanPham}`, prod.value, "Tất cả sản phẩm", escapeHtml);
  }

  async function loadRefs() {
    if (refsLoaded || !isAuthenticated()) return;
    refsLoaded = true;
    await Promise.all([
      masters?.warehouses?.all ? masters.warehouses.all().then((items) => { cache.warehouses = items; }).catch(() => {}) : Promise.resolve(),
      products?.all ? products.all().then((items) => { cache.products = items; }).catch(() => {}) : Promise.resolve()
    ]);
    syncFilterOptions();
  }

  function setMessage(message, error = false) {
    const node = document.querySelector("#reportMessage");
    node.textContent = message;
    node.hidden = !message;
    node.classList.toggle("text-danger", error);
  }

  function filters() {
    return {
      from: document.querySelector("#reportFrom").value,
      to: document.querySelector("#reportTo").value,
      warehouse: document.querySelector("#reportWarehouse").value,
      product: document.querySelector("#reportProduct").value
    };
  }

  function showPage(result) {
    document.querySelector("#reportRows").innerHTML = result.items.map((item) => `
      <tr><td>${escapeHtml(item.maKho)}</td>
      <td><span class="cell-primary">${escapeHtml(item.maSanPham)}</span><br>${escapeHtml(item.tenSanPham)}</td>
      <td class="number-cell">${escapeHtml(item.soLuongDauKy)}</td>
      <td class="number-cell">${escapeHtml(item.soLuongNhap)}</td>
      <td class="number-cell">${escapeHtml(item.soLuongXuat)}</td>
      <td class="number-cell">${escapeHtml(item.soLuongDieuChinh)}</td>
      <td class="number-cell"><strong>${escapeHtml(item.soLuongCuoiKy)}</strong> ${escapeHtml(item.maDonViTinh)}</td>
      <td class="number-cell">${escapeHtml(item.giaTriCuoiKy)} ₫</td></tr>`).join("");
    table.hidden = result.items.length === 0;
    document.querySelector("#reportEmpty").hidden = result.items.length !== 0;
    document.querySelector("#reportPagination").hidden = result.totalElements === 0;
    if (result.totalElements > 0) {
      document.querySelector("#reportRange").textContent =
        `Hiển thị ${result.page * result.size + 1}–${result.page * result.size + result.items.length} trong ${result.totalElements} dòng`;
      document.querySelector("#reportPrevious").disabled = result.page <= 0;
      document.querySelector("#reportNext").disabled = result.page + 1 >= result.totalPages;
    }
  }

  async function render(nextPage = page) {
    const current = ++requestId;
    page = nextPage;
    if (!isAuthenticated()) {
      button.disabled = false;
      table.hidden = true;
      document.querySelector("#reportEmpty").hidden = true;
      document.querySelector("#reportPagination").hidden = true;
      setMessage("Đăng nhập để xem báo cáo.");
      return;
    }
    const query = filters();
    if (!query.from || !query.to || query.from > query.to) {
      button.disabled = false;
      table.hidden = true;
      document.querySelector("#reportEmpty").hidden = true;
      document.querySelector("#reportPagination").hidden = true;
      setMessage("Chọn khoảng ngày hợp lệ.", true);
      return;
    }
    button.disabled = true;
    setMessage("Đang tổng hợp báo cáo...");
    loadRefs();
    try {
      const result = await reports.movements({ ...query, page, size: 20 });
      if (current !== requestId) return;
      showPage(result);
      setMessage("");
    } catch (error) {
      if (current !== requestId) return;
      table.hidden = true;
      document.querySelector("#reportEmpty").hidden = true;
      document.querySelector("#reportPagination").hidden = true;
      setMessage(error.message || "Không tải được báo cáo.", true);
      if (error.status === 401) requireLogin();
    } finally {
      if (current === requestId) button.disabled = false;
    }
  }

  function start() {
    const from = document.querySelector("#reportFrom").value;
    const to = document.querySelector("#reportTo").value;
    view.querySelector(".report-kpis").hidden = true;
    view.querySelector(".report-filters").innerHTML = `
      <label class="field"><span>Từ ngày</span><input id="reportFrom" type="date" required></label>
      <label class="field"><span>Đến ngày</span><input id="reportTo" type="date" required></label>
      <label class="field"><span>Kho</span><select id="reportWarehouse"><option value="">Tất cả kho</option></select></label>
      <label class="field"><span>Sản phẩm</span><select id="reportProduct"><option value="">Tất cả sản phẩm</option></select></label>`;
    document.querySelector("#reportFrom").value = from;
    document.querySelector("#reportTo").value = to;
    table.querySelector("thead").innerHTML = "<tr><th>Kho</th><th>Sản phẩm</th><th class=\"number-cell\">Tồn đầu</th><th class=\"number-cell\">Nhập</th><th class=\"number-cell\">Xuất</th><th class=\"number-cell\">Điều chỉnh</th><th class=\"number-cell\">Tồn cuối</th><th class=\"number-cell\">Giá trị cuối</th></tr>";
    table.closest(".table-wrap").insertAdjacentHTML("beforebegin", '<p class="list-message" id="reportMessage" role="status" aria-live="polite" hidden></p>');
    table.closest(".table-wrap").insertAdjacentHTML("afterend", `<div class="empty-state" id="reportEmpty" hidden><h3>Không có biến động trong kỳ</h3><p>Thử chọn khoảng ngày hoặc mã lọc khác.</p></div>
      <footer class="pagination" id="reportPagination" hidden><span id="reportRange"></span><div><button id="reportPrevious" type="button" aria-label="Trang trước">‹</button><button id="reportNext" type="button" aria-label="Trang sau">›</button></div></footer>`);
    button.addEventListener("click", () => {
      if (view.querySelector(".report-filters").querySelectorAll("input:invalid, select:invalid").length === 0) render(0);
      else view.querySelector("input:invalid, select:invalid").reportValidity();
    });
    document.querySelector("#reportWarehouse").addEventListener("change", () => render(0));
    document.querySelector("#reportProduct").addEventListener("change", () => render(0));
    document.querySelector("#reportPrevious").addEventListener("click", () => render(page - 1));
    document.querySelector("#reportNext").addEventListener("click", () => render(page + 1));
  }

  return { start, render };
}
