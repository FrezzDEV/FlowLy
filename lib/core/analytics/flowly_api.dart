import 'dart:convert';

import 'package:http/http.dart' as http;

class FlowLyApi {
  FlowLyApi({String? baseUrl, http.Client? client})
      : baseUrl = _normalizeBaseUrl(baseUrl),
        _client = client ?? http.Client();

  static const Duration _requestTimeout = Duration(seconds: 15);

  final String baseUrl;
  final http.Client _client;
  String? accessToken;

  static String _normalizeBaseUrl(String? value) {
    final raw = (value ?? const String.fromEnvironment('FLOWLY_API_BASE_URL')).trim();
    if (raw.isEmpty) {
      throw StateError(
        'FLOWLY_API_BASE_URL is not configured. Pass baseUrl explicitly or '
        'build with --dart-define=FLOWLY_API_BASE_URL=https://...',
      );
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      throw FormatException('Invalid FLOWLY_API_BASE_URL: $raw');
    }

    return raw.replaceFirst(RegExp(r'/+$'), '');
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Map<String, String> _headers({bool jsonBody = false}) => {
    if (jsonBody) 'Content-Type': 'application/json',
    if (accessToken != null && accessToken!.isNotEmpty)
      'Authorization': 'Bearer $accessToken',
  };

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) =>
      request().timeout(_requestTimeout);

  Future<Map<String, dynamic>> getProfile() async =>
      _jsonMap(await _request(() => _client.get(_uri('/api/v1/me'), headers: _headers())));

  Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? avatarUrl,
    String? language,
    String? downloadDirectory,
  }) async =>
      _jsonMap(await _request(() => _client.patch(
            _uri('/api/v1/me'),
            headers: _headers(jsonBody: true),
            body: jsonEncode({
              if (username != null) 'username': username,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
              if (language != null) 'language': language,
              if (downloadDirectory != null)
                'download_directory': downloadDirectory,
            }),
          )));

  Future<Map<String, dynamic>> getFilters() async =>
      _jsonMap(await _request(() => _client.get(_uri('/api/v1/me/filters'), headers: _headers())));

  Future<Map<String, dynamic>> updateFilters(Map<String, dynamic> values) async =>
      _jsonMap(await _request(() => _client.put(
            _uri('/api/v1/me/filters'),
            headers: _headers(jsonBody: true),
            body: jsonEncode(values),
          )));

  Future<List<Map<String, dynamic>>> recommendations() async =>
      _jsonList(await _request(() => _client.get(_uri('/api/v1/recommendations'), headers: _headers())));

  Future<List<Map<String, dynamic>>> related(int trackId) async =>
      _jsonList(await _request(() => _client.get(
            _uri('/api/v1/tracks/$trackId/related'),
            headers: _headers(),
          )));

  Future<void> addHistory(int trackId) async => _ensureSuccess(
        await _request(() => _client.post(
              _uri('/api/v1/history/$trackId'),
              headers: _headers(),
            )),
      );

  Future<List<Map<String, dynamic>>> history() async =>
      _jsonList(await _request(() => _client.get(_uri('/api/v1/me/history'), headers: _headers())));

  Future<bool> toggleFavorite(int trackId) async {
    final data = _jsonMap(await _request(() => _client.post(
          _uri('/api/v1/tracks/$trackId/favorite'),
          headers: _headers(),
        )));
    return data['liked'] == true;
  }

  Future<List<Map<String, dynamic>>> comments(int trackId) async =>
      _jsonList(await _request(() => _client.get(
            _uri('/api/v1/tracks/$trackId/comments'),
            headers: _headers(),
          )));

  Future<Map<String, dynamic>> addComment(int trackId, String body) async =>
      _jsonMap(await _request(() => _client.post(
            _uri('/api/v1/tracks/$trackId/comments'),
            headers: _headers(jsonBody: true),
            body: jsonEncode({'body': body}),
          )));

  Future<Map<String, dynamic>> lyrics(int trackId) async =>
      _jsonMap(await _request(() => _client.get(
            _uri('/api/v1/tracks/$trackId/lyrics'),
            headers: _headers(),
          )));

  Future<Map<String, dynamic>> stats() async =>
      _jsonMap(await _request(() => _client.get(_uri('/api/v1/me/stats'), headers: _headers())));

  Future<List<Map<String, dynamic>>> myThemes() async =>
      _jsonList(await _request(() => _client.get(_uri('/api/v1/me/themes'), headers: _headers())));

  Future<Map<String, dynamic>> saveTheme({
    required String name,
    required Map<String, dynamic> config,
    String? coverUrl,
    bool isPublic = false,
  }) async =>
      _jsonMap(await _request(() => _client.post(
            _uri('/api/v1/me/themes'),
            headers: _headers(jsonBody: true),
            body: jsonEncode({
              'name': name,
              'config': config,
              'cover_url': coverUrl,
              'is_public': isPublic,
            }),
          )));

  Future<List<Map<String, dynamic>>> popularThemes() async =>
      _jsonList(await _request(() => _client.get(_uri('/api/v1/themes/popular'), headers: _headers())));

  Future<Map<String, dynamic>> downloadTheme(int id) async =>
      _jsonMap(await _request(() => _client.post(_uri('/api/v1/themes/$id/download'), headers: _headers())));

  Future<Map<String, dynamic>> rateTheme(int id, int rating) async =>
      _jsonMap(await _request(() => _client.post(
            _uri('/api/v1/themes/$id/rating'),
            headers: _headers(jsonBody: true),
            body: jsonEncode({'rating': rating}),
          )));

  Future<Map<String, dynamic>> commentTheme(int id, String body) async =>
      _jsonMap(await _request(() => _client.post(
            _uri('/api/v1/themes/$id/comments'),
            headers: _headers(jsonBody: true),
            body: jsonEncode({'body': body}),
          )));

  Future<Map<String, dynamic>> startImport({
    required String source,
    required String sourceUrl,
  }) async =>
      _jsonMap(await _request(() => _client.post(
            _uri('/api/v1/imports'),
            headers: _headers(jsonBody: true),
            body: jsonEncode({'source': source, 'source_url': sourceUrl}),
          )));

  Future<Map<String, dynamic>> importStatus(int jobId) async =>
      _jsonMap(await _request(() => _client.get(
            _uri('/api/v1/imports/$jobId'),
            headers: _headers(),
          )));

  Future<Map<String, dynamic>?> latestUpdate() async {
    final response = await _request(() => _client.get(
          _uri('/api/v1/updates/latest'),
          headers: _headers(),
        ));
    _ensureSuccess(response);

    final body = response.body.trim();
    if (body.isEmpty || body == 'null') return null;

    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Latest update response must be a JSON object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  void dispose() => _client.close();

  Map<String, dynamic> _jsonMap(http.Response response) {
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Expected a JSON object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  List<Map<String, dynamic>> _jsonList(http.Response response) {
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON array');
    }
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    var message = 'HTTP ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) {
        message = body['detail'].toString();
      }
    } catch (_) {
      // Keep the HTTP status when the server did not return JSON.
    }

    throw Exception(message);
  }
}
