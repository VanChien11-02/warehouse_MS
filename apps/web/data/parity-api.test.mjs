import assert from "node:assert/strict";
import test from "node:test";
import { createMasterApi, masterPrefixes, masterResources, nextCode, selectOptions } from "./master-api.js";
import { createDocumentApi } from "./document-api.js";
import { draftBody, actualBody } from "./document-models.js";
import { createIdentityApi } from "./identity-api.js";
import { createInsightApi } from "./insight-api.js";

const recorder = () => {
  const calls = [];
  return { calls, client: { send: async (path, options) => { calls.push({ path, options }); return { items: [], totalElements: 0 }; } } };
};

test("all master resources support paginated search, create, update, delete", async () => {
  const { calls, client } = recorder();
  const api = createMasterApi(client);
  for (const [key, path] of Object.entries(masterResources)) {
    calls.length = 0;
    await api[key].list(1, "A & B", { maKho: "KHO001" });
    await api[key].get("A/B");
    await api[key].create({ test: true });
    await api[key].update("A/B", { test: false });
    await api[key].remove("A/B");
    assert.equal(calls[0].path, `/${path}?page=1&size=20&q=A+%26+B&maKho=KHO001`);
    assert.equal(calls[1].path, `/${path}/A%2FB`);
    assert.equal(calls[2].options.method, "POST");
    assert.equal(calls[3].options.method, "PUT");
    assert.equal(calls[4].options.method, "DELETE");
  }
});

test("nextCode and selectOptions generate sequential codes and combobox options", () => {
  assert.equal(nextCode(masterPrefixes.warehouses, [{ maKho: "KHO001" }, { maKho: "KHO004" }], "maKho"), "KHO005");
  assert.equal(nextCode("SP", [], "maSanPham"), "SP0001");
  const html = selectOptions([{ maKho: "KHO001", tenKho: "Kho chính" }], "maKho", (item) => `${item.maKho} · ${item.tenKho}`, "KHO002", "-- Chọn kho --");
  assert.match(html, /value="KHO002" selected/);
  assert.match(html, /KHO001 · Kho chính/);
});

test("partner mappings and permission matrix use server endpoints", async () => {
  const { calls, client } = recorder();
  const api = createMasterApi(client);
  await api.suppliers.products("NCC001");
  await api.recipients.link("DT0001", "SP0001");
  await api.recipients.unlink("DT0001", "SP0001");
  await createIdentityApi(client).permissions();
  assert.deepEqual(calls.map((c) => c.path), ["/nha-cung-cap/NCC001/san-pham", "/doi-tac-nhan-hang/DT0001/san-pham/SP0001", "/doi-tac-nhan-hang/DT0001/san-pham/SP0001", "/quyen-han"]);
});

test("all document resources support lists, draft updates, cancellation and completion", async () => {
  const { calls, client } = recorder();
  const api = createDocumentApi(client);
  for (const [kind, path] of Object.entries({ inbound: "phieu-nhap", outbound: "phieu-xuat", transfer: "phieu-chuyen", count: "phieu-kiem-ke", return: "phieu-tra-hang" })) {
    calls.length = 0;
    await api[kind].list(2, 10, { trangThai: "NHAP" });
    await api[kind].cancel("A/B"); await api[kind].complete("A/B");
    assert.equal(calls[0].path, `/${path}?page=2&size=10&trangThai=NHAP`);
    assert.equal(calls[1].path, `/${path}/A%2FB/huy`);
    assert.deepEqual(calls[2], { path: `/${path}/A%2FB/hoan-tat`, options: { method: "POST" } });
  }
  await api.count.setActual("KK0001", "LO0001", { soLuongThucTe: 0, lyDoChenhLech: "Hao hụt" });
  assert.equal(calls.at(-1).path, "/phieu-kiem-ke/KK0001/chi-tiet/LO0001");
});

test("draft payloads exclude server owned fields and preserve multiple lines", () => {
  const body = draftBody("inbound", " NCC001 ", " ", [
    { maSanPham: "SP0001", soLuong: "2", donGiaNhap: "12.3456", maNhanVien: "FAKE" },
    { maSanPham: "SP0002", soLuong: "3", donGiaNhap: "0" }
  ]);
  assert.deepEqual(body, { maNhaCungCap: "NCC001", ghiChu: null, chiTiet: [
    { maSanPham: "SP0001", soLuong: 2, donGiaNhap: 12.3456 }, { maSanPham: "SP0002", soLuong: 3, donGiaNhap: 0 }
  ] });
  assert.deepEqual(actualBody({ soLuongHeThong: 99999, soLuongThucTe: "0", lyDoChenhLech: " Hao hụt " }), { soLuongThucTe: 0, lyDoChenhLech: "Hao hụt" });
  assert.deepEqual(draftBody("inbound", "NCC001", "", [
    { maSanPham: "SP0001", soLuong: "10", donGiaNhap: "1" }
  ], true, [
    { maSanPham: "SP0001", maViTri: "VT0001", soLuong: "6", ngaySanXuat: "", hanSuDung: "" },
    { maSanPham: "SP0001", maViTri: "VT0002", soLuong: "4", ngaySanXuat: "", hanSuDung: "" }
  ]).phanBo, [
    { maSanPham: "SP0001", maViTri: "VT0001", soLuong: "6", ngaySanXuat: "", hanSuDung: "" },
    { maSanPham: "SP0001", maViTri: "VT0002", soLuong: "4", ngaySanXuat: "", hanSuDung: "" }
  ]);
  assert.equal(Object.hasOwn(draftBody("return", "PX0001", "", [], true), "maPhieuXuat"), false);
  assert.deepEqual(draftBody("count", "VT0001", "", []), { maViTri: "VT0001", ghiChu: null });
});

test("extra reports and audit use accepted filters", async () => {
  const { calls, client } = recorder();
  const api = createInsightApi(client);
  await api.query("expiry", { soNgay: 30 });
  await api.query("discrepancies", { tuNgay: "2026-10-01", denNgay: "2026-10-21" }, 1);
  await api.query("audit", { tuNgay: "2026-10-01", denNgay: "2026-10-21", maTaiKhoan: "TK0001" });
  assert.equal(calls[0].path, "/bao-cao/lo-sap-het-han?soNgay=30&page=0&size=20");
  assert.equal(calls[1].path, "/bao-cao/chenh-lech-kiem-ke?tuNgay=2026-10-01&denNgay=2026-10-21&page=1&size=20");
  assert.equal(calls[2].path, "/audit?tuNgay=2026-10-01&denNgay=2026-10-21&maTaiKhoan=TK0001&page=0&size=20");
});
