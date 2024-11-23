import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/dio_client.dart';

import 'model/EpisodeCollection.dart';

class EpisodeCollectionApi {
  Future<EpisodeCollection?> findCollection(int episodeId) async {
    String apiUrl = "/api/v1alpha1/collection/episode/$episodeId";
    try {
      var response = await DioClient.instance.dio.get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return null;
      }
      return EpisodeCollection.fromJson(response.data);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<List<EpisodeCollection>> findListBySubjectId(int subjectId) async {
    List<EpisodeCollection> result = [];

    String apiUrl = "/api/v1alpha1/collection/episodes/subjectId/$subjectId";
    try {
      var response = await DioClient.instance.dio.get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return result;
      }

      var listDynamic = jsonDecode(jsonEncode(response.data));
      List<Map<String, dynamic>> listMap =
          List<Map<String, dynamic>>.from(listDynamic);
      for (var m in listMap) {
        result.add(EpisodeCollection.fromJson(m));
      }
    } catch (e) {
      print(e);
      return result;
    }

    return result;
  }

  Future updateCollection(
      int episodeId, Duration seek, Duration duration) async {
    String apiUrl = "/api/v1alpha1/collection/episode/$episodeId";

    final queryParams = {
      'progress': seek.inMilliseconds,
      'duration': duration.inMilliseconds,
    };

    // if (kDebugMode) {
    //   print("apiUrl:$apiUrl   basicAuth:$basicAuth");
    // }
    var response = await DioClient.instance.dio.put(apiUrl, queryParameters: queryParams);
    if (response.statusCode != 200) {
      if (kDebugMode) {
        print("response status code: ${response.statusCode}");
      }
      return;
    }
    if (kDebugMode) {
      print("update episode collection. and episodeId=$episodeId"
          " and currentTime:${seek.inMilliseconds} and duration:${duration.inMilliseconds}");
    }
    return;
  }

  Future updateCollectionFinish(int episodeId, bool isFinish) async {
    String apiUrl =
        "/api/v1alpha1/collection/episode/finish/$episodeId/$isFinish";
    var response = await DioClient.instance.dio.put(apiUrl);
    if (response.statusCode != 200) {
      print("response status code: ${response.statusCode}");
      return;
    }
    return;
  }
}
