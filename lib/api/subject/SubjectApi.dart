import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/dio_client.dart';

import 'model/Subject.dart';

class SubjectApi {
  Future<PagingWrap> listSubjectsByCondition(
      int page, int size, String name, String nameCn, bool? nsfw, String? type,
      {String? time, bool? airTimeDesc, bool? updateTimeDesc}) async {
    String apiUrl = "/api/v1alpha1/subjects/condition";
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

      debugPrint("queryParams: $queryParams");
      var response = await DioClient.instance.dio
          .get(apiUrl, queryParameters: queryParams);
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

  Future<Subject?> findById(int id) async {
    String apiUrl = "/api/v1alpha1/subject/$id";
    try {
      // print("queryParams: $queryParams");
      var response = await DioClient.instance.dio.get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return null;
      }
      return Subject.fromJson(response.data);
    } catch (e) {
      print(e);
      return null;
    }
  }
}
