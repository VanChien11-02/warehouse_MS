import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir } from "node:fs/promises";

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_PATH || "playwright");
const base = process.env.WEB_TEST_URL || "http://127.0.0.1:5174";
const api = process.env.API_TEST_URL || "http://127.0.0.1:8080/api";
const username = process.env.INBOUND_TEST_USERNAME;
const password = process.env.INBOUND_TEST_PASSWORD;
const product = process.env.INBOUND_TEST_PRODUCT || "SP0001";
const supplier = process.env.INBOUND_TEST_SUPPLIER || "NCC001";
const firstPosition = process.env.INBOUND_TEST_POSITION_A || "VT0001";
const secondPosition = process.env.INBOUND_TEST_POSITION_B || "VT0002";
const badPosition = process.env.INBOUND_TEST_BAD_POSITION || "VT0004";
if (!username || !password) throw new Error("Set INBOUND_TEST_USERNAME/PASSWORD for a QLKHO account. Use disposable fixtures with free capacity.");
const output = process.env.WEB_TEST_OUTPUT;
if (output) await mkdir(output, { recursive: true });
const browser = await chromium.launch({ headless: true,
  ...(process.env.PLAYWRIGHT_CHANNEL ? { channel: process.env.PLAYWRIGHT_CHANNEL } : {}) });
