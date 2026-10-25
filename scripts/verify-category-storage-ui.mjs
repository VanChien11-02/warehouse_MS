import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir } from "node:fs/promises";

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_PATH || "playwright");
const base = process.env.WEB_TEST_URL || "http://127.0.0.1:5174";
const api = process.env.API_TEST_URL || "http://127.0.0.1:8080/api";
const username = process.env.CATEGORY_TEST_USERNAME;
const password = process.env.CATEGORY_TEST_PASSWORD;
const usedCategory = process.env.CATEGORY_TEST_USED;
const unusedCategory = process.env.CATEGORY_TEST_UNUSED;
if (!username || !password || !usedCategory || !unusedCategory) {
  throw new Error("Set CATEGORY_TEST_USERNAME/PASSWORD (QLKHO), CATEGORY_TEST_USED (has lots, Khô), CATEGORY_TEST_UNUSED (no lots). Use disposable fixtures.");
}
const output = process.env.WEB_TEST_OUTPUT;
if (output) await mkdir(output, { recursive: true });
const browser = await chromium.launch({ headless: true,
  ...(process.env.PLAYWRIGHT_CHANNEL ? { channel: process.env.PLAYWRIGHT_CHANNEL } : {}) });
const errors = [];
try {
  for (const width of [1440, 390]) {
    const context = await browser.newContext({ viewport: { width, height: 980 } });
    try {
      const page = await context.newPage();
      page.on("pageerror", (error) => errors.push(error.message));
      await page.goto(`${base}/?mode=api#categories`);
      await page.locator('#loginForm [name="tenTaiKhoan"]').fill(username);
      await page.locator('#loginForm [name="matKhau"]').fill(password);
      await page.locator('#loginForm button[type="submit"]').click();
      await page.locator("#loginDialog").waitFor({ state: "hidden" });
      await page.goto(`${base}/?mode=api#categories`);
      const view = page.locator("#liveMasterView");
      const dialog = page.locator(".identity-dialog[open]");
      const open = async (code) => {
        await view.locator("[data-search]").fill(code);
        const loaded = page.waitForResponse((response) => response.url().startsWith(`${api}/loai-san-pham?`) && response.url().includes(code));
        await view.getByRole("button", { name: "Tìm kiếm", exact: true }).click();
        await loaded;
        await view.locator(`[data-open="${code}"]`).click();
        await dialog.locator('[name="yeuCauBaoQuan"]').waitFor();
      };
      const save = async (code, status) => {
        const response = page.waitForResponse((response) => response.url() === `${api}/loai-san-pham/${code}` && response.request().method() === "PUT");
        await dialog.getByRole("button", { name: "Lưu", exact: true }).click();
        const result = await response;
        assert.equal(result.status(), status);
        return result.json();
      };
      const category = async (code) => {
        const result = await context.request.get(`${api}/loai-san-pham/${code}`);
        assert.equal(result.status(), 200);
        return result.json();
      };
      await open(usedCategory);
      const before = await category(usedCategory);
      assert.equal(before.yeuCauBaoQuan, "Khô");
      await dialog.locator('[name="yeuCauBaoQuan"]').selectOption("Mát");
      const blocked = await save(usedCategory, 409);
      assert.equal(blocked.code, "CATEGORY_STORAGE_LOCKED");
      await dialog.getByText("Không thể đổi yêu cầu bảo quản vì loại sản phẩm đã phát sinh lô hàng.", { exact: false }).waitFor();
      assert.equal((await category(usedCategory)).yeuCauBaoQuan, "Khô");
      assert.equal(await dialog.locator('[name="yeuCauBaoQuan"]').inputValue(), "Mát");
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true, `overflow at ${width}`);
      if (output) await dialog.screenshot({ path: `${output}/category-storage-blocked-${width}.png` });
      await dialog.locator('[name="yeuCauBaoQuan"]').selectOption("");
      assert.equal((await save(usedCategory, 409)).code, "CATEGORY_STORAGE_LOCKED");
      await dialog.locator('[name="yeuCauBaoQuan"]').selectOption("Khô");
      await dialog.locator('[name="tenLoai"]').fill(`Loại đã sửa ${usedCategory} ${width}`);
      await dialog.locator('[name="moTa"]').fill("Sửa mô tả khi đã có lô vẫn hợp lệ.");
      const renamed = await save(usedCategory, 200);
      assert.equal(renamed.tenLoai, `Loại đã sửa ${usedCategory} ${width}`);
      assert.equal(renamed.yeuCauBaoQuan, "Khô");
      await dialog.waitFor({ state: "hidden" });
      await open(unusedCategory);
      const oldStorage = (await category(unusedCategory)).yeuCauBaoQuan;
      const newStorage = oldStorage === "Mát" ? "Khô" : "Mát";
      await dialog.locator('[name="yeuCauBaoQuan"]').selectOption(newStorage);
      assert.equal((await save(unusedCategory, 200)).yeuCauBaoQuan, newStorage);
      await dialog.waitFor({ state: "hidden" });
    } finally { await context.close(); }
  }
  assert.deepEqual(errors, []);
  console.log("Category storage UI passed: real login/form/API/SQL, used category rejects Mát and NULL, database unchanged, rename succeeds, unused category changes; desktop/mobile; no page errors or overflow.");
} finally { await browser.close(); }
