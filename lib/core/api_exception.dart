/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Đại diện cho lỗi mà backend trả về theo format chung toàn hệ thống:
///   { "code": "ORDER_NOT_FOUND", "message": "Không tìm thấy đơn hàng.", "details": null }
///
/// Cần có:
/// - Field: statusCode (int, mã HTTP), code (String), message (String), details (dynamic).
/// - Factory `ApiException.fromJson(int statusCode, Map<String, dynamic> json)` để
///   dựng từ JSON lỗi backend trả về.
/// - Factory `ApiException.unknown()` dùng khi mất mạng / không parse được JSON.
class ApiException implements Exception {
  // TODO: implement
}
