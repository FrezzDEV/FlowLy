import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/secure_storage_service.dart';

class FlowLyApiException implements Exception {
  final int statusCode;
  final String message;

  const FlowLyApiException(this.statusCode, this.message);

  @override
  String toString() => 'FlowLyApiException($statusCode): $message';
}

class FlowLyApi {
  FlowLyApi._();

  static const String _defaultBaseUrl = 'https://cryptic-forest-99443.herokuapp.com/api/v1';
  static final Uri _baseUri = Uri.parse(
    const String.fromEnvironment('FLOWLY_API_URL', defaultValue: _defaultBaseUrl),
  );

  static Uri _uri(String path) => _baseUri.resolve(path.replaceFirst('/', ''));

  static Future<Map<String, String>> _headers({bool authenticated = false}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = await SecureStorageService.readAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  static void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decode(response);
      final message = decoded is Map<String, dynamic>
          ? (decoded['detail']?.toString() ?? 'Request failed')
          : 'Request failed';
      throw FlowLyApiException(response.statusCode, message);
    }
  }

  static Future<void> login({required String email, required String password}) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    _ensureSuccess(response);
    final data = _decode(response) as Map<String, dynamic>;
    final access = data['access_token']?.toString();
    if (access == null || access.isEmpty) {
      throw const FlowLyApiException(500, 'Server did not return an access token');
    }
    // The current API exposes only an access token. Keep the refresh slot empty
    // until refresh-token rotation is introduced server-side.
    await SecureStorageService.saveTokens(accessToken: access, refreshToken: '');
  }

  static Future<void> logout() => SecureStorageService.clearTokens();

  static Future<Map<String, dynamic>> me() async {
    final response = await http.get(_uri('/me'), headers: await _headers(authenticated: true));
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? avatarUrl,
    String? language,
    String? downloadDirectory,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (language != null) body['language'] = language;
    if (downloadDirectory != null) body['download_directory'] = downloadDirectory;

    final response = await http.patch(
      _uri('/me'),
      headers: await _headers(authenticated: true),
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>> filters() async {
    final response = await http.get(_uri('/me/filters'), headers: await _headers(authenticated: true));
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>> updateFilters(Map<String, dynamic> filters) async {
    final response = await http.put(
      _uri('/me/filters'),
      headers: await _headers(authenticated: true),
      body: jsonEncode(filters),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<List<Map<String, dynamic>>> recommendations() async {
    final response = await http.get(_uri('/recommendations'), headers: await _headers(authenticated: true));
    _ensureSuccess(response);
    return List<Map<String, dynamic>>.from(
      (jsonDecode(response.body) as List).map((item) => Map<String, dynamic>.from(item as Map)),
    );
  }

  static Future<List<Map<String, dynamic>>> related(int trackId) async {
    final response = await http.get(_uri('/tracks/$trackId/related'), headers: await _headers(authenticated: true));
    _ensureSuccess(response);
    return List<Map<String, dynamic>>.from(
      (jsonDecode(response.body) as List).map((item) => Map<String, dynamic>.from(item as Map)),
    );
  }

  static Future<List<Map<String, dynamic>>> favorites() async {
    final response = await http.get(_uri('/me/favorites'), headers: await _headers(authenticated: true));
    _ensureSuccess(response);
    return List<Map<String, dynamic>>.from(
      (jsonDecode(response.body) as List).map((item) => Map<String, dynamic>.from(item as Map)),
    );
  }

  static Future<Map<String, dynamic>> toggleFavorite(int trackId) async {
    final response = await http.post(
      _uri('/tracks/$trackId/favorite'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<void> addHistory(int trackId) async {
    final response = await http.post(
      _uri('/history/$trackId'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
  }

  static Future<List<Map<String, dynamic>>> history() async {
    final response = await http.get(_uri('/me/history'), headers: await _headers(authenticated: true));
    _ensureSuccess(response);
    return List<Map<String, dynamic>>.from(
      (jsonDecode(response.body) as List).map((item) => Map<String, dynamic>.from(item as Map)),
    );
  }

  static Future<Map<String, dynamic>> stats() async {
    final response = await http.get(_uri('/me/stats'), headers: await _headers(authenticated: true));
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<List<Map<String, dynamic>>> comments(int trackId) async {
    final response = await http.get(_uri('/tracks/$trackId/comments'), headers: await _headers(authenticated: true));
    _ensureSuccess(response);
    return List<Map<String, dynamic>>.from(
      (jsonDecode(response.body) as List).map((item) => Map<String, dynamic>.from(item as Map)),
    );
  }

  static Future<Map<String, dynamic>> addComment(int trackId, String body) async {
    final response = await http.post(
      _uri('/tracks/$trackId/comments'),
      headers: await _headers(authenticated: true),
      body: jsonEncode({'body': body}),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>?> latestUpdate() async {
    final response = await http.get(_uri('/updates/latest'));
    _ensureSuccess(response);
    if (response.statusCode == 204 || response.body.trim().isEmpty) return null;
    return Map<String, dynamic>.from(_decode(response) as Map);
  }
}
