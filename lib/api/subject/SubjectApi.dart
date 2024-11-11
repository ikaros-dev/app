import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';

import 'model/Subject.dart';

class SubjectApi {
  Subject error = Subject(
      id: -1,
      type: SubjectType.OTHER,
      name: "-1",
      nsfw: false,
      cover: "-1",
      nameCn: '',
      infobox: '',
      summary: '',
      airTime: '');

  Future<PagingWrap> listSubjectsByCondition(int page, int size, String name,
      String nameCn, bool nsfw, SubjectType? type) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return Future(() =>
          PagingWrap(page: page, size: size, total: 0, items: List.empty()));
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String apiUrl = "$baseUrl/api/v1alpha1/subjects/condition";
    try {
      final queryParams = {
        'page': page,
        'size': size,
        'name': base64Encode(utf8.encode(name)),
        'nameCn': base64Encode(utf8.encode(nameCn)),
        'nsfw': nsfw,
        'type': type?.name,
        // 在这里添加更多查询参数
      };

      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      // print("queryParams: $queryParams");
      var response =
          await Dio(options).get(apiUrl, queryParameters: queryParams);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return PagingWrap(
            page: page, size: size, total: 0, items: List.empty());
      }
      return PagingWrap.fromJson(response.data);
    } catch (e) {
      print(e);
      return PagingWrap(page: page, size: size, total: 0, items: List.empty());
    }
  }

  Future<Subject> findById(int id) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return Future(() => error);
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String apiUrl = "$baseUrl/api/v1alpha1/subject/$id";
    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      // print("queryParams: $queryParams");
      var response = await Dio(options).get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return error;
      }
      return Subject.fromJson(response.data);
    } catch (e) {
      print(e);
      return error;
    }
  }
}
