import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir } from "node:fs/promises";
import { documentScreens } from "../apps/web/data/document-models.js";
import { masterScreens } from "../apps/web/features/live-masters.js";
import { masterResources } from "../apps/web/data/master-api.js";
import { apiPagesForRole } from "../apps/web/core/navigation.js";

// Optional browser gate: Playwright is supplied by the caller, not a web dependency.
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_PATH || "playwright");
const base = process.env.WEB_TEST_URL || "http://127.0.0.1:5174";
const output = process.env.WEB_TEST_OUTPUT;
if (output) await mkdir(output, { recursive: true });
const browser = await chromium.launch({ headless: true, ...(process.env.PLAYWRIGHT_CHANNEL ? { channel: process.env.PLAYWRIGHT_CHANNEL } : {}) });
const calls = [], errors = [];
const documentsByPath = { "phieu-nhap": "inbound", "phieu-xuat": "outbound", "phieu-chuyen": "transfer", "phieu-kiem-ke": "count", "phieu-tra-hang": "return" };
const fixtureLines = {
  inbound: [{ maSanPham: "SP0001", soLuong: 2, donGiaNhap: 12 }, { maSanPham: "SP0002", soLuong: 3, donGiaNhap: 15 }],
  outbound: [{ maLo: "LO0001", maViTri: "VT0001", soLuong: 2, donGiaXuat: 20 }],
  transfer: [{ maLo: "LO0001", maViTriNguon: "VT0001", maViTriDich: "VT0002", soLuong: 1 }],
  count: [{ maLo: "LO0001", soLuongHeThong: 5, soLuongThucTe: null, lyDoChenhLech: null }],
  return: [{ maLo: "LO0001", maViTri: "VT0001", soLuong: 1, tinhTrang: "Tốt" }]
};
const ids = { inbound: "PN0001", outbound: "PX0001", transfer: "PC0001", count: "KK0001", return: "TH0001" };
const fixture = (kind, body = {}) => ({ [documentScreens[kind].code]: ids[kind], [documentScreens[kind].date]: "2026-10-21T12:00:00Z",
  [documentScreens[kind].partner || "unused"]: kind === "count" ? "VT0001" : kind === "return" ? "PX0001" : "NCC001",
  maNhanVien: "NV0001", trangThai: "NHAP", ghiChu: null, chiTiet: structuredClone(fixtureLines[kind]), ...body });
const pageResult = (items) => ({ items, page: 0, size: 20, totalElements: items.length, totalPages: items.length ? 1 : 0 });

