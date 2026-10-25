import assert from "node:assert/strict";
import { test } from "node:test";
import { createDocumentApi } from "./document-api.js";

test("document adapter uses accepted create, completion and FEFO routes", async () => {
  const calls = [];
  const api = createDocumentApi({ send: async (path, options) => {
    calls.push({ path, options });
    return {};
  } });
  await api.inbound.create({ chiTiet: [] });
  await api.inbound.complete("PN0001", { phanBo: [] });
  await api.outbound.suggest("PX0001", "SP0001", 2);
  await api.outbound.complete("PX0001");
  await api.reconciliation.get("NHAP", "PN0001");
  await api.reconciliation.create("XUAT", "PX0001", { giaTriDoiSoat: 120, ghiChu: null });
  assert.deepEqual(calls, [
    { path: "/phieu-nhap", options: { method: "POST", body: { chiTiet: [] } } },
    { path: "/phieu-nhap/PN0001/hoan-tat", options: { method: "POST", body: { phanBo: [] } } },
    { path: "/phieu-xuat/PX0001/goi-y-fefo?maSanPham=SP0001&soLuong=2", options: undefined },
    { path: "/phieu-xuat/PX0001/hoan-tat", options: { method: "POST" } },
    { path: "/doi-soat-gia-tri/NHAP/PN0001", options: undefined },
    { path: "/doi-soat-gia-tri/XUAT/PX0001", options: { method: "POST", body: { giaTriDoiSoat: 120, ghiChu: null } } }
  ]);
});

test("inbound history keeps page zero and omits empty optional filters", async () => {
  const paths = [];
  const api = createDocumentApi({ send: async (path) => { paths.push(path); return { items: [] }; } });
  await api.inbound.history({ page: 0, maPhieuNhap: "PN0001", maSanPham: "", tuNgay: "2026-10-25", denNgay: null });
  const url = new URL(paths[0], "http://local.test");
  assert.equal(url.pathname, "/phieu-nhap/lich-su");
  assert.deepEqual(Object.fromEntries(url.searchParams), { page: "0", size: "20", maPhieuNhap: "PN0001", tuNgay: "2026-10-25" });
});
