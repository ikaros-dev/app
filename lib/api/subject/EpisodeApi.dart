import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';

import 'model/Episode.dart';
import 'model/Subject.dart';

class EpisodeApi {

  Episode error = Episode(id: -1, subjectId: -1, name: "", sequence: -1);

  Future<Episode> findById(int id) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if(authParams.baseUrl == '' || authParams.username == ''
        || authParams.basicAuth == '') {
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
      if(response.statusCode != 200) {
        return error;
      }
      return Episode.fromJson(response.data);
    } catch (e) {
      print(e);
      return error;
    }
  }
}



