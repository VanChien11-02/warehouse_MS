export function createLiveInventory({ inventory, escapeHtml, isAuthenticated, requireLogin }) {
  const view = document.querySelector("#inventoryView");
  const table = document.querySelector("#inventoryTable");
  const toolbar = view.querySelector(".data-toolbar");
  const refresh = document.querySelector("#refreshInventoryButton");
  let page = 0;
  let requestId = 0;

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

  function showPage(result) {
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
    try {
      const result = await inventory.list({ page, size: 20, ...filters() });
      if (current !== requestId) return;
      showPage(result);
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
    toolbar.innerHTML = `<form id="inventoryFilters" class="filter-row">
      <label><span>Mã kho</span><input name="maKho" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label>
      <label><span>Mã sản phẩm</span><input name="maSanPham" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label>
      <label><span>Mã lô</span><input name="maLo" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label>
      <label><span>Hạn đến ngày</span><input name="hanSuDungTruoc" type="date"></label>
      <label><span>Chỉ khả dụng</span><input name="chiKhaDung" type="checkbox"></label>
      <button class="button button-secondary" type="submit">Lọc tồn kho</button>
    </form>`;
    table.querySelector("thead").innerHTML = "<tr><th>Sản phẩm</th><th>Lô</th><th>Kho · vị trí</th><th>Hạn dùng</th><th class=\"number-cell\">Số lượng</th><th class=\"number-cell\">Giá trị tồn</th><th>Trạng thái</th><th>Phiếu nhập</th></tr>";
    table.insertAdjacentHTML("beforebegin", '<p class="list-message" id="inventoryMessage" role="status" aria-live="polite" hidden></p>');
    table.closest(".table-wrap").insertAdjacentHTML("afterend", `<div class="empty-state" id="inventoryEmpty" hidden><h3>Không có tồn phù hợp</h3><p>Thử thay đổi bộ lọc.</p></div>
      <footer class="pagination" id="inventoryPagination" hidden><span id="inventoryRange"></span><div><button id="inventoryPrevious" type="button" aria-label="Trang trước">‹</button><button id="inventoryNext" type="button" aria-label="Trang sau">›</button></div></footer>`);
    document.querySelector("#inventoryFilters").addEventListener("submit", (event) => {
      event.preventDefault();
      if (event.currentTarget.reportValidity()) render(0);
    });
    document.querySelector("#inventoryPrevious").addEventListener("click", () => render(page - 1));
    document.querySelector("#inventoryNext").addEventListener("click", () => render(page + 1));
    refresh.addEventListener("click", () => render(page));
  }

  return { start, render };
}
