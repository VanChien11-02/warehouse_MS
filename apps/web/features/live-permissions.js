export function createLivePermissions({ identity, getRole, requireLogin, escapeHtml: esc, navigate }) {
  const view = document.createElement("section");
  view.id = "livePermissionsView";
  view.className = "view";
  view.hidden = true;
  let generation = 0;
  function start() {
    view.innerHTML = `<div class="section-toolbar"><h2>Quyền hạn theo vai trò</h2><div class="toolbar-actions">
      <button class="button button-secondary" data-refresh>Làm mới</button><button class="button button-primary" data-accounts>Gán vai trò tài khoản</button></div></div>
      <label class="field"><span>Vai trò</span><select data-role></select></label><p data-message role="status" aria-live="polite"></p>
      <div class="table-wrap"><table><thead><tr><th>Chức năng</th><th>Xem</th><th>Tạo</th><th>Sửa</th><th>Xóa / hủy</th><th>Hoàn tất</th></tr></thead><tbody></tbody></table></div>`;
    document.querySelector("#mainContent").append(view);
    view.querySelector("[data-refresh]").addEventListener("click", show);
    view.querySelector("[data-accounts]").addEventListener("click", () => navigate("accounts"));
  }
  async function show() {
    const ticket = ++generation;
    if (getRole() !== "ADMIN") return clear();
    const select = view.querySelector("select"), body = view.querySelector("tbody"), message = view.querySelector("[data-message]");
    body.replaceChildren(); select.replaceChildren(); message.textContent = "Đang tải quyền hạn...";
    try {
      const roles = await identity.permissions();
      if (ticket !== generation) return;
      select.innerHTML = roles.map((r) => `<option value="${esc(r.role)}">${esc(r.tenVaiTro)} (${esc(r.role)})</option>`).join("");
      const render = () => {
        const role = roles.find((r) => r.role === select.value);
        body.innerHTML = (role?.permissions || []).map((p) => `<tr><td>${esc(p.tenChucNang)}</td>${["xem", "tao", "sua", "xoaHoacHuy", "hoanTat"].map((key) => `<td>${p[key] ? "Có" : "Không"}</td>`).join("")}</tr>`).join("");
      };
      select.onchange = render; render(); message.textContent = "";
    } catch (error) { if (ticket === generation) { message.textContent = error.message; if (error.status === 401) requireLogin(); } }
  }
  function clear() { generation++; view.querySelector("tbody").replaceChildren(); view.querySelector("select").replaceChildren(); }
  return { start, show, clear, viewId: view.id };
}
