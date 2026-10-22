export const documentScreens = {
  inbound: { title: "Phiếu nhập kho", code: "maPhieuNhap", date: "ngayNhap", partner: "maNhaCungCap", label: "Mã nhà cung cấp",
    fields: [["maSanPham", "Mã sản phẩm"], ["soLuong", "Số lượng", "quantity"], ["donGiaNhap", "Đơn giá nhập", "money"]] },
  outbound: { title: "Phiếu xuất kho", code: "maPhieuXuat", date: "ngayXuat", partner: "maDoiTacNhanHang", label: "Mã đối tác nhận",
    fields: [["maLo", "Mã lô"], ["maViTri", "Vị trí"], ["soLuong", "Số lượng", "quantity"], ["donGiaXuat", "Đơn giá xuất", "money"]] },
  transfer: { title: "Phiếu chuyển kho", code: "maPhieuChuyen", date: "ngayChuyen",
    fields: [["maLo", "Mã lô"], ["maViTriNguon", "Vị trí nguồn"], ["maViTriDich", "Vị trí đích"], ["soLuong", "Số lượng", "quantity"]] },
  count: { title: "Phiếu kiểm kê", code: "maPhieuKiemKe", date: "ngayKiemKe", partner: "maViTri", label: "Vị trí kiểm kê",
    fields: [["maLo", "Mã lô"], ["soLuongHeThong", "Hệ thống", "snapshot"], ["soLuongThucTe", "Thực tế", "actual"], ["lyDoChenhLech", "Lý do chênh lệch", "reason"]] },
  return: { title: "Phiếu trả hàng", code: "maPhieuTraHang", date: "ngayTra", partner: "maPhieuXuat", label: "Phiếu xuất gốc",
    fields: [["maLo", "Mã lô"], ["maViTri", "Vị trí nhận"], ["soLuong", "Số lượng", "quantity"], ["tinhTrang", "Tình trạng", "condition"]] }
};

export function draftBody(mode, partner, note, lines, updating = false) {
  const screen = documentScreens[mode];
  const body = { ghiChu: note.trim() || null };
  if (screen.partner && !(mode === "return" && updating)) body[screen.partner] = partner.trim();
  if (mode !== "count") body.chiTiet = lines.map((line) => Object.fromEntries(screen.fields.map(([key, , type]) =>
    [key, ["quantity", "money"].includes(type) ? Number(line[key]) : String(line[key] ?? "").trim()])));
  return body;
}

export function actualBody(line) {
  return { soLuongThucTe: Number(line.soLuongThucTe), lyDoChenhLech: String(line.lyDoChenhLech || "").trim() || null };
}
