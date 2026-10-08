"use strict";

import { roleProfiles, navDefinition, pageMeta } from "./core/navigation.js";
import { createApiClient } from "./core/api-client.js";
import { listConfigs, inventoryRows, countRows, reportData, documentProducts } from "./data/demo.js";
import { createProductApi } from "./data/product-api.js";
import { createInventoryApi } from "./data/inventory-api.js";
import { createReportApi } from "./data/report-api.js";
import { createDocumentApi } from "./data/document-api.js";
import { createLiveProducts } from "./features/live-products.js";
import { createLiveInventory } from "./features/live-inventory.js";
import { createLiveReport } from "./features/live-report.js";
import { createLiveDocuments } from "./features/live-documents.js";

const USE_DUMMY_DATA = new URLSearchParams(window.location.search).get("mode") !== "api";
const requestedApiPort = new URLSearchParams(window.location.search).get("apiPort");
const apiPort = /^\d{1,5}$/.test(requestedApiPort || "")
  && Number(requestedApiPort) >= 1 && Number(requestedApiPort) <= 65535
  ? requestedApiPort : "8080";
const API_BASE_URL = `http://127.0.0.1:${apiPort}/api`;

const elements = {
  sidebar: document.querySelector("#sidebar"),
  sidebarOverlay: document.querySelector("#sidebarOverlay"),
  mobileMenuButton: document.querySelector("#mobileMenuButton"),
  navGroups: document.querySelector("#navGroups"),
  pageTitle: document.querySelector("#pageTitle"),
  pageSubtitle: document.querySelector("#pageSubtitle"),
  roleSwitcher: document.querySelector("#roleSwitcher"),
  listSearch: document.querySelector("#listSearch"),
  statusFilter: document.querySelector("#statusFilter"),
  dataTable: document.querySelector("#dataTable"),
  listEmpty: document.querySelector("#listEmpty"),
  recordRange: document.querySelector("#recordRange"),
  pageNumbers: document.querySelector("#pageNumbers"),
  previousPage: document.querySelector("#previousPage"),
  nextPage: document.querySelector("#nextPage"),
  documentForm: document.querySelector("#documentForm"),
  documentRows: document.querySelector("#documentRows"),
  documentError: document.querySelector("#documentError"),
  recordEditor: document.querySelector("#recordEditor"),
  editorOverlay: document.querySelector("#editorOverlay"),
  recordForm: document.querySelector("#recordForm"),
  toast: document.querySelector("#toast"),
  commandResults: document.querySelector("#commandResults")
};

let activeRole = "manager";
let activeView = "dashboard";
let activeList = "products";
let currentPage = 1;
const pageSize = 8;
let toastTimer;
const apiClient = USE_DUMMY_DATA ? null : createApiClient({ baseUrl: API_BASE_URL });
let liveInventory = null;
let liveReport = null;
let liveDocuments = null;
const liveProducts = USE_DUMMY_DATA ? null : createLiveProducts({
  client: apiClient,
  products: createProductApi(apiClient),
  escapeHtml,
  formatCurrency,
  showToast,
  onSessionChange: () => {
    if (activeView === "inventory") liveInventory?.render();
    if (activeView === "reports") liveReport?.render();
    if (["inbound", "outbound"].includes(activeView)) liveDocuments?.show(activeView);
  },
  closeEditor: closeRecordEditor
});
if (!USE_DUMMY_DATA) {
  liveInventory = createLiveInventory({
    inventory: createInventoryApi(apiClient),
    escapeHtml,
    isAuthenticated: liveProducts.isAuthenticated,
    requireLogin: liveProducts.requireLogin
  });
  liveReport = createLiveReport({
    reports: createReportApi(apiClient),
    escapeHtml,
    isAuthenticated: liveProducts.isAuthenticated,
    requireLogin: liveProducts.requireLogin
  });
  liveDocuments = createLiveDocuments({
    documents: createDocumentApi(apiClient),
    isAuthenticated: liveProducts.isAuthenticated,
    getRole: liveProducts.getRole,
    requireLogin: liveProducts.requireLogin
  });
}

function icon(name) {
  return `<svg aria-hidden="true"><use href="#icon-${name}"/></svg>`;
}

function localDateValue(date = new Date()) {
  const offsetDate = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return offsetDate.toISOString().slice(0, 10);
}

function formatCurrency(value) {
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    maximumFractionDigits: 0
  }).format(Number(value) || 0);
}

function escapeHtml(value) {
  const holder = document.createElement("div");
  holder.textContent = String(value);
  return holder.innerHTML;
}

