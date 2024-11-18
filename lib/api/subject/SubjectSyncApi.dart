import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/api/subject/model/SubjectSync.dart';

import 'model/Subject.dart';

class SubjectSyncApi {
  Future<List<SubjectSync>> getSyncsBySubjectId(int subjectId) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.authHeader == '') {
      return List.empty();
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.authHeader;
    String apiUrl = "$baseUrl/api/v1alpha1/subject/syncs/subjectId/$subjectId";
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
      List<SubjectSync> syncs = [];
      for (var e in response.data??List.empty()) {
        syncs.add(SubjectSync.fromJson(e));
      }
      return syncs;
    } catch (e) {
      print(e);
      return List.empty();
    }
  }
}
