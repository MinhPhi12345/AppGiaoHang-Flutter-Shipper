/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Tương ứng `PagedResponse<T>` dùng chung ở backend:
///   { "page": 1, "pageSize": 20, "totalItems": 5, "items": [...] }
///
/// Cần có field: page, pageSize, totalItems, items (`List<T>`).
/// Nên có factory nhận thêm 1 hàm parse từng item trong "items".
class PagedResponse<T> {
  // TODO: implement
}
