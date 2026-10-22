import assert from "node:assert/strict";
import test from "node:test";
import { createIdentityApi } from "./identity-api.js";

test("identity adapter uses admin contract and never includes a password in list requests", async () => {
  const calls = [];
  const client = { send(path, options) { calls.push({ path, options }); } };
  const identity = createIdentityApi(client);
  await identity.employees.list(1, 20);
  await identity.accounts.create({ maTaiKhoan: "TK0005", matKhau: "private-value" });
  await identity.accounts.update("TK0005", { role: "QLKHO", trangThai: true });
  await identity.accounts.resetPassword("TK0005", "another-private-value");
  assert.deepEqual(calls.map(({ path, options }) => [path, options?.method || "GET"]), [
    ["/nhan-vien?page=1&size=20", "GET"],
    ["/tai-khoan", "POST"],
    ["/tai-khoan/TK0005", "PUT"],
    ["/tai-khoan/TK0005/mat-khau", "PUT"]
  ]);
  assert.equal(calls[0].options, undefined);
  assert.deepEqual(calls[3].options.body, { matKhauMoi: "another-private-value" });
});
