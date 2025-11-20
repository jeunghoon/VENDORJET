import 'dart:convert';
import 'package:http/http.dart' as http;

// dart-define로 전달: --dart-define=USE_LOCAL_API=true --dart-define=API_BASE_URL=http://localhost:4110
// 기본값을 true/localhost:4110으로 두어 F5 실행 시 자동으로 로컬 서버와 연결되도록 함.
const bool useLocalApi = bool.fromEnvironment('USE_LOCAL_API', defaultValue: true);
const String apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:4110');

class ApiClient {
  static final http.Client _client = http.Client();
  static String? token;

  static Uri _uri(String path, [Map<String, String?>? query]) {
    final base = apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
    final uri = Uri.parse('$base$path');
    if (query == null) return uri;
    final cleaned = <String, String>{};
    query.forEach((k, v) {
      if (v != null && v.isNotEmpty) cleaned[k] = v;
    });
    return uri.replace(queryParameters: cleaned);
  }

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<dynamic> get(String path, {Map<String, String?>? query}) async {
    final resp = await _client.get(_uri(path, query), headers: _headers());
    return _decode(resp);
  }

  static Future<dynamic> post(String path, {Object? body}) async {
    final resp = await _client.post(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(resp);
  }

  static Future<dynamic> put(String path, {Object? body}) async {
    final resp = await _client.put(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(resp);
  }

  static Future<dynamic> patch(String path, {Object? body}) async {
    final resp = await _client.patch(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(resp);
  }

  static Future<void> delete(String path) async {
    final resp = await _client.delete(_uri(path), headers: _headers());
    _decode(resp, allowNoContent: true);
  }

  static dynamic _decode(http.Response resp, {bool allowNoContent = false}) {
    if (!allowNoContent || resp.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
        if (resp.statusCode >= 200 && resp.statusCode < 300) return decoded;
        throw ApiClientException(resp.statusCode, decoded);
      } catch (e) {
        if (resp.statusCode >= 400) {
          throw ApiClientException(resp.statusCode, resp.body.isEmpty ? null : resp.body);
        }
        rethrow;
      }
    } else {
      if (resp.statusCode >= 400) {
        throw ApiClientException(resp.statusCode, null);
      }
      return null;
    }
  }
}

class ApiClientException implements Exception {
  final int statusCode;
  final dynamic body;
  ApiClientException(this.statusCode, this.body);

  @override
  String toString() => 'ApiClientException($statusCode): $body';
}