function showToast(message) {
  clearTimeout(toastTimer);
  elements.toast.textContent = message;
  elements.toast.hidden = false;
  toastTimer = window.setTimeout(() => {
    elements.toast.hidden = true;
  }, 3200);
}

function statusClass(status) {
  const normalized = String(status).toLocaleLowerCase("vi");
  if (normalized.includes("hỏng") || normalized.includes("hủy") || normalized.includes("dưới")) return "status-danger";
  if (normalized.includes("chờ") || normalized.includes("sắp")) return "status-pending";
  if (normalized.includes("đang chuyển")) return "status-info";
  if (normalized.includes("hoạt động") || normalized.includes("khả dụng") || normalized.includes("đã nhập") || normalized.includes("đã xuất")) return "status-success";
  return "status-muted";
}

function closeMobileMenu() {
  elements.sidebar.classList.remove("open");
  elements.sidebarOverlay.hidden = true;
  elements.mobileMenuButton.setAttribute("aria-expanded", "false");
}

function renderNavigation() {
  if (!USE_DUMMY_DATA) {
    elements.navGroups.innerHTML = `<section class="nav-group"><p class="nav-group-title">Danh mục</p>
      <button class="nav-item" type="button" data-view="products">${icon("box")}<span>Sản phẩm</span></button></section>
      <section class="nav-group"><p class="nav-group-title">Kho</p>
      <button class="nav-item" type="button" data-view="inventory">${icon("chart")}<span>Tồn kho</span></button>
      <button class="nav-item" type="button" data-view="reports">${icon("chart")}<span>Báo cáo nhập–xuất–tồn</span></button></section>
      <section class="nav-group"><p class="nav-group-title">Chứng từ</p>
      <button class="nav-item" type="button" data-view="inbound">${icon("file")}<span>Phiếu nhập</span></button>
      <button class="nav-item" type="button" data-view="outbound">${icon("file")}<span>Phiếu xuất</span></button></section>`;
    updateActiveNavigation();
    return;
  }
  const allowedPages = new Set(roleProfiles[activeRole].pages);
  const fragment = document.createDocumentFragment();

  navDefinition.forEach((group) => {
    const items = group.items.filter((item) => allowedPages.has(item.id));
    if (!items.length) return;
    const section = document.createElement("section");
    section.className = "nav-group";
    const title = document.createElement("p");
    title.className = "nav-group-title";
    title.textContent = group.label;
    section.append(title);
    items.forEach((item) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "nav-item";
      button.dataset.view = item.id;
      button.innerHTML = `${icon(item.icon)}<span>${escapeHtml(item.label)}</span>${item.badge ? `<small>${item.badge}</small>` : ""}`;
      section.append(button);
    });
    fragment.append(section);
  });
  elements.navGroups.replaceChildren(fragment);
  updateActiveNavigation();
}

function updateActiveNavigation() {
  document.querySelectorAll(".nav-item").forEach((item) => {
    const isActive = item.dataset.view === activeView;
    item.classList.toggle("active", isActive);
    if (isActive) item.setAttribute("aria-current", "page");
    else item.removeAttribute("aria-current");
  });
}

function applyRole(role) {
  activeRole = roleProfiles[role] ? role : "manager";
  const profile = roleProfiles[activeRole];
  elements.roleSwitcher.value = activeRole;
  document.querySelector("#userName").textContent = profile.name;
  document.querySelector("#userRole").textContent = profile.label;
  document.querySelector("#userAvatar").textContent = profile.initials;
  document.querySelector("#primaryActionLabel").textContent = profile.primaryAction;
  renderNavigation();

  if (!profile.pages.includes(activeView)) showView("dashboard");
  else updateActiveNavigation();
  showToast(`Đã chuyển giao diện sang vai trò ${profile.label}. Quyền thực thi vẫn do backend kiểm soát.`);
}

function setVisibleView(viewId) {
  document.querySelectorAll(".view").forEach((view) => {
    const active = view.id === viewId;
    view.hidden = !active;
    view.classList.toggle("active", active);
  });
}

