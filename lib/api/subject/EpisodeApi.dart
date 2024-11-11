import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/api/subject/model/EpisodeRecord.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';

import 'model/Episode.dart';
import 'model/Subject.dart';

class EpisodeApi {
  Episode error = Episode(id: -1, subjectId: -1, name: "", sequence: -1);

  Future<Episode> findById(int id) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return Future(() => error);
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String apiUrl = "$baseUrl/api/v1alpha1/episode/$id";
    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      // print("queryParams: $queryParams");
      var response = await Dio(options).get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return error;
      }
      return Episode.fromJson(response.data);
    } catch (e) {
      print(e);
      return error;
    }
  }

  Future<List<Episode>> findBySubjectId(int subjectId) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return Future(() => List.empty());
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String apiUrl = "$baseUrl/api/v1alpha1/episodes/subjectId/$subjectId";
    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      // print("queryParams: $queryParams");
      Response<List<dynamic>?> response =
          await Dio(options).get<List>(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return List.empty();
      }
      List<Episode> episodes = [];
      for (var e in response.data??List.empty()) {
        Episode episode = Episode.fromJson(e);
        episodes.add(episode);
      }
      return episodes;
    } catch (e) {
      print(e);
      return List.empty();
    }
  }

  Future<List<EpisodeRecord>> findRecordsBySubjectId(int subjectId) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return Future(() => List.empty());
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String apiUrl = "$baseUrl/api/v1alpha1/episode/records/subjectId/$subjectId";
    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      // print("queryParams: $queryParams");
      Response<List<dynamic>?> response =
          await Dio(options).get<List>(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return List.empty();
      }
      List<EpisodeRecord> records = [];
      for (var e in response.data??List.empty()) {
        EpisodeRecord record = EpisodeRecord.fromJson(e);
        records.add(record);
      }
      return records;
    } catch (e) {
      print(e);
      return List.empty();
    }
  }


  Future<List<EpisodeResource>> getEpisodeResourcesRefs(int id) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return Future(() => List.empty());
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String apiUrl = "$baseUrl/api/v1alpha1/episode/attachment/refs/$id";
    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      // print("queryParams: $queryParams");
      Response<List<dynamic>?> response =
          await Dio(options).get<List>(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return List.empty();
      }
      List<EpisodeResource> resources = [];
      for (var e in response.data??List.empty()) {
        EpisodeResource resource = EpisodeResource.fromJson(e);
        resources.add(resource);
      }
      return resources;
    } catch (e) {
      print(e);
      return List.empty();
    }
  }
}
