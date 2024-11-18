import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ikaros/api/attachment/model/VideoSubtitle.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';

class AttachmentRelationApi {
  VideoSubtitle error = VideoSubtitle(attachmentId: -1, name: "", url: "");

  Future<List<VideoSubtitle>> findByAttachmentId(int attachmentId) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.authHeader == '') {
      return Future(() => [error]);
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.authHeader;
    String apiUrl =
        "$baseUrl/api/v1alpha1/attachment/relation/videoSubtitle/subtitles/$attachmentId";
    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      // print("queryParams: $queryParams");
      var response = await Dio(options).get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return [error];
      }

      var listDynamic = jsonDecode(jsonEncode(response.data));

      List<Map<String, dynamic>> listMap = List<Map<String, dynamic>>.from(listDynamic);
      List<VideoSubtitle> videoSubtitles = [];
      for (var m in listMap) {
        videoSubtitles.add(VideoSubtitle.fromJson(m));
      }

      return videoSubtitles;
    } catch (e) {
      print(e);
      return [error];
    }
  }
}
