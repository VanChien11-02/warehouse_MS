export function createLiveDocuments({ documents, isAuthenticated, getRole, requireLogin }) {
  let mode = "inbound";
  let current = null;
  let pending = false;
  const view = document.createElement("section");
  view.className = "view";
  view.id = "liveDocumentView";
  view.hidden = true;

  function field(id) {
    return document.querySelector(`#${id}`);
  }

  function setMessage(message, error = false) {
    const node = field("liveDocMessage");
    node.textContent = message;
    node.hidden = !message;
    node.classList.toggle("text-danger", error);
  }

  function canWrite() {
    return isAuthenticated() && ["QLKHO", "NVKHO"].includes(getRole());
  }

  function updateActions() {
    const draft = current?.trangThai === "NHAP";
    field("liveDocCreate").hidden = !canWrite() || !!current;
    field("liveDocComplete").hidden = !draft || getRole() !== "QLKHO" || current.chiTiet.length !== 1;
    field("liveDocCancel").hidden = !draft || !canWrite();
    field("liveDocSuggest").hidden = mode !== "outbound" || !draft || !canWrite();
    for (const id of ["liveDocPartner", "liveDocLot", "liveDocQuantity", "liveDocPrice", "liveDocNote"]) {
      field(id).readOnly = !!current;
    }
    field("liveDocProduct").readOnly = !!current && mode === "inbound";
    field("liveDocPosition").readOnly = !!current && mode === "outbound";
  }

  function reset() {
    current = null;
    field("liveDocForm").reset();
    field("liveDocState").textContent = "Chưa có phiếu được chọn.";
    field("liveDocLoadCode").value = "";
    setMessage(isAuthenticated() ? "" : "Đăng nhập để thao tác chứng từ.");
    updateActions();
  }

  function show(nextMode) {
    if (mode !== nextMode) {
      mode = nextMode;
      reset();
    }
    const inbound = mode === "inbound";
    field("liveDocTitle").textContent = inbound ? "Phiếu nhập kho" : "Phiếu xuất kho";
    field("liveDocHelp").textContent = inbound
      ? "Tạo phiếu một dòng, chỉ định vị trí và hạn lô, rồi hoàn tất ghi sổ."
      : "Tạo phiếu một dòng từ lô/vị trí đang có tồn; backend kiểm tra FEFO khi hoàn tất.";
    field("liveDocPartnerLabel").textContent = inbound ? "Mã nhà cung cấp *" : "Mã đối tác nhận *";
    field("liveDocProductLabel").textContent = inbound ? "Mã sản phẩm *" : "Mã sản phẩm để gợi ý FEFO";
    field("liveDocPriceLabel").textContent = inbound ? "Đơn giá nhập *" : "Đơn giá xuất *";
    field("liveDocLotField").hidden = inbound;
    field("liveDocExpiryField").hidden = !inbound;
    field("liveDocProduct").required = inbound;
    field("liveDocLot").required = !inbound;
    updateActions();
    if (!isAuthenticated()) setMessage("Đăng nhập để thao tác chứng từ.");
    else if (!canWrite()) setMessage("Vai trò hiện tại chỉ được xem chứng từ.");
    else if (!current) setMessage("");
  }

  function display(documentData) {
    current = documentData;
    const code = mode === "inbound" ? current.maPhieuNhap : current.maPhieuXuat;
    field("liveDocState").textContent = `${code} · ${current.trangThai} · ${current.chiTiet.length} dòng`;
    field("liveDocLoadCode").value = code;
    field("liveDocPartner").value = mode === "inbound" ? current.maNhaCungCap : current.maDoiTacNhanHang;
    field("liveDocNote").value = current.ghiChu || "";
    if (current.chiTiet.length === 1) {
      const line = current.chiTiet[0];
      field("liveDocProduct").value = line.maSanPham || "";
      field("liveDocLot").value = line.maLo || "";
      field("liveDocPosition").value = line.maViTri || field("liveDocPosition").value;
      field("liveDocQuantity").value = line.soLuong;
      field("liveDocPrice").value = mode === "inbound" ? line.donGiaNhap : line.donGiaXuat;
    }
    updateActions();
    if (current.chiTiet.length !== 1) {
      setMessage("Phiếu nhiều dòng: dùng HTTP client theo contract để hoàn tất.");
    }
  }

  async function run(action) {
    if (pending) return;
    pending = true;
    for (const button of view.querySelectorAll("button")) button.disabled = true;
    setMessage("Đang xử lý...");
    try {
      await action();
    } catch (error) {
      setMessage(error.message || "Không thực hiện được thao tác.", true);
      if (error.status === 401) requireLogin();
    } finally {
      pending = false;
      for (const button of view.querySelectorAll("button")) button.disabled = false;
      updateActions();
    }
  }

  function start() {
    view.innerHTML = `<div class="section-toolbar"><div><h2 id="liveDocTitle"></h2><p id="liveDocHelp"></p></div></div>
      <article class="panel form-panel">
        <div class="panel-heading"><div><h3>Chứng từ</h3><p id="liveDocState">Chưa có phiếu được chọn.</p></div>
          <div class="toolbar-actions"><label class="field"><span>Mã phiếu đã lập</span><input id="liveDocLoadCode" maxlength="6" pattern="[A-Za-z0-9]{1,6}" placeholder="PN0001 / PX0001"></label>
          <button class="button button-secondary" id="liveDocLoad" type="button">Tải phiếu</button></div></div>
        <form id="liveDocForm"><div class="form-grid four-columns">
          <label class="field"><span id="liveDocPartnerLabel"></span><input id="liveDocPartner" maxlength="6" pattern="[A-Za-z0-9]{1,6}" required></label>
          <label class="field"><span id="liveDocProductLabel"></span><input id="liveDocProduct" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label>
          <label class="field" id="liveDocLotField"><span>Mã lô *</span><input id="liveDocLot" maxlength="6" pattern="[A-Za-z0-9]{1,6}"></label>
          <label class="field"><span>Mã vị trí *</span><input id="liveDocPosition" maxlength="6" pattern="[A-Za-z0-9]{1,6}" required></label>
          <label class="field"><span>Số lượng *</span><input id="liveDocQuantity" type="number" min="1" step="1" required></label>
          <label class="field"><span id="liveDocPriceLabel"></span><input id="liveDocPrice" type="number" min="0" step="0.0001" required></label>
          <label class="field" id="liveDocExpiryField"><span>Hạn dùng</span><input id="liveDocExpiry" type="date"></label>
          <label class="field field-wide"><span>Ghi chú</span><textarea id="liveDocNote" maxlength="1000" rows="2"></textarea></label>
        </div><div class="toolbar-actions live-document-actions">
          <button class="button button-primary" id="liveDocCreate" type="submit">Tạo nháp</button>
          <button class="button button-secondary" id="liveDocSuggest" type="button" hidden>Gợi ý FEFO</button>
          <button class="button button-primary" id="liveDocComplete" type="button" hidden>Hoàn tất</button>
          <button class="button button-quiet" id="liveDocCancel" type="button" hidden>Hủy nháp</button>
        </div></form>
      </article><p class="list-message" id="liveDocMessage" role="status" aria-live="polite" hidden></p>`;
    document.querySelector("#mainContent").append(view);
    field("liveDocForm").addEventListener("submit", (event) => {
      event.preventDefault();
      if (!canWrite() || current || !event.currentTarget.reportValidity()) return;
      run(async () => {
        const line = { soLuong: Number(field("liveDocQuantity").value) };
        const body = { ghiChu: field("liveDocNote").value.trim() || null };
        if (mode === "inbound") {
          body.maNhaCungCap = field("liveDocPartner").value.trim();
          body.chiTiet = [{ ...line, maSanPham: field("liveDocProduct").value.trim(),
            donGiaNhap: Number(field("liveDocPrice").value) }];
        } else {
          body.maDoiTacNhanHang = field("liveDocPartner").value.trim();
          body.chiTiet = [{ ...line, maLo: field("liveDocLot").value.trim(),
            maViTri: field("liveDocPosition").value.trim(), donGiaXuat: Number(field("liveDocPrice").value) }];
        }
        display(await documents[mode].create(body));
        setMessage("Đã tạo phiếu nháp. Quản lý kho có thể hoàn tất.");
      });
    });
    field("liveDocLoad").addEventListener("click", () => {
      const code = field("liveDocLoadCode").value.trim();
      if (!isAuthenticated() || !field("liveDocLoadCode").reportValidity()) return;
      if (!code) { setMessage("Nhập mã phiếu để tải.", true); return; }
      run(async () => {
        const loaded = await documents[mode].get(code);
        field("liveDocForm").reset();
        display(loaded);
        setMessage("Đã tải phiếu.");
      });
    });
    field("liveDocComplete").addEventListener("click", () => {
      if (!current || getRole() !== "QLKHO" || current.trangThai !== "NHAP") return;
      if (mode === "inbound" && !field("liveDocForm").reportValidity()) return;
      run(async () => {
        const code = mode === "inbound" ? current.maPhieuNhap : current.maPhieuXuat;
        const body = mode === "inbound" ? { phanBo: [{
          maSanPham: current.chiTiet[0].maSanPham,
          maViTri: field("liveDocPosition").value.trim(),
          soLuong: current.chiTiet[0].soLuong,
          hanSuDung: field("liveDocExpiry").value || null
        }] } : undefined;
        await documents[mode].complete(code, body);
        display(await documents[mode].get(code));
        setMessage("Đã hoàn tất và ghi sổ. Xem tồn kho và báo cáo để đối chiếu.");
      });
    });
    field("liveDocCancel").addEventListener("click", () => {
      if (!current || !canWrite() || current.trangThai !== "NHAP") return;
      run(async () => {
        const code = mode === "inbound" ? current.maPhieuNhap : current.maPhieuXuat;
        display(await documents[mode].cancel(code));
        setMessage("Đã hủy phiếu nháp.");
      });
    });
    field("liveDocSuggest").addEventListener("click", () => {
      if (mode !== "outbound" || !current || !canWrite()) return;
      if (!field("liveDocProduct").reportValidity() || !field("liveDocProduct").value.trim()) {
        setMessage("Nhập mã sản phẩm để xem gợi ý FEFO.", true);
        return;
      }
      run(async () => {
        const result = await documents.outbound.suggest(current.maPhieuXuat,
          field("liveDocProduct").value.trim(), Number(field("liveDocQuantity").value));
        const allocations = result.phanBo.map((part) =>
          `${part.maLo}/${part.maViTri}: ${part.soLuong}`).join(", ");
        setMessage(`Gợi ý FEFO: ${allocations || "không có tồn"}. Thiếu ${result.soLuongThieu}. Phiếu nháp chưa được sửa tự động.`);
      });
    });
    reset();
  }

  return { start, show, viewId: view.id };
}
