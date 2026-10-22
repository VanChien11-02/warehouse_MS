import assert from "node:assert/strict";
import test from "node:test";
import { apiLandingPageForRole, apiPagesForRole, roleProfiles } from "./navigation.js";

test("API pages follow the authenticated role and reject unknown roles", () => {
  assert.deepEqual(apiPagesForRole("ADMIN"), ["dashboard", "employees", "accounts", "permissions"]);
  for (const role of ["QLKHO", "NVKHO", "KETOAN"]) {
    assert.equal(apiPagesForRole(role).includes("accounts"), false);
    assert.equal(apiPagesForRole(role).includes("employees"), false);
  }
  for (const page of roleProfiles.manager.pages) assert.ok(apiPagesForRole("QLKHO").includes(page));
  for (const role of ["QLKHO", "NVKHO", "KETOAN"]) {
    assert.equal(apiPagesForRole(role).includes("permissions"), false);
    assert.equal(apiPagesForRole(role).includes("audit"), false);
  }
  assert.equal(apiPagesForRole("KETOAN").includes("expiry"), false);
  assert.equal(apiPagesForRole("NVKHO").includes("reports"), false);
  assert.deepEqual(apiPagesForRole("NVKHO"), ["dashboard", "inventory", "inbound", "outbound"]);
  assert.equal(apiLandingPageForRole("ADMIN"), "dashboard");
  assert.equal(apiLandingPageForRole("NVKHO"), "dashboard");
  assert.equal(apiLandingPageForRole(null), "products");
  assert.deepEqual(apiPagesForRole(null), []);
  assert.deepEqual(apiPagesForRole("UNKNOWN"), []);
  assert.deepEqual(apiPagesForRole("toString"), []);
});