async function session(role, width = 1440) {
  const context = await browser.newContext({ viewport: { width, height: 980 } });
  const page = await context.newPage();
  page.on("pageerror", (error) => errors.push(error.message));
  const store = Object.fromEntries(Object.keys(ids).map((kind) => [kind, fixture(kind)]));
  if (role === "KETOAN") store.inbound.trangThai = "DA_HOAN_THANH";
  const reconciled = new Map();
  let loggedIn = true;
  await page.route("http://127.0.0.1:8080/api/**", async (route) => {
    const request = route.request(), url = new URL(request.url()), path = url.pathname.replace("/api/", "").split("/");
    const method = request.method();
    const headers = { "Access-Control-Allow-Origin": new URL(base).origin, "Access-Control-Allow-Credentials": "true",
      "Access-Control-Allow-Headers": "Content-Type,X-CSRF-TOKEN", "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS" };
    if (method === "OPTIONS") return route.fulfill({ status: 204, headers });
    const body = request.postDataJSON();
    calls.push({ role, path: url.pathname, method, body });
    const reply = (data, status = 200) => route.fulfill({ status, headers, contentType: "application/json", ...(status === 204 ? {} : { body: JSON.stringify(data) }) });
    if (path[0] === "auth") {
      if (path[1] === "csrf") return reply({ token: "test-csrf", headerName: "X-CSRF-TOKEN" });
      if (path[1] === "dang-xuat") { loggedIn = false; return reply(null, 204); }
      if (!loggedIn) return reply({ message: "Cần đăng nhập" }, 401);
      return reply({ role, maTaiKhoan: "TK0001", maNhanVien: "NV0001", tenNhanVien: "Nguyễn Trung" });
    }
    if (path[0] === "quyen-han") return reply(["ADMIN", "QLKHO", "NVKHO", "KETOAN"].map((r) => ({ role: r, tenVaiTro: r, permissions: [
      { tenChucNang: "Chứng từ", xem: true, tao: ["QLKHO", "NVKHO"].includes(r), sua: false, xoaHoacHuy: false, hoanTat: r === "QLKHO" }
    ] })));
    if (path[0] === "doi-soat-gia-tri") {
      const key = `${path[1]}/${path[2]}`;
      if (method === "GET") return reconciled.has(key) ? reply(reconciled.get(key)) : reply({ code: "RECONCILIATION_NOT_FOUND", message: "Chưa đối soát" }, 404);
      const data = { loaiChungTu: path[1], maChungTu: path[2], giaTriChungTu: 39, giaTriDoiSoat: body.giaTriDoiSoat,
        chenhLech: body.giaTriDoiSoat - 39, trangThai: body.giaTriDoiSoat === 39 ? "KHOP" : "CHENH_LECH",
        ghiChu: body.ghiChu, maTaiKhoanKeToan: "TK0004", thoiGian: "2026-10-22T00:00:00Z" };
      reconciled.set(key, data);
      return reply(data);
    }
    const kind = documentsByPath[path[0]];
    if (kind) {
      if (path[2] === "goi-y-fefo") return reply({ phanBo: [{ maLo: "LO0001", maViTri: "VT0001", soLuong: 2 }], soLuongThieu: 0 });
      if (path[2] === "hoan-tat") store[kind].trangThai = "DA_HOAN_THANH";
      else if (path[2] === "huy") store[kind].trangThai = "DA_HUY";
      else if (path[2] === "chi-tiet") Object.assign(store[kind].chiTiet[0], body);
      else if (["POST", "PUT"].includes(method)) store[kind] = fixture(kind, body);
      return reply(path.length === 1 && method === "GET" ? pageResult([store[kind]]) : store[kind], method === "POST" && path.length === 1 ? 201 : 200);
    }
    const master = Object.entries(masterResources).find(([, p]) => p === path[0]);
    if (master) {
      if (path[2] === "san-pham") return reply(method === "GET" ? ["SP0001"] : null, method === "DELETE" ? 204 : method === "POST" ? 201 : 200);
      if (method === "DELETE") return reply(null, 204);
      const item = Object.fromEntries(masterScreens[master[0]].fields.map((f, index) => [f.key, f.options?.[0] || (f.type === "number" ? 100 : index === 0 ? "AB0001" : "Kho trung tâm")]));
      return reply(path.length > 1 || method !== "GET" ? { ...item, ...body } : pageResult([item]), method === "POST" ? 201 : 200);
    }
    return reply(pageResult([]));
  });
  await page.goto(`${base}/?mode=api#${role === "ADMIN" ? "permissions" : "dashboard"}`);
  await page.waitForFunction((r) => document.querySelector("#userRole").textContent === r, role);
  return { page, context };
}

async function go(page, name) {
  await page.evaluate((n) => window.warehouseUi.showView(n), name);
  await page.waitForFunction((n) => document.querySelector("#pageTitle").textContent === n, {
    warehouses: "Danh sách kho", zones: "Khu vực kho", locations: "Vị trí trong kho", categories: "Loại sản phẩm", units: "Đơn vị tính",
    suppliers: "Nhà cung cấp", recipients: "Đối tác nhận hàng", inbound: "Phiếu nhập kho", outbound: "Phiếu xuất kho", transfer: "Phiếu chuyển kho",
    count: "Phiếu kiểm kê", return: "Phiếu trả hàng", permissions: "Quyền hạn", accounts: "Tài khoản đăng nhập", expiry: "Lô sắp hết hạn",
    discrepancies: "Chênh lệch kiểm kê", audit: "Nhật ký thao tác"
  }[name]);
}
async function loadDocument(page, kind) {
  await go(page, kind);
  await page.locator(`[data-load="${ids[kind]}"]`).click();
  await page.waitForFunction(() => !document.querySelector("#liveDocumentView").inert);
  assert.match(await page.locator("#liveDocState").textContent(), /NHAP|DA_HOAN_THANH/);
}

