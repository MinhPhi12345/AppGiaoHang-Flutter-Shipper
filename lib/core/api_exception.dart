class ApiException implements Exception {
  final int statusCode;
  final String? code;
  final String message;
  final Map<String, dynamic>? details;

  ApiException(this.statusCode, this.message, {this.code, this.details});

  @override
  String toString() {
    return 'Lỗi $statusCode: $message';
  }
}
