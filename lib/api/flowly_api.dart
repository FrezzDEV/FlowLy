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

  static const String _defaultBaseUrl =
      'https://cryptic-forest-99443.herokuapp.com/api/v1';
  static final Uri _baseUri = Uri.parse(
    const String.fromEnvironment('FLOWLY_API_URL', defaultValue: _defaultBaseUrl),
  );

  static Uri _uri(String path) =>
      _baseUri.resolve(path.replaceFirst('/', ''));

  static Future<Map<String, String>> _headers({
    bool authenticated = false,
  }) async {
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

  static List<Map<String, dynamic>> _list(http.Response response) {
    final decoded = _decode(response);
    if (decoded is! List) return const [];
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'username': email, 'password': password},
    );
    _ensureSuccess(response);
    final data = _decode(response) as Map<String, dynamic>;
    final access = data['access_token']?.toString();
    if (access == null || access.isEmpty) {
      throw const FlowLyApiException(
        500,
        'Server did not return an access token',
      );
    }
    await SecureStorageService.saveTokens(
      accessToken: access,
      refreshToken: '',
    );
  }

  static Future<void> logout() => SecureStorageService.clearTokens();

  static Future<Map<String, dynamic>> me() async {
    final response = await http.get(
      _uri('/me'),
      headers: await _headers(authenticated: true),
    );
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
    if (downloadDirectory != null) {
      body['download_directory'] = downloadDirectory;
    }

    final response = await http.patch(
      _uri('/me'),
      headers: await _headers(authenticated: true),
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>> filters() async {
    final response = await http.get(
      _uri('/me/filters'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>> updateFilters(
    Map<String, dynamic> filters,
  ) async {
    final response = await http.put(
      _uri('/me/filters'),
      headers: await _headers(authenticated: true),
      body: jsonEncode(filters),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<List<Map<String, dynamic>>> recommendations() async {
    final response = await http.get(
      _uri('/recommendations'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return _list(response);
  }

  static Future<List<Map<String, dynamic>>> related(int trackId) async {
    final response = await http.get(
      _uri('/tracks/$trackId/related'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return _list(response);
  }

  static Future<List<Map<String, dynamic>>> favorites() async {
    final response = await http.get(
      _uri('/me/favorites'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return _list(response);
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
    final response = await http.get(
      _uri('/me/history'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return _list(response);
  }

  static Future<Map<String, dynamic>> stats() async {
    final response = await http.get(
      _uri('/me/stats'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<List<Map<String, dynamic>>> comments(int trackId) async {
    final response = await http.get(
      _uri('/tracks/$trackId/comments'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return _list(response);
  }

  static Future<Map<String, dynamic>> addComment(
    int trackId,
    String body,
  ) async {
    final response = await http.post(
      _uri('/tracks/$trackId/comments'),
      headers: await _headers(authenticated: true),
      body: jsonEncode({'body': body}),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>> lyrics(int trackId) async {
    final response = await http.get(
      _uri('/tracks/$trackId/lyrics'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<List<Map<String, dynamic>>> myThemes() async {
    final response = await http.get(
      _uri('/me/themes'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return _list(response);
  }

  static Future<Map<String, dynamic>> createTheme({
    required String name,
    required Map<String, dynamic> config,
    String? coverUrl,
    bool isPublic = false,
  }) async {
    final response = await http.post(
      _uri('/me/themes'),
      headers: await _headers(authenticated: true),
      body: jsonEncode({
        'name': name,
        'config': config,
        'cover_url': coverUrl,
        'is_public': isPublic,
      }),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<List<Map<String, dynamic>>> popularThemes() async {
    final response = await http.get(_uri('/themes/popular'));
    _ensureSuccess(response);
    return _list(response);
  }

  static Future<Map<String, dynamic>> downloadTheme(int themeId) async {
    final response = await http.post(
      _uri('/themes/$themeId/download'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>> rateTheme(
    int themeId,
    int rating,
  ) async {
    final response = await http.post(
      _uri('/themes/$themeId/rating'),
      headers: await _headers(authenticated: true),
      body: jsonEncode({'rating': rating}),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>> createImport({
    required String source,
    required String sourceUrl,
  }) async {
    final response = await http.post(
      _uri('/imports'),
      headers: await _headers(authenticated: true),
      body: jsonEncode({
        'source': source,
        'source_url': sourceUrl,
      }),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>> importStatus(int jobId) async {
    final response = await http.get(
      _uri('/imports/$jobId'),
      headers: await _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>?> latestUpdate() async {
    final response = await http.get(_uri('/updates/latest'));
    _ensureSuccess(response);
    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(_decode(response) as Map);
  }
}
