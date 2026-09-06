/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Đây sẽ là nơi DUY NHẤT trong app gọi `http.get/post/put/patch` trực tiếp.
/// Mọi service (auth_service, driver_service, delivery_service...) gọi qua
/// ApiClient này thay vì gọi package http trực tiếp.
///
/// Cần có:
/// - Constructor nhận vào một hàm lấy accessToken hiện tại (để tự thêm header
///   `Authorization: Bearer <token>`), và một callback xử lý khi gặp lỗi 401.
/// - Các hàm get/post/put/patch(path, {body, query}) trả JSON đã decode.
/// - Ghép base URL từ AppConfig.apiBaseUrl + path.
/// - Khi response lỗi (status >= 400): parse body thành ApiException và throw.
class ApiClient {
  // TODO: implement
}
