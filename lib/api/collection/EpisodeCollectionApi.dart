import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/subject/enums/EpisodeGroup.dart';

import 'model/EpisodeCollection.dart';

class EpisodeCollectionApi {
  EpisodeCollection error = EpisodeCollection(
      id: -1,
      userId: -1,
      episodeId: -1,
      name: '',
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
    String apiUrl =
        "$baseUrl/api/v1alpha1/collection/episode/$episodeId";

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

  Future<List<EpisodeCollection>> findListBySubjectId(int subjectId) async {
    List<EpisodeCollection> result = [];
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return result;
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String apiUrl =
        "$baseUrl/api/v1alpha1/collection/episodes/subjectId/$subjectId";

    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      var response = await Dio(options).get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return result;
      }

      var listDynamic = jsonDecode(jsonEncode(response.data));
      List<Map<String, dynamic>> listMap = List<Map<String, dynamic>>.from(listDynamic);
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
        "$baseUrl/api/v1alpha1/collection/episode/$episodeId";

    final queryParams = {
      'progress': seek.inMilliseconds,
      'duration': duration.inMilliseconds,
    };

    BaseOptions options = BaseOptions();
    options.headers.putIfAbsent("Authorization", () => basicAuth);
    debugPrint("apiUrl:$apiUrl");
    // if (kDebugMode) {
    //   print("apiUrl:$apiUrl   basicAuth:$basicAuth");
    // }
    var response = await Dio(options).put(apiUrl, queryParameters: queryParams);
    if (response.statusCode != 200) {
      if (kDebugMode) {
        print("response status code: ${response.statusCode}");
      }
      return;
    }
    if (kDebugMode) {
      print("update episode collection. userId=$userId and episodeId=$episodeId"
        " and currentTime:${seek.inMilliseconds} and duration:${duration.inMilliseconds}");
    }
    return;
  }

  Future updateCollectionFinish(
      int episodeId, bool isFinish) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return;
    }

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String apiUrl =
        "$baseUrl/api/v1alpha1/collection/episode/finish/$episodeId/$isFinish";

    BaseOptions options = BaseOptions();
    options.headers.putIfAbsent("Authorization", () => basicAuth);
    debugPrint("apiUrl:$apiUrl");
    var response = await Dio(options).put(apiUrl);
    if (response.statusCode != 200) {
      print("response status code: ${response.statusCode}");
      return;
    }
    return;
  }









}
