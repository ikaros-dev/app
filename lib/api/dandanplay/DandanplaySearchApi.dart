import 'package:dio/dio.dart';

import 'model/SearchEpisodesResponse.dart';

class DandanplaySearchApi {
  Future<SearchEpisodesResponse?> searchEpisodes(
      String anime, String episode) async {
    String apiUrl = "https://api.dandanplay.net/api/v2/search/episodes";
    try {
      final queryParams = {
        'anime': anime,
        'episode': episode,
      };

      // print("queryParams: $queryParams");
      var response = await Dio().get(apiUrl, queryParameters: queryParams);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return null;
      }

      return SearchEpisodesResponse.fromJson(response.data);
    } catch (e) {
      print(e);
      return null;
    }
  }
}
