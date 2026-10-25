export function createLiveInboundHistory({ api, escapeHtml: esc, requireLogin, onOpen }) {
  let root, ticket = 0, page = 0, active = false, filters = {};
  const el = (id) => root.querySelector(`#${id}`);
  const money = new Intl.NumberFormat("vi-VN", { maximumFractionDigits: 4 });
  const date = (value) => value ? value.split("-").reverse().join("/") : "Không có";
  const time = (value) => value ? new Date(value).toLocaleString("vi-VN") : "—";

  async function load(nextPage = 0) {
    const currentTicket = ++ticket;
    page = nextPage;
    const message = el("inboundHistoryMessage");
    message.textContent = "Đang tải lịch sử nhập kho...";
    message.classList.remove("text-danger");
    root.setAttribute("aria-busy", "true");
    el("inboundHistoryTable").hidden = true;
    el("inboundHistoryRows").replaceChildren();
    el("inboundHistoryPagination").hidden = true;
    el("inboundHistoryRefresh").disabled = true;
    try {
      const result = await api.history({ ...filters, page, size: 20 });
      if (currentTicket !== ticket || !active) return;
      message.textContent = result.items.length ? "" : "Chưa có lô nhập phù hợp. Thử đổi bộ lọc hoặc kiểm tra trạng thái phiếu nhập.";
      el("inboundHistoryRows").innerHTML = result.items.map((item) => `<tr>
        <td><button class="text-button" type="button" data-receipt="${esc(item.maPhieuNhap)}" aria-label="Mở phiếu ${esc(item.maPhieuNhap)}">${esc(item.maPhieuNhap)}</button><small>${esc(time(item.ngayHoanTat))}</small></td>
        <td>${esc(item.maNhaCungCap)}</td>
        <td><strong>${esc(item.maSanPham)}</strong><small>${esc(item.tenSanPham)}</small></td>
        <td>${esc(item.maLo)}</td>
        <td class="number-cell">${esc(money.format(item.soLuongNhap))}<small>${esc(item.maDonViTinh)}</small></td>
        <td class="number-cell">${esc(money.format(item.donGiaNhap))}</td>
        <td class="number-cell">${esc(money.format(item.giaTriNhap))}</td>
        <td><small>NSX: ${esc(date(item.ngaySanXuat))}</small><small>HSD: ${esc(date(item.hanSuDung))}</small></td>
      </tr>`).join("");
      el("inboundHistoryTable").hidden = result.items.length === 0;
      el("inboundHistoryPagination").hidden = result.totalElements === 0;
      el("inboundHistoryRange").textContent = `${result.totalElements} lô · Trang ${result.page + 1}/${result.totalPages}`;
      el("inboundHistoryPrevious").disabled = result.page === 0;
      el("inboundHistoryNext").disabled = result.page + 1 >= result.totalPages;
    } catch (error) {
      if (currentTicket !== ticket || !active) return;
      message.textContent = `${error.message || "Không tải được lịch sử nhập kho."} Hãy kiểm tra bộ lọc và bấm Làm mới.`;
      message.classList.add("text-danger");
      if (error.status === 401) requireLogin();
    } finally {
      if (currentTicket === ticket) {
        root.setAttribute("aria-busy", "false");
        el("inboundHistoryRefresh").disabled = false;
      }
    }
  }

  function start(container) {
    root = container;
    root.classList.add("inbound-history");
    root.innerHTML = `<div class="section-toolbar"><div><h3>Lịch sử nhập kho</h3><p>Phiếu đã hoàn tất · Mỗi dòng là một lô nhập.</p></div><button class="button button-secondary" id="inboundHistoryRefresh" type="button">Làm mới</button></div>
      <form id="inboundHistoryFilters" class="inbound-history-filters">
      ${[["maPhieuNhap", "Mã phiếu"], ["maSanPham", "Mã sản phẩm"], ["maNhaCungCap", "Mã nhà cung cấp"]].map(([name, label]) => `<label class="field"><span>${label}</span><input name="${name}" maxlength="6" pattern="[A-Za-z0-9]{1,6}" placeholder="Tất cả" autocomplete="off"></label>`).join("")}
      <label class="field"><span>Từ ngày (UTC)</span><input type="date" name="tuNgay"></label>
      <label class="field"><span>Đến ngày (UTC)</span><input type="date" name="denNgay"></label>
      <div class="toolbar-actions"><button class="button button-primary" type="submit">Tra cứu</button><button class="button button-quiet" id="inboundHistoryReset" type="button">Xóa bộ lọc</button></div></form>
      <p id="inboundHistoryMessage" role="status" aria-live="polite"></p>
      <p class="inbound-history-scroll-hint">Vuốt ngang bảng để xem đủ thông tin.</p>
      <div class="table-wrap" id="inboundHistoryTable" role="region" aria-label="Các lô nhập đã hoàn tất" tabindex="0" hidden><table><thead><tr>
      <th scope="col">Phiếu / Ngày hoàn tất</th><th scope="col">Nhà cung cấp</th><th scope="col">Sản phẩm</th><th scope="col">Lô hàng</th>
      <th scope="col" class="number-cell">Số lượng</th><th scope="col" class="number-cell">Đơn giá (₫)</th><th scope="col" class="number-cell">Giá trị nhập (₫)</th><th scope="col">Ngày lô</th>
      </tr></thead><tbody id="inboundHistoryRows"></tbody></table></div>
      <footer class="pagination" id="inboundHistoryPagination" hidden><span id="inboundHistoryRange"></span><div><button id="inboundHistoryPrevious" type="button" aria-label="Trang lịch sử trước">&lt;</button><button id="inboundHistoryNext" type="button" aria-label="Trang lịch sử sau">&gt;</button></div></footer>`;
    function search() {
      const form = el("inboundHistoryFilters");
      if (!form.reportValidity()) return;
      const next = Object.fromEntries(new FormData(form));
      if (next.tuNgay && next.denNgay && next.tuNgay > next.denNgay) {
        ticket++;
        root.setAttribute("aria-busy", "false");
        el("inboundHistoryRefresh").disabled = false;
        el("inboundHistoryTable").hidden = el("inboundHistoryPagination").hidden = true;
        el("inboundHistoryMessage").textContent = "Từ ngày không được sau đến ngày. Hãy chọn lại khoảng ngày.";
        el("inboundHistoryMessage").classList.add("text-danger");
        return;
      }
      filters = Object.fromEntries(Object.entries(next).map(([key, value]) => [key, value.trim()]));
      load(0);
    }
    el("inboundHistoryFilters").addEventListener("submit", (event) => { event.preventDefault(); search(); });
    el("inboundHistoryRefresh").addEventListener("click", search);
    el("inboundHistoryReset").addEventListener("click", () => { el("inboundHistoryFilters").reset(); search(); });
    el("inboundHistoryPrevious").addEventListener("click", () => load(Math.max(0, page - 1)));
    el("inboundHistoryNext").addEventListener("click", () => load(page + 1));
    el("inboundHistoryRows").addEventListener("click", (event) => {
      const button = event.target.closest("[data-receipt]");
      if (button) onOpen(button.dataset.receipt);
    });
  }
  function show(visible) {
    active = visible;
    if (visible) load(0);
    else { ticket++; root.setAttribute("aria-busy", "false"); el("inboundHistoryRefresh").disabled = false; }
  }
  function clear() {
    show(false); filters = {}; el("inboundHistoryFilters").reset();
    el("inboundHistoryRows").replaceChildren();
  }
  return { start, show, clear };
}
