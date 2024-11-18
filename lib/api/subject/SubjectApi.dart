import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
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

  Future<PagingWrap> listSubjectsByCondition(
      int page, int size, String name, String nameCn, bool? nsfw, String? type,
      {String? time, bool? airTimeDesc, bool? updateTimeDesc}) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.authHeader == '') {
      return Future(() =>
          PagingWrap(page: page, size: size, total: 0, items: List.empty()));
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.authHeader;
    String apiUrl = "$baseUrl/api/v1alpha1/subjects/condition";
    try {
      final Map<String, Object?> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'name': base64Encode(utf8.encode(name)),
        'nameCn': base64Encode(utf8.encode(nameCn)),
        'nsfw': nsfw,
        // 在这里添加更多查询参数
      };
      if (type != null && type != "") {
        queryParams.putIfAbsent("type", () => type);
      }
      if (time != null && time != "") {
        queryParams.putIfAbsent("time", () => time);
      }
      if (airTimeDesc != null) {
        queryParams.putIfAbsent("airTimeDesc", () => airTimeDesc);
      }
      if (updateTimeDesc != null) {
        queryParams.putIfAbsent("updateTimeDesc", () => updateTimeDesc);
      }

      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      debugPrint("queryParams: $queryParams");
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
        authParams.authHeader == '') {
      return Future(() => error);
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.authHeader;
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
