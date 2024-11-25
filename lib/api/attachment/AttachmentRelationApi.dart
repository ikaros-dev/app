import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ikaros/api/attachment/model/VideoSubtitle.dart';
import 'package:ikaros/api/dio_client.dart';

class AttachmentRelationApi {
  Future<List<VideoSubtitle>> findByAttachmentId(int attachmentId) async {
    String apiUrl =
        "/api/v1alpha1/attachment/relation/videoSubtitle/subtitles/$attachmentId";
    try {
      // print("queryParams: $queryParams");
      Dio dio = await DioClient.getDio();
      var response = await dio.get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return [];
      }

      var listDynamic = jsonDecode(jsonEncode(response.data));

      List<Map<String, dynamic>> listMap =
          List<Map<String, dynamic>>.from(listDynamic);
      List<VideoSubtitle> videoSubtitles = [];
      for (var m in listMap) {
        videoSubtitles.add(VideoSubtitle.fromJson(m));
      }

      return videoSubtitles;
    } catch (e) {
      print(e);
      return [];
    }
  }
}
