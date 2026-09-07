import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'app_config.dart';

/// Hàm để ApiClient lấy accessToken hiện tại mỗi lần gọi API.
typedef TokenGetter = String? Function();

/// Nơi DUY NHẤT trong app được gọi http.get/post/put/patch trực tiếp. Mọi
/// service (delivery_service, driver_service, auth_service...) gọi qua
/// ApiClient này để tự thêm header Authorization và tự parse lỗi backend.
class ApiClient {
  final TokenGetter getAccessToken;
  final Future<void> Function()? onUnauthorized;

  ApiClient({required this.getAccessToken, this.onUnauthorized});

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.port,
      path: path,
      queryParameters:
          query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = true}) =>
      _send('PUT', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) =>
      _send('PATCH', path, body: body, auth: auth);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
  }) async {
    final uri = _uri(path, query);
    final headers = _headers(auth: auth);
    final encodedBody = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: encodedBody);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: encodedBody);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: encodedBody);
          break;
        default:
          throw UnsupportedError('HTTP method không hỗ trợ: $method');
      }
    } catch (_) {
      throw ApiException.unknown(
        'Không gọi được tới máy chủ ($path). Kiểm tra backend đã chạy '
        '(docker compose up) và AppConfig.apiBaseUrl đã đúng chưa.',
      );
    }

    if (response.statusCode == 401 && onUnauthorized != null) {
      await onUnauthorized!.call();
    }

    return _parseResponse(response);
  }

  dynamic _parseResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (isSuccess) return decoded;

    if (decoded is Map<String, dynamic>) {
      throw ApiException.fromJson(response.statusCode, decoded);
    }
    throw ApiException.unknown('Lỗi máy chủ (mã ${response.statusCode}).');
  }
}
