export function createLiveProducts({ client, products, escapeHtml, formatCurrency, showToast,
  onSessionChange = () => {},
  closeEditor }) {
  const dialog = document.querySelector("#loginDialog");
  const loginForm = document.querySelector("#loginForm");
  const loginError = document.querySelector("#loginError");
  const listMessage = document.querySelector("#listMessage");
  const table = document.querySelector("#dataTable");
  const editor = document.querySelector("#recordEditor");
  const recordForm = document.querySelector("#recordForm");
  const addButton = document.querySelector("#addRecordButton");
  let user = null;
  let editingCode = null;
  let requestId = 0;

  function canWrite() {
    return user && ["ADMIN", "QLKHO"].includes(user.role);
  }

  function setMessage(message, error = false) {
    listMessage.textContent = message;
    listMessage.hidden = !message;
    listMessage.classList.toggle("text-danger", error);
  }

  function showLogin(message = "") {
    loginError.textContent = message;
    loginError.hidden = !message;
    if (!dialog.open) dialog.showModal();
  }

  function setUser(nextUser) {
    user = nextUser;
    addButton.hidden = !canWrite();
    document.querySelector("#logoutButton").hidden = !user;
    document.querySelector("#userName").textContent = user?.tenNhanVien || "Chưa đăng nhập";
    document.querySelector("#userRole").textContent = user?.role || "Dữ liệu API";
    document.querySelector("#userAvatar").textContent = user?.tenNhanVien?.trim().slice(0, 2).toUpperCase() || "?";
    onSessionChange();
  }

  function showPage(page) {
    const totalPages = Math.max(1, page.totalPages);
    const number = page.page + 1;
    table.querySelector("thead").innerHTML = "<tr><th>Mã sản phẩm</th><th>Tên sản phẩm</th><th>Loại</th><th>Đơn vị</th><th>Giá bán</th><th>Chi tiết</th></tr>";
    table.querySelector("tbody").innerHTML = page.items.map((item) => `
      <tr><td><span class="cell-primary">${escapeHtml(item.maSanPham)}</span></td>
      <td>${escapeHtml(item.tenSanPham)}</td><td>${escapeHtml(item.tenLoai)}</td>
      <td>${escapeHtml(item.tenDonViTinh)}</td>
      <td class="number-cell">${escapeHtml(formatCurrency(item.giaBanMacDinh))}</td>
      <td><button class="row-action" type="button" data-row-action="open" data-code="${escapeHtml(item.maSanPham)}" aria-label="Mở ${escapeHtml(item.maSanPham)}">›</button></td></tr>`).join("");
    document.querySelector("#listEmpty").hidden = page.items.length !== 0;
    table.hidden = page.items.length === 0;
    document.querySelector(".pagination").hidden = page.totalElements === 0;
    const start = page.totalElements ? page.page * page.size + 1 : 0;
    const end = page.totalElements ? start + page.items.length - 1 : 0;
    document.querySelector("#recordRange").textContent = `Hiển thị ${start}–${end} trong ${page.totalElements} bản ghi`;
    document.querySelector("#previousPage").disabled = number <= 1;
    document.querySelector("#nextPage").disabled = number >= totalPages;
    const firstPage = Math.max(1, Math.min(number - 3, totalPages - 6));
    document.querySelector("#pageNumbers").innerHTML = Array.from({ length: Math.min(totalPages, 7) }, (_, index) => {
      const visiblePage = firstPage + index;
      const selected = visiblePage === number;
      return `<button type="button" data-page-number="${visiblePage}" ${selected ? 'class="active" aria-current="page"' : ""}>${visiblePage}</button>`;
    }).join("");
  }

  async function render(page, query) {
    const current = ++requestId;
    if (!user) {
      table.querySelector("tbody").replaceChildren();
      table.hidden = true;
      document.querySelector(".pagination").hidden = true;
      setMessage("Đăng nhập để xem danh mục sản phẩm.");
      return;
    }
    setMessage("Đang tải sản phẩm...");
    try {
      const response = await products.list(page - 1, 8, query.trim());
      if (current !== requestId) return;
      showPage(response);
      setMessage("");
    } catch (error) {
      if (current !== requestId) return;
      table.hidden = true;
      document.querySelector(".pagination").hidden = true;
      setMessage(error.message || "Không tải được sản phẩm.", true);
      if (error.status === 401) {
        setUser(null);
        showLogin("Phiên đăng nhập đã hết hạn.");
      }
    }
  }

  async function openEditor(code = null) {
    editingCode = code;
    const writable = canWrite();
    document.querySelector("#recordEditorTitle").textContent = code ? "Chi tiết sản phẩm" : "Thêm sản phẩm";
    editor.querySelector(".editor-header p").textContent = code
      ? "Thông tin sản phẩm hiện tại." : "Tạo sản phẩm mới.";
    recordForm.querySelector(".editor-body").innerHTML = `
      <label class="field"><span>Mã sản phẩm *</span><input id="liveCode" maxlength="6" pattern="[A-Za-z0-9]{1,6}" required></label>
      <label class="field"><span>Tên sản phẩm *</span><input id="liveName" maxlength="255" required></label>
      <label class="field"><span>Loại sản phẩm *</span><select id="liveCategory" required></select></label>
      <label class="field"><span>Đơn vị tính *</span><select id="liveUnit" required></select></label>
      <label class="field"><span>Giá nhập mặc định *</span><input id="liveImportPrice" type="number" min="0" step="0.0001" required></label>
      <label class="field"><span>Giá bán mặc định *</span><input id="liveSalePrice" type="number" min="0" step="0.0001" required></label>
      <p class="text-danger" id="liveFormError" role="alert" hidden></p>`;
    document.querySelector("#liveSaveButton").hidden = !writable;
    document.querySelector("#liveDeleteButton").hidden = !writable || !code;
    editor.hidden = false;
    document.querySelector("#editorOverlay").hidden = false;
    document.body.style.overflow = "hidden";
    try {
      const [references, item] = await Promise.all([
        products.references(), code ? products.get(code) : Promise.resolve(null)
      ]);
      const category = document.querySelector("#liveCategory");
      const unit = document.querySelector("#liveUnit");
      category.innerHTML = '<option value="">Chọn loại</option>' + references.categories.map((entry) =>
        `<option value="${escapeHtml(entry.maLoai)}">${escapeHtml(entry.tenLoai)}</option>`).join("");
      unit.innerHTML = '<option value="">Chọn đơn vị</option>' + references.units.map((entry) =>
        `<option value="${escapeHtml(entry.maDonViTinh)}">${escapeHtml(entry.tenDonViTinh)}</option>`).join("");
      if (item) {
        document.querySelector("#liveCode").value = item.maSanPham;
        document.querySelector("#liveName").value = item.tenSanPham;
        category.value = item.maLoai;
        unit.value = item.maDonViTinh;
        document.querySelector("#liveImportPrice").value = item.giaNhapMacDinh;
        document.querySelector("#liveSalePrice").value = item.giaBanMacDinh;
      }
      document.querySelector("#liveCode").readOnly = !!code;
      category.disabled = !!code || !writable;
      unit.disabled = !!code || !writable;
      for (const field of recordForm.querySelectorAll("input")) {
        if (!writable) field.readOnly = true;
      }
      document.querySelector("#liveCode").focus();
    } catch (error) {
      const message = document.querySelector("#liveFormError");
      message.textContent = error.message || "Không tải được thông tin sản phẩm.";
      message.hidden = false;
    }
  }

  async function submit(event) {
    event.preventDefault();
    if (!canWrite() || !recordForm.reportValidity()) return;
    const body = {
      tenSanPham: document.querySelector("#liveName").value.trim(),
      giaNhapMacDinh: Number(document.querySelector("#liveImportPrice").value),
      giaBanMacDinh: Number(document.querySelector("#liveSalePrice").value)
    };
    const save = document.querySelector("#liveSaveButton");
    save.disabled = true;
    try {
      if (editingCode) await products.update(editingCode, body);
      else await products.create({
        maSanPham: document.querySelector("#liveCode").value.trim(),
        maLoai: document.querySelector("#liveCategory").value,
        maDonViTinh: document.querySelector("#liveUnit").value,
        ...body
      });
      closeEditor();
      showToast("Đã lưu sản phẩm.");
      await render(1, document.querySelector("#listSearch").value);
    } catch (error) {
      const message = document.querySelector("#liveFormError");
      message.textContent = error.message || "Không lưu được sản phẩm.";
      message.hidden = false;
    } finally {
      save.disabled = false;
    }
  }

  async function remove() {
    if (!canWrite() || !editingCode || !window.confirm(`Xóa sản phẩm ${editingCode}?`)) return;
    try {
      await products.remove(editingCode);
      closeEditor();
      showToast("Đã xóa sản phẩm.");
      await render(1, document.querySelector("#listSearch").value);
    } catch (error) {
      const message = document.querySelector("#liveFormError");
      message.textContent = error.message || "Không xóa được sản phẩm.";
      message.hidden = false;
    }
  }

  async function start() {
    setUser(null);
    dialog.addEventListener("cancel", (event) => event.preventDefault());
    loginForm.addEventListener("submit", async (event) => {
      event.preventDefault();
      const submitButton = loginForm.querySelector('button[type="submit"]');
      submitButton.disabled = true;
      loginError.hidden = true;
      try {
        const username = loginForm.elements.namedItem("tenTaiKhoan").value.trim();
        const password = loginForm.elements.namedItem("matKhau").value;
        const signedIn = await client.login(username, password);
        setUser(signedIn);
        loginForm.reset();
        dialog.close();
        await render(1, document.querySelector("#listSearch").value);
      } catch (error) {
        loginError.textContent = error.message || "Không đăng nhập được.";
        loginError.hidden = false;
        loginForm.elements.namedItem("matKhau").value = "";
      } finally {
        submitButton.disabled = false;
      }
    });
    document.querySelector("#logoutButton").addEventListener("click", async () => {
      try {
        await client.logout();
        setUser(null);
        await render(1, "");
        showLogin();
      } catch (error) {
        showToast(error.message || "Không đăng xuất được.");
      }
    });
    document.querySelector("#liveDeleteButton").addEventListener("click", remove);
    try {
      setUser(await client.send("/auth/me"));
      await render(1, "");
    } catch (error) {
      showLogin(error.status === 401 ? "" : "Không kết nối được hệ thống. Kiểm tra dịch vụ đang chạy.");
    }
  }

  return {
    render, openEditor, submit, start,
    isAuthenticated: () => !!user,
    getRole: () => user?.role || null,
    requireLogin: () => { setUser(null); showLogin("Phiên đăng nhập đã hết hạn."); }
  };
}
