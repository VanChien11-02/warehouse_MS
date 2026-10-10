import assert from "node:assert/strict";
import { test } from "node:test";
import { createInventoryApi } from "./inventory-api.js";

test("inventory adapter sends contract filters and pagination", async () => {
  const calls = [];
  const api = createInventoryApi({
    send: async (path) => {
      calls.push(path);
      return { items: [], page: 1, size: 20, totalElements: 0, totalPages: 0 };
    }
  });
  await api.list({ page: 1, maKho: " KHO001 ", maSanPham: " SP001 ",
    maLo: " LO001 ", hanSuDungTruoc: "2026-11-01", chiKhaDung: true });
  const url = new URL(calls[0], "http://local.test");
  assert.equal(url.pathname, "/ton-kho");
  assert.deepEqual(Object.fromEntries(url.searchParams), {
    page: "1", size: "20", maKho: "KHO001", maSanPham: "SP001",
    maLo: "LO001", hanSuDungTruoc: "2026-11-01", chiKhaDung: "true"
  });
});
