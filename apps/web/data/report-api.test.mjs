import assert from "node:assert/strict";
import { test } from "node:test";
import { createReportApi } from "./report-api.js";

test("report adapter sends accepted date, code and page filters", async () => {
  let path;
  const api = createReportApi({ send: async (value) => { path = value; return { items: [] }; } });
  await api.movements({ from: "2026-10-01", to: "2026-10-08", page: 2,
    warehouse: " KHO001 ", product: " SP0001 " });
  const url = new URL(path, "http://local.test");
  assert.equal(url.pathname, "/bao-cao/nhap-xuat");
  assert.deepEqual(Object.fromEntries(url.searchParams), {
    tuNgay: "2026-10-01", denNgay: "2026-10-08", page: "2", size: "20",
    maKho: "KHO001", maSanPham: "SP0001"
  });
});