function configureDocument(mode) {
  const config = {
    inbound: {
      title: "Lập phiếu nhập kho",
      description: "Tiếp nhận hàng hóa và chỉ định vị trí nhập.",
      code: "PN-261002-01",
      partnerLabel: "Nhà cung cấp *",
      partnerOptions: [["", "Chọn nhà cung cấp"], ["NCC001", "Vinamilk miền Nam"], ["NCC002", "Thực phẩm Á Châu"], ["NCC003", "Nông sản Đà Lạt"]],
      action: "Tạo phiếu nhập",
      statuses: ["Chờ nhập", "Đã nhập", "Đã hủy"]
    },
    outbound: {
      title: "Lập phiếu xuất kho",
      description: "Chọn hàng theo FEFO và kiểm tra tồn trước khi hoàn tất.",
      code: "PX-261002-01",
      partnerLabel: "Đối tác nhận hàng *",
      partnerOptions: [["", "Chọn đối tác"], ["DT001", "Siêu thị An Phú"], ["DT002", "Cửa hàng Minh Long"], ["DT003", "Đại lý Thành Công"]],
      action: "Tạo phiếu xuất",
      statuses: ["Chờ xuất", "Đã xuất", "Đã hủy"]
    },
    transfer: {
      title: "Lập phiếu chuyển kho",
      description: "Chuyển hàng giữa hai kho hoặc vị trí theo giao dịch nguyên tử.",
      code: "CK-261002-01",
      partnerLabel: "Kho / vị trí đích *",
      partnerOptions: [["", "Chọn kho đích"], ["K02", "Kho lạnh · K02"], ["K03", "Kho hàng trả · K03"], ["K04", "Kho miền Tây · K04"]],
      action: "Tạo phiếu chuyển",
      statuses: ["Chờ chuyển", "Đã chuyển", "Đã hủy"]
    }
  }[mode];

  document.querySelector("#documentTitle").textContent = config.title;
  document.querySelector("#documentDescription").textContent = config.description;
  document.querySelector("#documentCode").textContent = config.code;
  document.querySelector("#documentCodeInput").value = config.code;
  document.querySelector("#partnerLabel").textContent = config.partnerLabel;
  document.querySelector("#completeDocumentLabel").textContent = config.action;
  const partner = document.querySelector("#documentPartner");
  partner.innerHTML = config.partnerOptions.map(([value, label]) => `<option value="${value}">${escapeHtml(label)}</option>`).join("");
  elements.documentRows.replaceChildren();
  addDocumentRow(config.statuses);
  addDocumentRow(config.statuses);
  updateDocumentSummary();
}

