import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'model/IkarosDanmukuBangumiResponse.dart';
import 'model/IkarosDanmukuEpisodesResponse.dart';

class DandanplayBangumiApi {
  Future<IkarosDanmukuBangumiResponse?> getBangumiDetailsByBgmtvSubjectId(
      String bgmtvSubjectId) async {
    String apiUrl = "https://danmuku.ikaros.run/api/dandanplay/v2/bangumi/bgmtv/" + bgmtvSubjectId;
    try {

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("User-Agent", () => "ikaros/${Platform.operatingSystem} ${packageInfo.version}");

      // print("queryParams: $queryParams");
      var response = await Dio(options).get(apiUrl);
      if (kDebugMode || kProfileMode) {
        print("request search episodes with url:$apiUrl resp:$response");
      }
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return null;
      }

      return IkarosDanmukuBangumiResponse.fromJson(response.data);
    } catch (e) {
      print(e);
      return null;
    }
  }
}
