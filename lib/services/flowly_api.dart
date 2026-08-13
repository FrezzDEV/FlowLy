import 'dart:convert';

import 'package:http/http.dart' as http;

class FlowLyApi {
  FlowLyApi({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'FLOWLY_API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            ),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? accessToken;

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Map<String, String> _headers({bool jsonBody = false}) => {
        if (jsonBody) 'Content-Type': 'application/json',
        if (accessToken != null && accessToken!.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get(_uri('/api/v1/me'), headers: _headers());
    return _jsonMap(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? avatarUrl,
    String? language,
    String? downloadDirectory,
  }) async {
    final response = await _client.patch(
      _uri('/api/v1/me'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (language != null) 'language': language,
        if (downloadDirectory != null) 'download_directory': downloadDirectory,
      }),
    );
    return _jsonMap(response);
  }

  Future<Map<String, dynamic>> getFilters() async {
    final response = await _client.get(_uri('/api/v1/me/filters'), headers: _headers());
    return _jsonMap(response);
  }

  Future<Map<String, dynamic>> updateFilters(Map<String, dynamic> values) async {
    final response = await _client.put(
      _uri('/api/v1/me/filters'),
      headers: _headers(jsonBody: true),
      body: jsonEncode(values),
    );
    return _jsonMap(response);
  }

  Future<List<Map<String, dynamic>>> recommendations() async {
    final response = await _client.get(_uri('/api/v1/recommendations'), headers: _headers());
    return _jsonList(response);
  }

  Future<List<Map<String, dynamic>>> related(int trackId) async {
    final response = await _client.get(_uri('/api/v1/tracks/$trackId/related'), headers: _headers());
    return _jsonList(response);
  }

  Future<void> addHistory(int trackId) async {
    final response = await _client.post(_uri('/api/v1/history/$trackId'), headers: _headers());
    _ensureSuccess(response);
  }

  Future<List<Map<String, dynamic>>> history() async {
    final response = await _client.get(_uri('/api/v1/me/history'), headers: _headers());
    return _jsonList(response);
  }

  Future<bool> toggleFavorite(int trackId) async {
    final response = await _client.post(_uri('/api/v1/tracks/$trackId/favorite'), headers: _headers());
    final map = _jsonMap(response);
    return map['liked'] == true;
  }

  Future<List<Map<String, dynamic>>> comments(int trackId) async {
    final response = await _client.get(_uri('/api/v1/tracks/$trackId/comments'), headers: _headers());
    return _jsonList(response);
  }

  Future<Map<String, dynamic>> addComment(int trackId, String body) async {
    final response = await _client.post(
      _uri('/api/v1/tracks/$trackId/comments'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({'body': body}),
    );
    return _jsonMap(response);
  }

  Future<Map<String, dynamic>> lyrics(int trackId) async {
    final response = await _client.get(_uri('/api/v1/tracks/$trackId/lyrics'), headers: _headers());
    return _jsonMap(response);
  }

  Future<Map<String, dynamic>> stats() async {
    final response = await _client.get(_uri('/api/v1/me/stats'), headers: _headers());
    return _jsonMap(response);
  }

  Future<Map<String, dynamic>?> latestUpdate() async {
    final response = await _client.get(_uri('/api/v1/updates/latest'), headers: _headers());
    if (response.statusCode == 200 && response.body.trim() != 'null') {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  void dispose() => _client.close();

  Map<String, dynamic> _jsonMap(http.Response response) {
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _jsonList(http.Response response) {
    _ensureSuccess(response);
    final values = jsonDecode(response.body) as List<dynamic>;
    return values.cast<Map<String, dynamic>>();
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message = 'HTTP ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) message = body['detail'].toString();
    } catch (_) {}
    throw Exception(message);
  }
}
