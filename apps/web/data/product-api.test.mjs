import assert from "node:assert/strict";
import test from "node:test";
import { createProductApi } from "./product-api.js";

test("product adapter uses accepted routes and payload", async () => {
  const calls = [];
  const product = { maSanPham: "SP0001", tenSanPham: "Mẫu" };
  const api = createProductApi({ send: async (...args) => {
    calls.push(args);
    return { items: [] };
  } });

  await api.list(1, 8, "sữa & bánh");
  await api.get("SP0001");
  await api.create(product);
  await api.update("SP0001", product);
  await api.remove("SP0001");
  await api.references();

  assert.equal(calls[0][0], "/san-pham?page=1&size=8&q=s%E1%BB%AFa+%26+b%C3%A1nh");
  assert.deepEqual(calls[1], ["/san-pham/SP0001"]);
  assert.deepEqual(calls[2], ["/san-pham", { method: "POST", body: product }]);
  assert.deepEqual(calls[3], ["/san-pham/SP0001", { method: "PUT", body: product }]);
  assert.deepEqual(calls[4], ["/san-pham/SP0001", { method: "DELETE" }]);
  assert.equal(calls[5][0], "/loai-san-pham?page=0&size=100");
  assert.equal(calls[6][0], "/don-vi-tinh?page=0&size=100");
});
