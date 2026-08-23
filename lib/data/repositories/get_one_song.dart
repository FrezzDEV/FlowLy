import 'dart:convert';

import 'package:http/http.dart';
import 'package:flowly/core/network/url.dart';
import 'package:flowly/core/utils/get_response.dart';
import 'package:flowly/domain/entities/song_model.dart';

class GetOneSong {
  Future<SongModel> getSongs(String name) async {
    Response res =
        await getResponse(Uri.https(baseUrl, basePath + '/songs/one/' + name));
    if (res.statusCode == 200) {
      var body = jsonDecode(res.body);

      return SongModel.fromJson(body['results'][0]);
    } else {
      throw Exception("failed fetch users ");
    }
  }
}
