import 'dart:convert';

import 'package:http/http.dart';
import 'package:flowly/core/network/url.dart';
import 'package:flowly/core/utils/get_response.dart';
import 'package:flowly/domain/entities/song_model.dart';
import 'package:flowly/domain/entities/user.dart';

class GetHomePage {
  Future<List<User>> getUsers() async {
    final query = {
      'page': '0',
      'limit': '26',
    };
    final Response response = await getResponse(
      Uri.https(baseUrl, '$basePath/users', query),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load users: HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'];
    if (results is! List) return const [];

    return results
        .map((user) => User.fromJson(user as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<SongModel>> getSongs() async {
    final response = await getResponse(
      Uri.https(baseUrl, '$basePath/songs/random/all', {'limit': '30'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load songs: HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'];
    if (results is! List) return const [];

    return results
        .map((song) => SongModel.fromJson(song as Map<String, dynamic>))
        .toList(growable: false);
  }
}
