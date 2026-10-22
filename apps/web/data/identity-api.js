export function createIdentityApi(client) {
  function resource(path) {
    return {
      list(page = 0, size = 20) {
        return client.send(`/${path}?page=${page}&size=${size}`);
      },
      get(code) {
        return client.send(`/${path}/${encodeURIComponent(code)}`);
      },
      create(body) {
        return client.send(`/${path}`, { method: "POST", body });
      },
      update(code, body) {
        return client.send(`/${path}/${encodeURIComponent(code)}`, { method: "PUT", body });
      }
    };
  }

  return {
    permissions: () => client.send("/quyen-han"),
    employees: resource("nhan-vien"),
    accounts: {
      ...resource("tai-khoan"),
      resetPassword(code, password) {
        return client.send(`/tai-khoan/${encodeURIComponent(code)}/mat-khau`, {
          method: "PUT", body: { matKhauMoi: password }
        });
      }
    }
  };
}
