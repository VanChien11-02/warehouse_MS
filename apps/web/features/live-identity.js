export function createLiveIdentity({ identity, escapeHtml, getRole, requireLogin, showToast }) {
  const view = document.createElement("section");
  view.className = "view";
  view.id = "liveIdentityView";
  view.hidden = true;
  const dialog = document.createElement("dialog");
  dialog.className = "identity-dialog";
  let mode = "employees";
  let page = 0;
  let editingCode = null;
  let requestId = 0;

  function field(name) {
    return dialog.querySelector(`[name="${name}"]`);
  }

  function isAdmin() {
    return getRole() === "ADMIN";
  }

  function message(value, error = false) {
    const node = view.querySelector("#identityMessage");
    node.textContent = value;
    node.hidden = !value;
    node.classList.toggle("text-danger", error);
  }

  function formError(value) {
    const node = dialog.querySelector("#identityFormError");
    node.textContent = value;
    node.hidden = !value;
  }

  function formFields() {
    if (mode === "employees") {
      return `<label class="field identity-create-only"><span>Mã nhân viên *</span><input name="maNhanVien" maxlength="6" pattern="[A-Za-z0-9]{1,6}" required></label>
        <label class="field"><span>Họ tên *</span><input name="tenNhanVien" maxlength="255" required></label>
        <label class="field"><span>Điện thoại</span><input name="soDienThoai" maxlength="20"></label>
        <label class="field"><span>Giới tính</span><select name="gioiTinh"><option value="">Không chọn</option><option>Nam</option><option>Nữ</option><option>Khác</option></select></label>
        <label class="field"><span>Ngày sinh</span><input name="ngaySinh" type="date"></label>
        <label class="field"><span>Ngày vào làm *</span><input name="ngayVaoLam" type="date" required></label>
        <label class="field"><span>Lương</span><input name="luong" type="number" min="0" step="0.0001"></label>
        <label class="field"><span>Trạng thái</span><select name="dangLamViec"><option value="true">Đang làm việc</option><option value="false">Ngừng làm việc</option></select></label>
        <label class="field field-wide"><span>Địa chỉ</span><input name="diaChi" maxlength="500"></label>`;
    }
    return `<label class="field identity-create-only"><span>Mã tài khoản *</span><input name="maTaiKhoan" maxlength="6" pattern="[A-Za-z0-9]{1,6}" required></label>
      <label class="field identity-create-only"><span>Mã nhân viên *</span><input name="maNhanVien" maxlength="6" pattern="[A-Za-z0-9]{1,6}" required></label>
      <label class="field"><span>Tên đăng nhập *</span><input name="tenTaiKhoan" maxlength="100" autocomplete="off" required></label>
      <label class="field"><span>Vai trò *</span><select name="role" required><option value="ADMIN">Quản trị viên</option><option value="QLKHO">Quản lý kho</option><option value="NVKHO">Nhân viên kho</option><option value="KETOAN">Kế toán</option></select></label>
      <label class="field identity-create-only"><span>Mật khẩu ban đầu *</span><input name="matKhau" type="password" minlength="12" maxlength="72" autocomplete="new-password" required></label>
      <label class="field"><span>Trạng thái</span><select name="trangThai"><option value="true">Đang hoạt động</option><option value="false">Đã khóa</option></select></label>`;
  }

  function openEditor(item = null) {
    if (!isAdmin()) return;
    editingCode = item ? (mode === "employees" ? item.maNhanVien : item.maTaiKhoan) : null;
    dialog.querySelector("#identityDialogTitle").textContent = `${item ? "Sửa" : "Thêm"} ${mode === "employees" ? "nhân viên" : "tài khoản"}`;
    const form = dialog.querySelector("#identityForm");
    form.reset();
    dialog.querySelector("#identityFields").innerHTML = formFields();
    formError("");
    for (const label of dialog.querySelectorAll(".identity-create-only")) {
      label.hidden = !!item;
      const input = label.querySelector("input");
      if (input) input.required = !item;
    }
    dialog.querySelector("#identityResetSection").hidden = mode !== "accounts" || !item;
    dialog.querySelector("#identityResetPassword").value = "";
    dialog.querySelector("#identityResetPassword").required = false;
    if (item && mode === "employees") {
      for (const key of ["tenNhanVien", "soDienThoai", "gioiTinh", "ngaySinh", "diaChi", "luong", "ngayVaoLam"]) {
        field(key).value = item[key] ?? "";
      }
      field("dangLamViec").value = String(item.dangLamViec);
    } else if (item) {
      field("tenTaiKhoan").value = item.tenTaiKhoan;
      field("role").value = item.role;
      field("trangThai").value = String(item.trangThai);
    } else if (mode === "employees") {
      const today = new Date();
      field("ngayVaoLam").value = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
    }
    dialog.showModal();
    dialog.querySelector("label:not([hidden]) input")?.focus();
  }

  function employeeBody() {
    return {
      tenNhanVien: field("tenNhanVien").value.trim(),
      soDienThoai: field("soDienThoai").value.trim() || null,
      gioiTinh: field("gioiTinh").value || null,
      ngaySinh: field("ngaySinh").value || null,
      diaChi: field("diaChi").value.trim() || null,
      luong: field("luong").value === "" ? null : Number(field("luong").value),
      ngayVaoLam: field("ngayVaoLam").value,
      ...(editingCode ? { dangLamViec: field("dangLamViec").value === "true" } : {})
    };
  }

  function accountBody() {
    return {
      tenTaiKhoan: field("tenTaiKhoan").value.trim(),
      role: field("role").value,
      ...(editingCode ? { trangThai: field("trangThai").value === "true" } : {
        maTaiKhoan: field("maTaiKhoan").value.trim(),
        maNhanVien: field("maNhanVien").value.trim(),
        matKhau: field("matKhau").value
      })
    };
  }

  async function load(nextPage = page) {
    const current = ++requestId;
    page = nextPage;
    if (!isAdmin()) return;
    message("Đang tải dữ liệu...");
    try {
      const result = await identity[mode].list(page, 20);
      if (current !== requestId || !isAdmin()) return;
      const employeeMode = mode === "employees";
      view.querySelector("thead").innerHTML = employeeMode
        ? "<tr><th>Mã</th><th>Nhân viên</th><th>Điện thoại</th><th>Ngày vào làm</th><th>Trạng thái</th><th></th></tr>"
        : "<tr><th>Mã</th><th>Tên đăng nhập</th><th>Nhân viên</th><th>Vai trò</th><th>Trạng thái</th><th></th></tr>";
      view.querySelector("tbody").innerHTML = result.items.map((item) => {
        const code = employeeMode ? item.maNhanVien : item.maTaiKhoan;
        const active = employeeMode ? item.dangLamViec : item.trangThai;
        return `<tr><td class="cell-primary">${escapeHtml(code)}</td>
          <td>${escapeHtml(employeeMode ? item.tenNhanVien : item.tenTaiKhoan)}</td>
          <td>${escapeHtml(employeeMode ? (item.soDienThoai || "—") : item.tenNhanVien)}</td>
          <td>${escapeHtml(employeeMode ? item.ngayVaoLam : item.role)}</td>
          <td><span class="status ${active ? "status-success" : "status-muted"}">${active ? (employeeMode ? "Đang làm việc" : "Hoạt động") : (employeeMode ? "Ngừng làm việc" : "Đã khóa")}</span></td>
          <td><button class="row-action" type="button" data-code="${escapeHtml(code)}" aria-label="Sửa ${escapeHtml(code)}">›</button></td></tr>`;
      }).join("");
      view.querySelector("#identityEmpty").hidden = result.items.length > 0;
      view.querySelector("table").hidden = result.items.length === 0;
      view.querySelector("#identityRange").textContent = `${result.totalElements} bản ghi · trang ${page + 1}/${Math.max(1, result.totalPages)}`;
      view.querySelector("#identityPrevious").disabled = page <= 0;
      view.querySelector("#identityNext").disabled = page + 1 >= result.totalPages;
      message("");
    } catch (error) {
      if (current !== requestId) return;
      view.querySelector("table").hidden = true;
      message(error.message || "Không tải được dữ liệu.", true);
      if (error.status === 401) requireLogin();
    }
  }

  function show(nextMode) {
    if (!isAdmin()) return;
    if (mode !== nextMode) page = 0;
    mode = nextMode;
    if (dialog.open) dialog.close();
    view.querySelector("#identityTitle").textContent = mode === "employees" ? "Nhân viên" : "Tài khoản đăng nhập";
    view.querySelector("#identityDescription").textContent = mode === "employees"
      ? "Quản lý hồ sơ và trạng thái làm việc của nhân viên."
      : "Phân quyền, khóa tài khoản và đặt lại mật khẩu.";
    view.querySelector("#identityAdd").textContent = mode === "employees" ? "Thêm nhân viên" : "Thêm tài khoản";
    load();
  }

  function start() {
    view.innerHTML = `<div class="section-toolbar"><div><h2 id="identityTitle"></h2><p id="identityDescription"></p></div>
      <button class="button button-primary" id="identityAdd" type="button"></button></div>
      <article class="data-surface"><p class="list-message" id="identityMessage" role="status" aria-live="polite" hidden></p>
      <div class="table-wrap"><table><thead></thead><tbody></tbody></table></div>
      <div class="empty-state" id="identityEmpty" hidden><h3>Chưa có dữ liệu</h3><p>Thêm bản ghi đầu tiên để bắt đầu.</p></div>
      <footer class="pagination"><span id="identityRange"></span><div>
        <button id="identityPrevious" type="button" aria-label="Trang trước">‹</button>
        <button id="identityNext" type="button" aria-label="Trang sau">›</button></div></footer></article>`;
    dialog.innerHTML = `<div class="identity-dialog-content"><div class="panel-heading"><div><h2 id="identityDialogTitle"></h2>
      <p>Mã đã tạo sẽ không thay đổi; khóa tài khoản để ngừng truy cập.</p></div>
      <button class="button button-quiet" type="button" id="identityClose" aria-label="Đóng">Đóng</button></div>
      <form id="identityForm"><div class="form-grid" id="identityFields"></div>
        <p class="list-message text-danger" id="identityFormError" role="alert" hidden></p>
        <div class="toolbar-actions"><button class="button button-primary" type="submit" id="identitySave">Lưu</button></div></form>
      <div id="identityResetSection" hidden><label class="field"><span>Mật khẩu mới (12–72 ký tự)</span>
        <input id="identityResetPassword" type="password" minlength="12" maxlength="72" autocomplete="new-password"></label>
        <button class="button button-secondary" id="identityReset" type="button">Đặt lại mật khẩu</button></div></div>`;
    document.querySelector("#mainContent").append(view);
    document.body.append(dialog);
    view.querySelector("#identityAdd").addEventListener("click", () => openEditor());
    view.querySelector("#identityPrevious").addEventListener("click", () => load(page - 1));
    view.querySelector("#identityNext").addEventListener("click", () => load(page + 1));
    view.querySelector("tbody").addEventListener("click", async (event) => {
      const button = event.target.closest("[data-code]");
      if (!button || !isAdmin()) return;
      try { openEditor(await identity[mode].get(button.dataset.code)); }
      catch (error) { message(error.message || "Không tải được bản ghi.", true); }
    });
    dialog.querySelector("#identityClose").addEventListener("click", () => dialog.close());
    dialog.querySelector("#identityForm").addEventListener("submit", async (event) => {
      event.preventDefault();
      if (!isAdmin() || !event.currentTarget.reportValidity()) return;
      const save = dialog.querySelector("#identitySave");
      save.disabled = true;
      formError("");
      try {
        if (mode === "employees") {
          const body = employeeBody();
          if (editingCode) await identity.employees.update(editingCode, body);
          else await identity.employees.create({ maNhanVien: field("maNhanVien").value.trim(), ...body });
        } else {
          const body = accountBody();
          if (editingCode) await identity.accounts.update(editingCode, body);
          else await identity.accounts.create(body);
        }
        dialog.close();
        showToast("Đã lưu thông tin.");
        await load(0);
      } catch (error) {
        formError(error.message || "Không lưu được thông tin.");
        if (error.status === 401) requireLogin();
      } finally { save.disabled = false; }
    });
    dialog.querySelector("#identityReset").addEventListener("click", async () => {
      if (!isAdmin() || !editingCode || mode !== "accounts") return;
      const input = dialog.querySelector("#identityResetPassword");
      input.required = true;
      if (!input.reportValidity()) return;
      const button = dialog.querySelector("#identityReset");
      button.disabled = true;
      formError("");
      try {
        await identity.accounts.resetPassword(editingCode, input.value);
        input.value = "";
        showToast("Đã đặt lại mật khẩu.");
      } catch (error) {
        formError(error.message || "Không đặt lại được mật khẩu.");
        if (error.status === 401) requireLogin();
      } finally { button.disabled = false; }
    });
  }

  function clear() {
    requestId++;
    if (dialog.open) dialog.close();
    view.querySelector("tbody").replaceChildren();
  }

  return { start, show, clear, viewId: view.id };
}
