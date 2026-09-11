import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'session_store.dart';
import 'api_exception.dart';

class ApiClient {
  static Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await SessionStore.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body; // Trường hợp trả về text/plain
      }
    } else {
      String message = 'Lỗi hệ thống';
      String? code;
      Map<String, dynamic>? details;

      try {
        final decoded = jsonDecode(response.body);
        message = decoded['message'] ?? message;
        code = decoded['code'];
        details = decoded['details'];
      } catch (_) {
        message = response.body.isNotEmpty ? response.body : 'Lỗi không xác định';
      }

      throw ApiException(
        response.statusCode,
        message,
        code: code,
        details: details,
      );
    }
  }

  static Future<dynamic> get(String path, {bool requiresAuth = true}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final response = await http.get(url, headers: headers);
    return _processResponse(response);
  }

  static Future<dynamic> post(String path, {dynamic body, bool requiresAuth = true}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final response = await http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  static Future<dynamic> patch(String path, {dynamic body, bool requiresAuth = true}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final response = await http.patch(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }
  static Future<dynamic> put(String path, {dynamic body, bool requiresAuth = true}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final response = await http.put(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }
}