try {
  const { page: admin, context: adminContext } = await session("ADMIN");
  await admin.locator("#livePermissionsView select").selectOption("QLKHO");
  assert.match(await admin.locator("#livePermissionsView tbody").textContent(), /Có/);
  if (output) await admin.screenshot({ path: `${output}/admin-permissions-desktop.png`, fullPage: true });
  await admin.locator("[data-accounts]").click();
  await admin.locator("#identityAdd").click();
  assert.equal(await admin.locator('dialog[open] [name="role"] option').count(), 4);
  await admin.locator("#identityClose").click();
  assert.deepEqual(await admin.locator("#navGroups [data-view]").evaluateAll((items) => items.map((item) => item.dataset.view)),
    ["dashboard", "employees", "accounts", "permissions"]);
  await admin.evaluate(() => window.warehouseUi.showView("dashboard"));
  await admin.locator(".live-metric").first().waitFor();
  if (output) await admin.screenshot({ path: `${output}/admin-dashboard-desktop.png`, fullPage: true });
  await adminContext.close();

  const { page: manager, context: managerContext } = await session("QLKHO");
  for (const key of Object.keys(masterScreens)) {
    await go(manager, key);
    await manager.locator("#liveMasterView [data-open]").first().click();
    const dialog = manager.locator("dialog[open]");
    await dialog.waitFor();
    assert.equal(await dialog.locator("input, select").count() >= 2, true);
    if (key === "zones") assert.equal(await dialog.locator('[name="maKho"]').isDisabled(), true);
    if (key === "locations") assert.equal(await dialog.locator('[name="sucChua"]').isDisabled(), false);
    if (masterScreens[key].mapping) await dialog.locator("[data-mappings] li").first().waitFor();
    await dialog.locator("[data-close]").click();
  }
  await go(manager, "warehouses");
  await manager.locator("#liveMasterView [data-add]").click();
  await manager.locator('dialog[open] [name="maKho"]').fill("KHO002");
  await manager.locator('dialog[open] [name="tenKho"]').fill("Kho mới");
  await manager.locator('dialog[open] button[type="submit"]').click();
  await manager.locator("dialog[open]").waitFor({ state: "hidden" });
  assert.ok(calls.some((c) => c.method === "POST" && c.path === "/api/kho" && c.body.maKho === "KHO002"));

  for (const kind of Object.keys(ids)) {
    await loadDocument(manager, kind);
    if (kind === "inbound") {
      assert.equal(await manager.locator("#liveDocRows tr").count(), 2);
      for (const input of await manager.locator('#liveDocAllocations [name="maViTri"]').all()) await input.fill("VT0001");
    }
    if (kind === "count") {
      await manager.locator('#liveDocRows [name="soLuongThucTe"]').fill("4");
      await manager.locator('#liveDocRows [name="lyDoChenhLech"]').fill("Hao hụt");
    }
    if (kind === "transfer" && output) await manager.screenshot({ path: `${output}/manager-transfer-desktop.png`, fullPage: true });
    await manager.locator("#liveDocComplete").click();
    await manager.waitForFunction(() => document.querySelector("#liveDocState").textContent.includes("DA_HOAN_THANH"));
    assert.equal(await manager.locator("#liveDocComplete").isVisible(), false);
    assert.equal(await manager.locator("#liveDocSave").isVisible(), false);
  }
  assert.ok(calls.some((c) => c.path === "/api/phieu-nhap/PN0001/hoan-tat" && c.body.phanBo.length === 2));
  assert.ok(calls.some((c) => c.path === "/api/phieu-kiem-ke/KK0001/chi-tiet/LO0001" && c.body.soLuongThucTe === 4 && !Object.hasOwn(c.body, "soLuongHeThong")));
  for (const name of ["expiry", "discrepancies"]) await go(manager, name);
  await managerContext.close();

  for (const role of ["NVKHO", "KETOAN"]) {
    const { page, context } = await session(role);
    assert.equal(await page.locator('#navGroups [data-view="permissions"]').count(), 0);
    for (const kind of (role === "NVKHO" ? ["inbound", "outbound"] : Object.keys(ids))) {
      await loadDocument(page, kind);
      assert.equal(await page.locator("#liveDocComplete").isVisible(), false);
      assert.equal(await page.locator("#liveDocSave").isVisible(), role === "NVKHO");
      if (role === "KETOAN" && kind === "inbound") {
        await page.locator('#liveDocReconciliationForm [name="giaTriDoiSoat"]').fill("39");
        await page.locator("#liveDocReconciliationForm button").click();
        await page.getByText(/Đã khớp · Giá trị phiếu/).waitFor();
      }
    }
    assert.equal(apiPagesForRole(role).includes("transfer"), role === "KETOAN");
    if (role === "NVKHO") assert.deepEqual(await page.locator("#navGroups [data-view]").evaluateAll((items) => items.map((item) => item.dataset.view)),
      ["dashboard", "inventory", "inbound", "outbound"]);
    if (role === "KETOAN") assert.ok(calls.some((c) => c.role === "KETOAN" && c.method === "POST" && c.path === "/api/doi-soat-gia-tri/NHAP/PN0001"));
    await context.close();
  }
  for (const [role, target] of [["ADMIN", "dashboard"], ["QLKHO", "transfer"]]) {
    const { page, context } = await session(role, 390);
    if (target === "dashboard") {
      await page.evaluate(() => window.warehouseUi.showView("dashboard"));
      await page.locator(".live-metric").first().waitFor();
    } else await go(page, target);
    if (target === "dashboard") await page.locator(".live-metric").first().waitFor();
    else await page.locator("#liveDocListRows tr").waitFor();
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth), true, `${role}: viewport overflow`);
    if (output) await page.screenshot({ path: `${output}/${role.toLowerCase()}-${target}-mobile.png`, fullPage: true });
    await context.close();
  }
  assert.deepEqual(errors, []);
  console.log(`Browser API parity passed: four roles, seven master screens, five document completions, role dashboards, desktop/mobile; ${calls.length} mocked HTTP requests; no page errors.`);
} finally { await browser.close(); }
