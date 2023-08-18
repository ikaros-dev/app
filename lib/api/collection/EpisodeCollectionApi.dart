import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/enums/EpisodeGroup.dart';

import 'model/EpisodeCollection.dart';

class EpisodeCollectionApi {
  EpisodeCollection error = EpisodeCollection(
      id: -1,
      userId: -1,
      episodeId: -1,
      name: '',
      sequence: -1,
      group: EpisodeGroup.MAIN);

  Future<EpisodeCollection> findCollection(int episodeId) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return error;
    }

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String userId = authParams.userId;
    String apiUrl =
        "$baseUrl/api/v1alpha1/collection/episode/$userId/$episodeId";

    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      var response = await Dio(options).get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return error;
      }
      return EpisodeCollection.fromJson(response.data);
    } catch (e) {
      print(e);
      return error;
    }
  }

  Future updateCollection(
      int episodeId, Duration seek, Duration duration) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return;
    }

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String userId = authParams.userId;
    String apiUrl =
        "$baseUrl/api/v1alpha1/collection/episode/$userId/$episodeId";

    final queryParams = {
      'progress': seek.inMilliseconds,
      'duration': duration.inMilliseconds,
    };

    BaseOptions options = BaseOptions();
    options.headers.putIfAbsent("Authorization", () => basicAuth);
    print("apiUrl:$apiUrl   basicAuth:$basicAuth");
    var response = await Dio(options).put(apiUrl, queryParameters: queryParams);
    if (response.statusCode != 200) {
      print("response status code: ${response.statusCode}");
      return;
    }
    print("update episode collection. userId=$userId and episodeId=$episodeId"
        " and currentTime:${seek.inMilliseconds} and duration:${duration.inMilliseconds}");
    return;
  }
}