const errors = [], createdDocuments = [];
try {
  for (const width of [1440, 390]) {
    const context = await browser.newContext({ viewport: { width, height: 980 } });
    try {
      const page = await context.newPage();
      page.on("pageerror", (error) => errors.push(error.message));
      await page.goto(`${base}/?mode=api#inbound`);
      await page.locator('#loginForm [name="tenTaiKhoan"]').fill(username);
      await page.locator('#loginForm [name="matKhau"]').fill(password);
      await page.locator('#loginForm button[type="submit"]').click();
      await page.locator("#loginDialog").waitFor({ state: "hidden" });
      await page.goto(`${base}/?mode=api#inbound`);
      await page.locator("#liveDocNew").click();
      assert.equal(await page.locator(".trigger-practice").count(), 0);
      assert.equal(await page.getByText("Thực hành trigger nhập kho").count(), 0);
      await page.waitForFunction((code) => !!document.querySelector(`#liveDocPartner option[value="${code}"]`), supplier);
      await page.locator("#liveDocPartner").selectOption(supplier);
      const line = page.locator("#liveDocRows tr").first();
      await line.locator('[name="maSanPham"]').selectOption(product);
      await line.locator('[name="soLuong"]').fill("10");
      await line.locator('[name="donGiaNhap"]').fill("12500");
      await page.locator("#liveDocNote").fill("Automated inbound rollback verification");
      const created = page.waitForResponse((response) => response.url() === `${api}/phieu-nhap` && response.request().method() === "POST");
      await page.locator("#liveDocSave").click();
      const createResponse = await created;
      assert.equal(createResponse.status(), 201);
      const document = await createResponse.json();
      createdDocuments.push(document.maPhieuNhap);
      await page.locator("#liveDocMessage").getByText("Đã lưu phiếu nháp.", { exact: true }).waitFor();
      const historyForReceipt = async (extra = {}) => {
        const params = new URLSearchParams({ maPhieuNhap: document.maPhieuNhap, ...extra });
        const response = await context.request.get(`${api}/phieu-nhap/lich-su?${params}`);
        assert.equal(response.status(), 200);
        return response.json();
      };
      assert.equal((await historyForReceipt()).totalElements, 0, "draft must not appear in history");
      const parts = page.locator("#liveDocAllocations tr");
      await page.locator("#liveDocAddAllocation").click();
      await parts.first().locator('[name="maSanPham"]').selectOption(product);
      await parts.first().locator('[name="maViTri"]').selectOption(firstPosition);
      await parts.first().locator('[name="soLuong"]').fill("6");
      await page.locator("#liveDocAddAllocation").click();
      await parts.nth(1).locator('[name="maSanPham"]').selectOption(product);
      await parts.nth(1).locator('[name="maViTri"]').selectOption(secondPosition);
      await parts.nth(1).locator('[name="soLuong"]').fill("5");
      const complete = async (status, expectedCode) => {
        const responsePromise = page.waitForResponse((response) => response.url() === `${api}/phieu-nhap/${document.maPhieuNhap}/hoan-tat` && response.request().method() === "POST");
        await page.locator("#liveDocComplete").click();
        const response = await responsePromise;
        assert.equal(response.status(), status);
        const result = await response.json();
        if (expectedCode) assert.equal(result.code, expectedCode);
        await page.waitForFunction(() => !document.querySelector("#liveDocumentView").inert);
        return result;
      };
      const stock = async () => {
        const response = await context.request.get(`${api}/ton-kho?maSanPham=${product}&size=100`);
        assert.equal(response.status(), 200);
        return (await response.json()).items;
      };
      const baseline = (await stock()).reduce((sum, row) => sum + row.soLuongTon, 0);
      const assertDraftUnchanged = async () => {
        const response = await context.request.get(`${api}/phieu-nhap/${document.maPhieuNhap}`);
        assert.equal((await response.json()).trangThai, "NHAP");
        assert.equal((await stock()).reduce((sum, row) => sum + row.soLuongTon, 0), baseline);
        assert.equal((await historyForReceipt()).totalElements, 0, "failed posting must not appear in history");
      };
      await complete(422, "ALLOCATION_EXCEEDS_LINE");
      await assertDraftUnchanged();
      await page.getByText("Tổng số lượng phân bổ vượt số lượng nhập.", { exact: false }).waitFor();
      assert.equal(await parts.nth(1).locator('[name="soLuong"]').inputValue(), "5");
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true, `overflow at ${width}`);
      if (output) {
        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({ path: `${output}/inbound-overallocation-${width}.png`, fullPage: true });
      }
      await parts.nth(1).locator('[name="soLuong"]').fill("3");
      await complete(422, "ALLOCATION_INCOMPLETE");
      await assertDraftUnchanged();
      await parts.nth(1).locator('[name="soLuong"]').fill("4");
      await parts.nth(1).locator('[name="maViTri"]').selectOption(badPosition);
      await complete(422, "INCOMPATIBLE_STORAGE");
      await assertDraftUnchanged();
      await parts.nth(1).locator('[name="maViTri"]').selectOption(secondPosition);
      await complete(200);
      await page.getByText("Đã hoàn tất và ghi sổ.", { exact: true }).waitFor();
      assert.equal(await page.locator("#liveDocComplete").isVisible(), false);
      const currentStock = await stock();
      assert.equal(currentStock.reduce((sum, row) => sum + row.soLuongTon, 0), baseline + 10);
      assert.deepEqual(currentStock.filter((row) => row.maPhieuNhap === document.maPhieuNhap).map((row) => row.soLuongTon).sort(), [4, 6]);
      const csrf = await (await context.request.get(`${api}/auth/csrf`)).json();
      const repeated = await context.request.post(`${api}/phieu-nhap/${document.maPhieuNhap}/hoan-tat`, {
        headers: { [csrf.headerName]: csrf.token },
        data: { phanBo: [{ maSanPham: product, maViTri: firstPosition, soLuong: 10 }] }
      });
      assert.equal(repeated.status(), 409);
      assert.equal((await repeated.json()).code, "INBOUND_NOT_DRAFT");
      assert.equal((await stock()).reduce((sum, row) => sum + row.soLuongTon, 0), baseline + 10);

      const history = await historyForReceipt({ maSanPham: product, maNhaCungCap: supplier });
      assert.equal(history.totalElements, 2);
      assert.deepEqual(history.items.map((row) => row.soLuongNhap).sort(), [4, 6]);
      assert.deepEqual(history.items.map((row) => row.giaTriNhap).sort((a, b) => a - b), [50000, 75000]);
      const utcDay = history.items[0].ngayHoanTat.slice(0, 10);
      assert.equal((await historyForReceipt({ tuNgay: utcDay, denNgay: utcDay })).totalElements, 2);
      assert.equal((await historyForReceipt({ maSanPham: "ZZ9999" })).totalElements, 0);
      const firstPage = await historyForReceipt({ size: 1, page: 0 });
      const secondPage = await historyForReceipt({ size: 1, page: 1 });
      assert.equal(firstPage.totalPages, 2);
      assert.notEqual(firstPage.items[0].maLo, secondPage.items[0].maLo);

      await page.locator("#liveDocTabHistory").click();
      await page.waitForFunction(() => document.querySelector("#liveDocHistory").getAttribute("aria-busy") === "false");
      const historyFilters = page.locator("#inboundHistoryFilters");
      await historyFilters.locator('[name="maPhieuNhap"]').fill(document.maPhieuNhap);
      await historyFilters.getByRole("button", { name: "Tra cứu", exact: true }).click();
      await page.waitForFunction(() => document.querySelector("#inboundHistoryRows").rows.length === 2);
      assert.equal(await page.locator("#liveDocWorkspace").isVisible(), false);
      assert.match(await page.locator("#inboundHistoryRows").innerText(), /75\.000/);
      assert.match(await page.locator("#inboundHistoryRows").innerText(), /50\.000/);
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true, `history overflow at ${width}`);
      if (output) {
        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({ path: `${output}/inbound-history-${width}.png`, fullPage: true });
      }
      // Errors clear stale results and the ordinary refresh button recovers.
      await page.route("**/api/phieu-nhap/lich-su?*", (route) => route.fulfill({ status: 503,
        contentType: "application/json", body: JSON.stringify({ code: "UNAVAILABLE", message: "Tạm thời không tải được lịch sử." }) }));
      await page.locator("#inboundHistoryRefresh").click();
      await page.getByText("Tạm thời không tải được lịch sử.", { exact: false }).waitFor();
      assert.equal(await page.locator("#inboundHistoryTable").isVisible(), false);
      await page.unroute("**/api/phieu-nhap/lich-su?*");
      await page.locator("#inboundHistoryRefresh").click();
      await page.waitForFunction(() => document.querySelector("#inboundHistoryRows").rows.length === 2);
      await historyFilters.locator('[name="maSanPham"]').fill("ZZ9999");
      await historyFilters.getByRole("button", { name: "Tra cứu", exact: true }).click();
      await page.getByText("Chưa có lô nhập phù hợp.", { exact: false }).waitFor();
      await historyFilters.locator('[name="maSanPham"]').fill(product);
      await page.locator("#inboundHistoryRefresh").click();
      await page.waitForFunction(() => document.querySelector("#inboundHistoryRows").rows.length === 2);
      await page.locator("#inboundHistoryRows button").first().click();
      await page.waitForFunction(() => !document.querySelector("#liveDocumentView").inert);
      assert.equal(await page.locator("#liveDocCode").inputValue(), document.maPhieuNhap);
      assert.equal(await page.locator("#liveDocComplete").isVisible(), false);
      // Keyboard navigation selects the history tab and retains the filters.
      await page.locator("#liveDocTabDocuments").focus();
      await page.keyboard.press("ArrowRight");
      await page.waitForFunction(() => document.querySelector("#inboundHistoryRows").rows.length === 2);
      assert.equal(await historyFilters.locator('[name="maPhieuNhap"]').inputValue(), document.maPhieuNhap);
    } finally { await context.close(); }
  }
  assert.deepEqual(errors, []);
  console.log(`Inbound UI passed: draft/rollback absent from lot history, completion shows 6+4 and exact values, code/date filters, paging API, history error/empty/retry, open receipt and keyboard tabs; posting/no double posting preserved; desktop/mobile without overflow/page errors. Test documents: ${createdDocuments.join(", ")}`);
} finally { await browser.close(); }
