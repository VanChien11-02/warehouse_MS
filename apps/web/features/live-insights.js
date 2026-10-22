const screens = {
  expiry: { title: "Lô sắp hết hạn", columns: [["maKho", "Kho"], ["maViTri", "Vị trí"], ["maLo", "Lô"], ["tenSanPham", "Sản phẩm"], ["soLuongTon", "Tồn"], ["hanSuDung", "Hạn sử dụng"], ["soNgayConLai", "Số ngày còn lại"]] },
  discrepancies: { title: "Chênh lệch kiểm kê", columns: [["maPhieuKiemKe", "Phiếu"], ["maKho", "Kho"], ["maViTri", "Vị trí"], ["maLo", "Lô"], ["tenSanPham", "Sản phẩm"], ["soLuongHeThong", "Hệ thống"], ["soLuongThucTe", "Thực tế"], ["chenhLech", "Chênh lệch"], ["lyDoChenhLech", "Lý do"]] },
  audit: { title: "Nhật ký thao tác", columns: [["maTaiKhoan", "Tài khoản"], ["thoiGian", "Thời gian"], ["hanhDong", "Hành động"], ["tenBang", "Đối tượng"], ["maBanGhi", "Mã bản ghi"], ["duLieuCu", "Trước"], ["duLieuMoi", "Sau"]] }
};
export function createLiveInsights({ insights, getRole, requireLogin, escapeHtml: esc, navigate, pagesForRole }) {
  const view = document.createElement("section");
  view.id = "liveInsightView"; view.className = "view"; view.hidden = true;
  let mode = "dashboard", page = 0, generation = 0;
  const el = (selector) => view.querySelector(selector);
  function start() {
    document.querySelector("#mainContent").append(view);
    view.addEventListener("submit", (event) => { event.preventDefault(); if (event.target.reportValidity()) load(0); });
    view.addEventListener("click", (event) => {
      const button = event.target.closest("button"); if (!button) return;
      if (button.dataset.target) navigate(button.dataset.target);
      if (button.hasAttribute("data-prev")) load(page - 1);
      if (button.hasAttribute("data-next")) load(page + 1);
      if (button.hasAttribute("data-refresh")) load(0);
    });
  }
  async function load(nextPage = page) {
    const ticket = ++generation; page = nextPage;
    if (mode === "dashboard") {
      el("[data-message]").textContent = "Đang tải số liệu từ API...";
      el("[data-metrics]").setAttribute("aria-busy", "true");
    } else {
      el("tbody").replaceChildren(); el("[data-message]").textContent = "Đang tải dữ liệu...";
      for (const button of view.querySelectorAll("[data-prev], [data-next]")) button.disabled = true;
    }
    try {
      if (mode === "dashboard") {
        const result = await insights.overview(getRole());
        if (ticket !== generation) return;
        const pages = pagesForRole(getRole());
        el("[data-metrics]").innerHTML = result.filter((r) => pages.includes(r.target)).map((r) => `<button class="live-metric" type="button" data-target="${esc(r.target)}">
          <span class="live-metric-label">${esc(r.label)}</span><strong>${r.error ? "—" : esc(r.total)}</strong>
          <span class="live-metric-foot">${r.error ? esc(r.error) : "Mở danh sách"}<svg aria-hidden="true"><use href="#icon-chevron"/></svg></span></button>`).join("");
        const volume = el("[data-volume]");
        if (volume) {
          const documents = result.filter((r) => ["inbound", "outbound", "transfer", "count", "return"].includes(r.target));
          const maximum = Math.max(1, ...documents.map((r) => Number(r.total) || 0));
          volume.innerHTML = documents.map((r) => {
            const count = Number(r.total) || 0;
            const width = Math.min(100, Math.round(count / maximum * 100));
            return `<div class="live-volume-row"><div class="live-volume-label"><span>${esc(r.label)}</span><strong>${r.error ? "—" : esc(count)}</strong></div>
              <div class="live-volume-track" role="img" aria-label="${esc(r.label)}: ${r.error ? "không tải được" : `${count} phiếu`}"><span style="width:${width}%"></span></div></div>`;
          }).join("");
        }
        el("[data-metrics]").setAttribute("aria-busy", "false");
        el("[data-updated]").textContent = `Cập nhật ${new Intl.DateTimeFormat("vi-VN", { hour: "2-digit", minute: "2-digit" }).format(new Date())}`;
      } else {
        const filters = Object.fromEntries([...view.querySelectorAll("input")].filter((i) => i.value).map((i) => [i.name, i.value]));
        const result = await insights.query(mode, filters, page);
        if (ticket !== generation) return;
        el("tbody").innerHTML = result.items.map((r) => `<tr>${screens[mode].columns.map(([key]) => `<td>${esc(r[key] ?? "—")}</td>`).join("")}</tr>`).join("");
        el("[data-range]").textContent = `${result.totalElements} bản ghi · trang ${page + 1}/${Math.max(1, result.totalPages)}`;
        el("[data-prev]").disabled = page === 0; el("[data-next]").disabled = page + 1 >= result.totalPages;
        if (!result.items.length) { el("[data-message]").textContent = "Không có dữ liệu phù hợp."; return; }
      }
      el("[data-message]").textContent = "";
    } catch (error) { if (ticket === generation) { el("[data-message]").textContent = error.message; if (mode === "dashboard") el("[data-metrics]").setAttribute("aria-busy", "false"); if (error.status === 401) requireLogin(); } }
  }
  function show(nextMode) {
    generation++; mode = nextMode;
    const date = new Date();
    const local = (d) => new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
    const today = local(date); date.setDate(date.getDate() - 30);
    if (mode === "dashboard") {
      const role = getRole();
      const config = {
        ADMIN: { title: "Quản trị hệ thống", intro: "Quản lý nhân viên, tài khoản đăng nhập và quyền truy cập.", links: [["employees", "Quản lý nhân viên", "Cập nhật hồ sơ và trạng thái làm việc"], ["accounts", "Quản lý tài khoản", "Tạo tài khoản, khóa truy cập và gán vai trò"], ["permissions", "Xem quyền hạn", "Đối chiếu quyền của bốn vai trò"]] },
        QLKHO: { title: "Nhịp kho hiện tại", intro: "Theo dõi tồn và các chứng từ đang chờ xử lý.", links: [["inbound", "Phiếu nhập", "Xem và duyệt phiếu nhập"], ["outbound", "Phiếu xuất", "Xem và duyệt phiếu xuất"], ["reports", "Báo cáo tồn kho", "Đối chiếu nhập, xuất và tồn theo kỳ"]] },
        NVKHO: { title: "Công việc trong ca", intro: "Tra cứu tồn và tiếp tục các phiếu nhập, xuất đang lập.", links: [["inventory", "Tra cứu tồn kho", "Xem số lượng theo lô và vị trí"], ["inbound", "Lập phiếu nhập", "Tiếp nhận hàng vào kho"], ["outbound", "Lập phiếu xuất", "Chọn lô theo gợi ý FEFO"]] },
        KETOAN: { title: "Đối soát giá trị", intro: "Kiểm tra giá trị phiếu nhập, xuất đã hoàn tất và theo dõi báo cáo.", links: [["inbound", "Đối soát phiếu nhập", "Mở phiếu đã hoàn tất và xác nhận giá trị"], ["outbound", "Đối soát phiếu xuất", "Ghi nhận sai lệch nếu có"], ["reports", "Báo cáo nhập – xuất – tồn", "Xem biến động và giá trị theo kỳ"]] }
      }[role] || { title: "Tổng quan", intro: "Chọn chức năng được cấp quyền.", links: [] };
      const links = config.links.filter(([target]) => pagesForRole(role).includes(target));
      view.innerHTML = `<div class="live-dashboard-head"><div><h2>${esc(config.title)}</h2><p>${esc(config.intro)}</p></div><button class="button button-secondary" type="button" data-refresh>Làm mới</button></div>
        <div class="live-dashboard-meta"><span>Dữ liệu trực tiếp từ API</span><span data-updated></span></div>
        <p data-message role="status" aria-live="polite"></p><div class="live-metrics" data-metrics aria-busy="true"></div>
        <div class="live-dashboard-lower">${role === "ADMIN" ? "" : `<section class="live-dashboard-volume" aria-label="Khối lượng chứng từ"><h3>Khối lượng chứng từ</h3><p>${role === "KETOAN" ? "Tất cả trạng thái trong phạm vi đối soát." : "Phiếu nháp cần tiếp tục xử lý."}</p><div data-volume></div></section>`}
          <section class="live-dashboard-tasks" aria-label="Truy cập nhanh"><div><h3>Công việc của bạn</h3><p>Chọn một chức năng để tiếp tục.</p></div>
            <div class="live-task-list">${links.map(([target, title, detail]) => `<button type="button" data-target="${esc(target)}"><span><strong>${esc(title)}</strong><small>${esc(detail)}</small></span><svg aria-hidden="true"><use href="#icon-chevron"/></svg></button>`).join("")}</div></section></div>`;
      load(0);
      return;
    }
    const columns = screens[mode].columns;
    view.innerHTML = `<div class="section-toolbar"><h2>${esc(screens[mode].title)}</h2><button class="button button-secondary" data-refresh>Làm mới</button></div>
      <form class="live-filters">${mode === "expiry" ? '<label class="field"><span>Số ngày</span><input name="soNgay" type="number" min="0" max="3650" step="1" value="30" required></label>'
        : `<label class="field"><span>Từ ngày</span><input name="tuNgay" type="date" value="${local(date)}" required></label><label class="field"><span>Đến ngày</span><input name="denNgay" type="date" value="${today}" required></label>`}
        <label class="field"><span>${mode === "audit" ? "Mã tài khoản" : "Mã kho"}</span><input name="${mode === "audit" ? "maTaiKhoan" : "maKho"}" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label>
        ${mode === "discrepancies" ? '<label class="field"><span>Mã vị trí</span><input name="maViTri" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label>' : ""}
        <button class="button button-primary" type="submit">Xem kết quả</button></form>
      <p data-message role="status" aria-live="polite"></p><div class="table-wrap"><table><thead><tr>${columns.map(([, label]) => `<th>${esc(label)}</th>`).join("")}</tr></thead><tbody></tbody></table></div>
      <footer class="pagination"><span data-range></span><div><button data-prev aria-label="Trang trước">&lt;</button><button data-next aria-label="Trang sau">&gt;</button></div></footer>`;
    load(0);
  }
  function clear() { generation++; view.replaceChildren(); }
  return { start, show, clear, viewId: view.id };
}
