import assert from "node:assert/strict";
import test from "node:test";
import { ApiRequestError, createApiClient } from "./api-client.js";

test("login sends session cookie and CSRF token without storing credentials", async () => {
  const calls = [];
  const replies = [
    { token: "first", headerName: "X-CSRF-TOKEN" },
    { maTaiKhoan: "TK0001", role: "ADMIN" },
    { token: "second", headerName: "X-CSRF-TOKEN" }
  ];
  const client = createApiClient({ fetchImpl: async (url, options) => {
    calls.push({ url, options });
    return { ok: true, status: 200, json: async () => replies.shift() };
  } });

  const user = await client.login("admin", "private-value");
  assert.equal(user.role, "ADMIN");
  assert.deepEqual(calls.map(({ url }) => new URL(url).pathname),
    ["/api/auth/csrf", "/api/auth/dang-nhap", "/api/auth/csrf"]);
  assert.ok(calls.every(({ options }) => options.credentials === "include"));
  assert.equal(calls[1].options.headers["X-CSRF-TOKEN"], "first");
  assert.deepEqual(JSON.parse(calls[1].options.body),
    { tenTaiKhoan: "admin", matKhau: "private-value" });
  await client.send("/san-pham", { method: "POST", body: { maSanPham: "SP0001" } });
  assert.equal(calls[3].options.headers["X-CSRF-TOKEN"], "second");
});

test("API errors keep HTTP status and public code", async () => {
  const client = createApiClient({ fetchImpl: async () => ({
    ok: false, status: 401, json: async () => ({ code: "UNAUTHORIZED", message: "Đăng nhập" })
  }) });
  await assert.rejects(client.send("/san-pham"), (error) =>
    error instanceof ApiRequestError && error.status === 401 && error.code === "UNAUTHORIZED");
});

test("network failures return a readable error", async () => {
  const client = createApiClient({ fetchImpl: async () => { throw new TypeError("Failed to fetch"); } });
  await assert.rejects(client.send("/san-pham"), (error) =>
    error instanceof ApiRequestError && error.code === "NETWORK_ERROR"
      && error.message === "Không kết nối được API.");
});

test("logout clears CSRF token and handles empty response", async () => {
  const calls = [];
  const client = createApiClient({ fetchImpl: async (url, options) => {
    calls.push({ url, options });
    return new URL(url).pathname === "/api/auth/csrf"
      ? { ok: true, status: 200, json: async () => ({ token: "token", headerName: "X-CSRF-TOKEN" }) }
      : { ok: true, status: 204 };
  } });
  await client.logout();
  await client.send("/san-pham", { method: "POST", body: {} });
  assert.deepEqual(calls.map(({ url }) => new URL(url).pathname),
    ["/api/auth/csrf", "/api/auth/dang-xuat", "/api/auth/csrf", "/api/san-pham"]);
});