function showView(viewName, updateHash = true) {
  const profile = roleProfiles[activeRole];
  if (!USE_DUMMY_DATA && !["products", "inventory", "reports", "inbound", "outbound"].includes(viewName)) viewName = "products";
  else if (!profile.pages.includes(viewName)) {
    showToast("Vai trò hiện tại không hiển thị chức năng này.");
    viewName = "dashboard";
  }

  activeView = viewName;
  const [title, subtitle] = pageMeta[viewName] || pageMeta.dashboard;
  elements.pageTitle.textContent = title;
  elements.pageSubtitle.textContent = subtitle;

  if (viewName === "dashboard") setVisibleView("dashboardView");
  else if (viewName === "inventory") {
    setVisibleView("inventoryView");
    if (USE_DUMMY_DATA) renderInventory();
    else liveInventory.render();
  } else if (!USE_DUMMY_DATA && ["inbound", "outbound"].includes(viewName)) {
    setVisibleView(liveDocuments.viewId);
    liveDocuments.show(viewName);
  } else if (["inbound", "outbound", "transfer"].includes(viewName)) {
    setVisibleView("documentView");
    configureDocument(viewName);
  } else if (viewName === "count") {
    setVisibleView("countView");
    renderCountRows();
  } else if (viewName === "return") {
    setVisibleView("returnView");
    if (!document.querySelector("#returnRows tr")) {
      addReturnRow();
      addReturnRow();
    }
  } else if (viewName === "reports") {
    setVisibleView("reportsView");
    if (USE_DUMMY_DATA) renderReport();
    else liveReport.render();
  } else {
    setVisibleView("listView");
    activeList = viewName;
    currentPage = 1;
    configureList();
  }

  updateActiveNavigation();
  closeMobileMenu();
  closeCommandResults();
  if (updateHash) history.replaceState(null, "", `#${viewName}`);
  document.querySelector("#mainContent").focus({ preventScroll: true });
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function configureList() {
  if (!USE_DUMMY_DATA) {
    document.querySelector("#listTitle").textContent = "Danh sách sản phẩm";
    document.querySelector("#listDescription").textContent = "Danh mục sản phẩm hiện có.";
    renderList();
    return;
  }
  const config = listConfigs[activeList] || listConfigs.products;
  document.querySelector("#listTitle").textContent = config.title;
  document.querySelector("#listDescription").textContent = config.description;
  document.querySelector("#addRecordLabel").textContent = config.addLabel;
  elements.listSearch.value = "";
  elements.statusFilter.value = "";
  renderList();
}

function renderList() {
  if (!USE_DUMMY_DATA) {
    liveProducts.render(currentPage, elements.listSearch.value);
    return;
  }
  const config = listConfigs[activeList] || listConfigs.products;
  const query = elements.listSearch.value.trim().toLocaleLowerCase("vi");
  const selectedStatus = elements.statusFilter.value;
  const filtered = config.rows.filter((row) => {
    const matchesText = !query || row.join(" ").toLocaleLowerCase("vi").includes(query);
    const matchesStatus = !selectedStatus || row.at(-1) === selectedStatus;
    return matchesText && matchesStatus;
  });
  const pageCount = Math.max(1, Math.ceil(filtered.length / pageSize));
  currentPage = Math.min(currentPage, pageCount);
  const start = (currentPage - 1) * pageSize;
  const pageRows = filtered.slice(start, start + pageSize);

  elements.dataTable.querySelector("thead").innerHTML = `<tr>${config.columns.map((column) => `<th>${escapeHtml(column)}</th>`).join("")}<th class="action-cell">Mở</th></tr>`;
  elements.dataTable.querySelector("tbody").innerHTML = pageRows.map((row) => {
    const cells = row.map((cell, index) => {
      if (index === 0) return `<td><span class="cell-primary">${escapeHtml(cell)}</span></td>`;
      if (index === row.length - 1) return `<td><span class="status ${statusClass(cell)}">${escapeHtml(cell)}</span></td>`;
      const numeric = /₫|^\d+%$/.test(String(cell));
      return `<td class="${numeric ? "number-cell" : ""}">${escapeHtml(cell)}</td>`;
    }).join("");
    return `<tr>${cells}<td class="action-cell"><button class="row-action" type="button" data-row-action="open" aria-label="Mở ${escapeHtml(row[0])}">${icon("chevron")}</button></td></tr>`;
  }).join("");

  elements.listEmpty.hidden = filtered.length !== 0;
  elements.dataTable.hidden = filtered.length === 0;
  document.querySelector(".pagination").hidden = filtered.length === 0;
  const rangeStart = filtered.length ? start + 1 : 0;
  const rangeEnd = Math.min(start + pageSize, filtered.length);
  elements.recordRange.textContent = `Hiển thị ${rangeStart}–${rangeEnd} trong ${filtered.length} bản ghi`;
  elements.previousPage.disabled = currentPage === 1;
  elements.nextPage.disabled = currentPage === pageCount;
  elements.pageNumbers.innerHTML = Array.from({ length: pageCount }, (_, index) => {
    const page = index + 1;
    return `<button type="button" class="${page === currentPage ? "active" : ""}" data-page-number="${page}" aria-label="Trang ${page}" ${page === currentPage ? 'aria-current="page"' : ""}>${page}</button>`;
  }).join("");
}

function clearListFilters() {
  elements.listSearch.value = "";
  if (!USE_DUMMY_DATA) {
    currentPage = 1;
    renderList();
    return;
  }
  elements.statusFilter.value = "";
  document.querySelector("#dateFromFilter").value = "";
  document.querySelector("#dateToFilter").value = "";
  currentPage = 1;
  renderList();
}

function openRecordEditor() {
  if (!USE_DUMMY_DATA) {
    liveProducts.openEditor();
    return;
  }
  const config = listConfigs[activeList] || listConfigs.products;
  document.querySelector("#recordEditorTitle").textContent = config.addLabel;
  elements.recordForm.reset();
  elements.recordEditor.hidden = false;
  elements.editorOverlay.hidden = false;
  document.body.style.overflow = "hidden";
  window.setTimeout(() => document.querySelector("#recordCode").focus(), 0);
}

function closeRecordEditor() {
  elements.recordEditor.hidden = true;
  elements.editorOverlay.hidden = true;
  document.body.style.overflow = "";
}

function addListRecord(event) {
  if (!USE_DUMMY_DATA) {
    liveProducts.submit(event);
    return;
  }
  event.preventDefault();
  if (!elements.recordForm.checkValidity()) {
    elements.recordForm.reportValidity();
    return;
  }
  const config = listConfigs[activeList] || listConfigs.products;
  const code = document.querySelector("#recordCode").value.trim().toUpperCase();
  const name = document.querySelector("#recordName").value.trim();
  const category = document.querySelector("#recordCategory").value;
  const status = document.querySelector("#recordStatus").value;
  const row = Array.from({ length: config.columns.length }, () => "—");
  row[0] = code;
  row[1] = name;
  if (row.length > 2) row[2] = category;
  row[row.length - 1] = status;
  config.rows.unshift(row);
  closeRecordEditor();
  currentPage = 1;
  renderList();
  showToast(`Đã thêm ${code} vào dữ liệu demo.`);
}

function productOptions() {
  return ['<option value="">Chọn sản phẩm</option>']
    .concat(documentProducts.map(([code, name]) => `<option value="${code}">${code} · ${name}</option>`))
    .join("");
}

function addDocumentRow(statuses) {
  const modeStatuses = statuses || ({
    inbound: ["Chờ nhập", "Đã nhập", "Đã hủy"],
    outbound: ["Chờ xuất", "Đã xuất", "Đã hủy"],
    transfer: ["Chờ chuyển", "Đã chuyển", "Đã hủy"]
  }[activeView] || ["Chờ xử lý", "Hoàn tất", "Đã hủy"]);
  const row = document.createElement("tr");
  row.innerHTML = `
    <td class="row-number"></td>
    <td><select class="product-select" aria-label="Mã sản phẩm" required>${productOptions()}</select></td>
    <td><select class="location-select" aria-label="Vị trí" required><option value="">Chọn vị trí</option><option>A-01-03</option><option>A-02-01</option><option>B-04-02</option><option>L1-02-01</option><option>QA-01-01</option></select></td>
    <td><input class="quantity-input number-cell" type="number" min="1" step="1" value="1" aria-label="Số lượng" required></td>
    <td><input class="price-input number-cell" type="number" min="0" step="1000" value="0" aria-label="Đơn giá" required></td>
    <td><select class="line-status" aria-label="Trạng thái">${modeStatuses.map((status) => `<option>${status}</option>`).join("")}</select></td>
    <td class="action-cell"><button class="delete-row" type="button" aria-label="Xóa dòng">${icon("trash")}</button></td>`;
  elements.documentRows.append(row);
  updateDocumentRowNumbers();
}

function updateDocumentRowNumbers() {
  elements.documentRows.querySelectorAll("tr").forEach((row, index) => {
    row.querySelector(".row-number").textContent = String(index + 1);
  });
  updateDocumentSummary();
}

function updateDocumentSummary() {
  const rows = [...elements.documentRows.querySelectorAll("tr")];
  const summary = rows.reduce((value, row) => {
    const quantity = Number(row.querySelector(".quantity-input")?.value) || 0;
    const price = Number(row.querySelector(".price-input")?.value) || 0;
    value.quantity += quantity;
    value.total += quantity * price;
    return value;
  }, { quantity: 0, total: 0 });
  document.querySelector("#documentLineCount").textContent = String(rows.length);
  document.querySelector("#documentQuantity").textContent = new Intl.NumberFormat("vi-VN").format(summary.quantity);
  document.querySelector("#documentTotal").textContent = formatCurrency(summary.total);
}

function handleDocumentChange(event) {
  const row = event.target.closest("tr");
  if (row && event.target.matches(".product-select")) {
    const product = documentProducts.find(([code]) => code === event.target.value);
    if (product) row.querySelector(".price-input").value = String(product[2]);
  }
  updateDocumentSummary();
}

function submitDocument(event) {
  event.preventDefault();
  elements.documentError.hidden = true;
  if (!elements.documentForm.checkValidity()) {
    elements.documentForm.reportValidity();
    return;
  }
  const rows = [...elements.documentRows.querySelectorAll("tr")];
  if (!rows.length || rows.some((row) => !row.querySelector(".product-select").value || !row.querySelector(".location-select").value)) {
    elements.documentError.querySelector("span").textContent = "Mỗi dòng cần chọn sản phẩm và vị trí trước khi tạo phiếu.";
    elements.documentError.hidden = false;
    return;
  }
  const payload = {
    type: activeView,
    code: document.querySelector("#documentCodeInput").value,
    date: document.querySelector("#documentDate").value,
    partner: document.querySelector("#documentPartner").value,
    employee: document.querySelector("#documentEmployee").value,
    note: document.querySelector("#documentNote").value.trim(),
    lines: rows.map((row) => ({
      productCode: row.querySelector(".product-select").value,
      location: row.querySelector(".location-select").value,
      quantity: Number(row.querySelector(".quantity-input").value),
      unitPrice: Number(row.querySelector(".price-input").value),
      status: row.querySelector(".line-status").value
    }))
  };
  console.info("Payload chứng từ demo:", payload);
  showToast("Phiếu hợp lệ. Payload demo đã được ghi vào Console; backend sẽ kiểm tra lại khi tích hợp.");
}

function renderInventory(filter = "") {
  const query = filter.trim().toLocaleLowerCase("vi");
  const rows = inventoryRows.filter((row) => !query || row.join(" ").toLocaleLowerCase("vi").includes(query));
  document.querySelector("#inventoryTable tbody").innerHTML = rows.map((row) => `
    <tr>
      <td><span class="cell-primary">${escapeHtml(row[0])}</span></td>
      <td><span class="cell-primary">${escapeHtml(row[1])}</span></td>
      <td>${escapeHtml(row[2])}</td>
      <td>${escapeHtml(row[3])}</td>
      <td class="number-cell">${row[4]}</td>
      <td class="number-cell">${row[5]}</td>
      <td class="number-cell"><strong>${row[6]}</strong></td>
      <td><span class="status ${statusClass(row[7])}">${escapeHtml(row[7])}</span></td>
    </tr>`).join("");
}

function renderCountRows() {
  document.querySelector("#countTable tbody").innerHTML = countRows.map((row, index) => `
    <tr>
      <td><span class="cell-primary">${escapeHtml(row[0])}</span><span class="cell-secondary">${escapeHtml(row[1])}</span></td>
      <td>${escapeHtml(row[2])}</td>
      <td class="number-cell system-count">${row[3]}</td>
      <td class="number-cell"><input class="actual-count" type="number" min="0" step="1" value="${row[4]}" aria-label="Số lượng thực tế dòng ${index + 1}"></td>
      <td class="variance">0</td>
      <td><input class="count-note" type="text" aria-label="Ghi chú dòng ${index + 1}" placeholder="Ghi nhận nguyên nhân..."></td>
    </tr>`).join("");
  updateCountVariance();
}

function updateCountVariance() {
  let surplus = 0;
  let shortage = 0;
  let changedRows = 0;
  document.querySelectorAll("#countTable tbody tr").forEach((row) => {
    const systemValue = Number(row.querySelector(".system-count").textContent);
    const actualValue = Number(row.querySelector(".actual-count").value);
    const variance = actualValue - systemValue;
    const cell = row.querySelector(".variance");
    cell.textContent = variance > 0 ? `+${variance}` : String(variance);
    cell.className = `variance ${variance > 0 ? "positive" : variance < 0 ? "negative" : ""}`;
    if (variance > 0) surplus += variance;
    if (variance < 0) shortage += Math.abs(variance);
    if (variance !== 0) changedRows += 1;
  });
  document.querySelector("#surplusCount").textContent = String(surplus);
  document.querySelector("#shortageCount").textContent = String(shortage);
  document.querySelector("#varianceRows").textContent = `${changedRows} dòng`;
}

function addReturnRow() {
  const rowIndex = document.querySelectorAll("#returnRows tr").length + 1;
  const row = document.createElement("tr");
  row.innerHTML = `
    <td class="row-number">${rowIndex}</td>
    <td><select class="product-select" aria-label="Sản phẩm trả" required>${productOptions()}</select></td>
    <td class="number-cell exported-quantity">24</td>
    <td><input class="return-quantity number-cell" type="number" min="1" max="24" value="1" aria-label="Số lượng trả" required></td>
    <td><select class="return-condition" aria-label="Tình trạng hàng trả"><option value="good">Tốt</option><option value="damaged">Hư hỏng</option></select></td>
    <td><select class="return-location" aria-label="Vị trí nhận"><option>A-01-03</option><option>B-04-02</option><option>QA-01-01</option></select></td>
    <td class="action-cell"><button class="delete-row" type="button" aria-label="Xóa dòng">${icon("trash")}</button></td>`;
  document.querySelector("#returnRows").append(row);
}

function updateReturnCondition(select) {
  const row = select.closest("tr");
  const location = row.querySelector(".return-location");
  const damaged = select.value === "damaged";
  select.classList.toggle("damaged-select", damaged);
  location.value = damaged ? "QA-01-01" : "A-01-03";
}

function renderReport() {
  document.querySelector("#reportRows").innerHTML = reportData.map((row) => `
    <tr><td><strong>${row[0]}</strong></td><td>${row[1]}</td><td class="number-cell">${row[2]}</td><td class="number-cell">${row[3]}</td><td class="number-cell">${row[4]}</td><td class="number-cell"><strong>${row[5]}</strong></td><td>${row[6]}</td></tr>`).join("");
}

function openCommandResults(query) {
  if (!USE_DUMMY_DATA) return;
  const normalized = query.trim().toLocaleLowerCase("vi");
  if (!normalized) {
    closeCommandResults();
    return;
  }
  const allowedPages = new Set(roleProfiles[activeRole].pages);
  const matches = navDefinition.flatMap((group) => group.items)
    .filter((item) => allowedPages.has(item.id) && item.label.toLocaleLowerCase("vi").includes(normalized))
    .slice(0, 6);
  elements.commandResults.innerHTML = matches.length
    ? matches.map((item) => `<button class="command-item" type="button" data-command-view="${item.id}"><span><strong>${escapeHtml(item.label)}</strong><small>${escapeHtml(pageMeta[item.id]?.[1] || "")}</small></span>${icon("arrow")}</button>`).join("")
    : '<div class="empty-state"><h3>Không có kết quả</h3><p>Thử tên chức năng khác.</p></div>';
  elements.commandResults.hidden = false;
}

function closeCommandResults() {
  elements.commandResults.hidden = true;
}

document.addEventListener("click", (event) => {
  const viewTrigger = event.target.closest("[data-view], [data-view-link]");
  if (viewTrigger) {
    event.preventDefault();
    showView(viewTrigger.dataset.view || viewTrigger.dataset.viewLink);
    return;
  }
  if (!event.target.closest(".global-search, #commandResults")) closeCommandResults();
});

elements.mobileMenuButton.addEventListener("click", () => {
  const open = elements.sidebar.classList.toggle("open");
  elements.sidebarOverlay.hidden = !open;
  elements.mobileMenuButton.setAttribute("aria-expanded", String(open));
});
document.querySelector("#sidebarClose").addEventListener("click", closeMobileMenu);
elements.sidebarOverlay.addEventListener("click", closeMobileMenu);
elements.roleSwitcher.addEventListener("change", (event) => applyRole(event.target.value));

document.querySelector("[data-quick-action]").addEventListener("click", () => showView(roleProfiles[activeRole].primaryView));
document.querySelector("#helpButton").addEventListener("click", () => showToast("Mẹo: dùng Ctrl + K để tìm nhanh chức năng."));
document.querySelector("#notificationButton").addEventListener("click", () => showToast("3 thông báo demo: 2 lô sắp hết hạn và 1 phiếu chờ duyệt."));
document.querySelector("#exportButton").addEventListener("click", () => showToast("Đã chuẩn bị dữ liệu demo để xuất. Chức năng tải file sẽ nối với API."));

elements.listSearch.addEventListener("input", () => {
  currentPage = 1;
  renderList();
});
elements.statusFilter.addEventListener("change", () => {
  currentPage = 1;
  renderList();
});
document.querySelector("#clearFiltersButton").addEventListener("click", clearListFilters);
document.querySelector("[data-clear-filters]").addEventListener("click", clearListFilters);
elements.previousPage.addEventListener("click", () => {
  currentPage = Math.max(1, currentPage - 1);
  renderList();
});
elements.nextPage.addEventListener("click", () => {
  currentPage += 1;
  renderList();
});
elements.pageNumbers.addEventListener("click", (event) => {
  const button = event.target.closest("[data-page-number]");
  if (!button) return;
  currentPage = Number(button.dataset.pageNumber);
  renderList();
});
elements.dataTable.addEventListener("click", (event) => {
  const button = event.target.closest("[data-row-action]");
  if (!button) return;
  if (USE_DUMMY_DATA) showToast("Đã mở bảng thông tin chi tiết bản ghi demo.");
  else liveProducts.openEditor(button.dataset.code);
});

document.querySelector("#addRecordButton").addEventListener("click", openRecordEditor);
document.querySelector("#closeRecordEditor").addEventListener("click", closeRecordEditor);
document.querySelector("#cancelRecordButton").addEventListener("click", closeRecordEditor);
elements.editorOverlay.addEventListener("click", closeRecordEditor);
elements.recordForm.addEventListener("submit", addListRecord);

document.querySelector("#addDocumentRow").addEventListener("click", () => addDocumentRow());
elements.documentRows.addEventListener("click", (event) => {
  const button = event.target.closest(".delete-row");
  if (!button) return;
  button.closest("tr").remove();
  updateDocumentRowNumbers();
});
elements.documentRows.addEventListener("input", updateDocumentSummary);
elements.documentRows.addEventListener("change", handleDocumentChange);
elements.documentForm.addEventListener("submit", submitDocument);
document.querySelector("#saveDraftButton").addEventListener("click", () => showToast("Đã lưu bản nháp trên giao diện demo."));

if (USE_DUMMY_DATA) {
  document.querySelector("#inventorySearch").addEventListener("input", (event) => renderInventory(event.target.value));
  document.querySelector("#refreshInventoryButton").addEventListener("click", (event) => {
    const button = event.currentTarget;
    button.disabled = true;
    button.textContent = "Đang làm mới...";
    window.setTimeout(() => {
      button.disabled = false;
      button.textContent = "Làm mới dữ liệu";
      showToast("Dữ liệu tồn kho demo đã được làm mới.");
    }, 650);
  });
}

document.querySelector("#countTable").addEventListener("input", (event) => {
  if (event.target.matches(".actual-count")) updateCountVariance();
});
document.querySelector("#saveCountButton").addEventListener("click", () => showToast("Đã lưu kết quả đếm demo."));
document.querySelector("#submitCountButton").addEventListener("click", () => showToast("Đã gửi phiếu kiểm kê demo để duyệt điều chỉnh."));

document.querySelector("#addReturnRow").addEventListener("click", addReturnRow);
document.querySelector("#returnRows").addEventListener("click", (event) => {
  const button = event.target.closest(".delete-row");
  if (!button) return;
  button.closest("tr").remove();
  document.querySelectorAll("#returnRows .row-number").forEach((cell, index) => {
    cell.textContent = String(index + 1);
  });
});
document.querySelector("#returnRows").addEventListener("change", (event) => {
  if (event.target.matches(".return-condition")) updateReturnCondition(event.target);
});
document.querySelector("#returnForm").addEventListener("submit", (event) => {
  event.preventDefault();
  if (!event.currentTarget.checkValidity()) {
    event.currentTarget.reportValidity();
    return;
  }
  showToast("Phiếu trả hợp lệ. Backend sẽ kiểm tra lượng đã xuất trước khi hoàn tất.");
});

if (USE_DUMMY_DATA) document.querySelector("#runReportButton").addEventListener("click", (event) => {
  const button = event.currentTarget;
  button.disabled = true;
  button.textContent = "Đang tổng hợp...";
  window.setTimeout(() => {
    button.disabled = false;
    button.textContent = "Chạy báo cáo";
    renderReport();
    showToast("Báo cáo demo đã được cập nhật.");
  }, 650);
});

const globalSearch = document.querySelector("#globalSearch");
globalSearch.addEventListener("input", (event) => openCommandResults(event.target.value));
elements.commandResults.addEventListener("click", (event) => {
  const button = event.target.closest("[data-command-view]");
  if (!button) return;
  globalSearch.value = "";
  showView(button.dataset.commandView);
});

document.addEventListener("keydown", (event) => {
  if ((event.ctrlKey || event.metaKey) && event.key.toLocaleLowerCase() === "k") {
    event.preventDefault();
    globalSearch.focus();
  }
  if (event.key === "Escape") {
    if (!elements.recordEditor.hidden) closeRecordEditor();
    else if (elements.sidebar.classList.contains("open")) closeMobileMenu();
    else closeCommandResults();
  }
});

const today = localDateValue();
document.querySelector("#currentDate").textContent = new Intl.DateTimeFormat("vi-VN", {
  weekday: "long",
  day: "2-digit",
  month: "2-digit",
  year: "numeric"
}).format(new Date());
["documentDate", "countDate", "returnDate", "reportTo"].forEach((id) => {
  document.querySelector(`#${id}`).value = today;
});
const reportFrom = new Date();
reportFrom.setDate(reportFrom.getDate() - 30);
document.querySelector("#reportFrom").value = localDateValue(reportFrom);

if (!USE_DUMMY_DATA) {
  document.querySelector("#demoRoleSwitcher").hidden = true;
  document.querySelector("#notificationButton").hidden = true;
  document.querySelector("#exportButton").hidden = true;
  document.querySelector(".global-search").hidden = true;
  document.querySelector(".location-context").hidden = true;
  document.querySelector("#listView .filter-row").hidden = true;
  document.querySelector("#dataStatus").textContent = "Dữ liệu API";
  document.querySelector("#dataStatusDetail").textContent = "Danh mục và nghiệp vụ kho";
  const modeLink = document.querySelector("#apiModeLink");
  modeLink.href = "?mode=demo#dashboard";
  modeLink.firstChild.textContent = "Dữ liệu demo ";
}
renderNavigation();
if (USE_DUMMY_DATA) {
  renderInventory();
  renderCountRows();
  renderReport();
  const initialHash = window.location.hash.slice(1);
  showView(roleProfiles[activeRole].pages.includes(initialHash) ? initialHash : "dashboard", false);
} else {
  liveInventory.start();
  liveReport.start();
  liveDocuments.start();
  const initialHash = window.location.hash.slice(1);
  showView(["products", "inventory", "reports", "inbound", "outbound"].includes(initialHash) ? initialHash : "products", false);
  liveProducts.start();
}

window.warehouseUi = {
  showView,
  applyRole,
  renderInventory,
  apiBaseUrl: API_BASE_URL,
  usingDummyData: USE_DUMMY_DATA
};
