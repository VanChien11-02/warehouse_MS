export class ApiRequestError extends Error {
  constructor(status, code, message, fieldErrors = []) {
    super(message);
    this.name = "ApiRequestError";
    this.status = status;
    this.code = code;
    this.fieldErrors = fieldErrors;
  }
}

export function createApiClient({ baseUrl = "http://127.0.0.1:8080/api", fetchImpl = fetch } = {}) {
  let csrfToken = null;
  let csrfHeader = "X-CSRF-TOKEN";

  async function send(path, { method = "GET", body } = {}) {
    const headers = { Accept: "application/json" };
    if (body !== undefined) headers["Content-Type"] = "application/json";
    if (!["GET", "HEAD", "OPTIONS"].includes(method.toUpperCase())) {
      if (!csrfToken) await refreshCsrf();
      headers[csrfHeader] = csrfToken;
    }
    let response;
    try {
      response = await fetchImpl(`${baseUrl}${path}`, {
        method,
        credentials: "include",
        headers,
        ...(body === undefined ? {} : { body: JSON.stringify(body) })
      });
    } catch {
      throw new ApiRequestError(0, "NETWORK_ERROR", "Không kết nối được API.");
    }
    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new ApiRequestError(response.status, error.code || "HTTP_ERROR",
        error.message || `HTTP ${response.status}`, error.fieldErrors || []);
    }
    return response.status === 204 ? null : response.json();
  }

  async function refreshCsrf() {
    const response = await send("/auth/csrf");
    csrfToken = response.token;
    csrfHeader = response.headerName;
    return response;
  }

  async function login(tenTaiKhoan, matKhau) {
    const user = await send("/auth/dang-nhap", {
      method: "POST", body: { tenTaiKhoan, matKhau }
    });
    await refreshCsrf();
    return user;
  }

  async function logout() {
    try {
      await send("/auth/dang-xuat", { method: "POST" });
    } finally {
      csrfToken = null;
    }
  }

  return { send, refreshCsrf, login, logout };
}
