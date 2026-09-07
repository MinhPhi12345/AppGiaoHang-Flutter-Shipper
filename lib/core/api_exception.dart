/// Đại diện cho lỗi mà backend trả về theo đúng format chung của hệ thống:
///   { "code": "ORDER_NOT_FOUND", "message": "Không tìm thấy đơn hàng.", "details": null }
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiException.fromJson(int statusCode, Map<String, dynamic> json) {
    return ApiException(
      statusCode: statusCode,
      code: json['code']?.toString() ?? 'UNKNOWN_ERROR',
      message: json['message']?.toString() ?? 'Đã có lỗi xảy ra.',
      details: json['details'],
    );
  }

  factory ApiException.unknown([String? message]) => ApiException(
        statusCode: 0,
        code: 'UNKNOWN_ERROR',
        message: message ?? 'Không thể kết nối tới máy chủ. Kiểm tra mạng và thử lại.',
      );

  @override
  String toString() => 'ApiException($code): $message';
}
