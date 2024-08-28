import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'model/CommentEpisodeIdResponse.dart';

class DandanplayCommentApi {
  /// chConvert 中文简繁转换。0-不转换，1-转换为简体，2-转换为繁体。
  Future<CommentEpisodeIdResponse?> commentEpisodeId(
      int episodeId, int chConvert) async {
    String apiUrl = "https://api.dandanplay.net/api/v2/comment/$episodeId";
    try {
      final queryParams = {
        'chConvert': chConvert,
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

      return CommentEpisodeIdResponse.fromJson(response.data);
    } catch (e) {
      print(e);
      return null;
    }
  }
}