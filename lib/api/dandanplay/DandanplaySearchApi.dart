import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("User-Agent", () => "ikaros/${Platform.operatingSystem} ${packageInfo.version}");

      // print("queryParams: $queryParams");
      var response = await Dio(options).get(apiUrl, queryParameters: queryParams);
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
