import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'model/IkarosDanmukuEpisodesResponse.dart';

class DandanplaySearchApi {
  Future<IkarosDanmukuEpisodesResponse?> searchEpisodes(
      String anime, String episode) async {
    String apiUrl = "https://danmuku.ikaros.run/api/dandanplay/search/episodes";
    try {
      final queryParams = {
        'anime': anime,
      };

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("User-Agent", () => "ikaros/${Platform.operatingSystem} ${packageInfo.version}");

      // print("queryParams: $queryParams");
      var response = await Dio(options).get(apiUrl, queryParameters: queryParams);
      if (kDebugMode || kProfileMode) {
        print("request search episodes with url:$apiUrl params:$queryParams resp:$response");
      }
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return null;
      }

      return IkarosDanmukuEpisodesResponse.fromJson(response.data);
    } catch (e) {
      print(e);
      return null;
    }
  }
}
