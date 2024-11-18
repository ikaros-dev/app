import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/search/model/SubjectSearchResult.dart';

class IndicesApi {
  Future<SubjectSearchResult?> searchSubject(String keyword, int limit) async {
    if (limit <= 0) limit = 20;
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.authHeader == '') {
      return null;
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.authHeader;
    String apiUrl = "$baseUrl/api/v1alpha1/indices/subject";
    try {
      final queryParams = {
        'limit': limit,
        'keyword': keyword,
        'highlightPreTag': "<B>",
        'highlightPostTag': "<\/B>",
        // 在这里添加更多查询参数
      };

      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      // print("queryParams: $queryParams");
      var response = await Dio(options).get(apiUrl, queryParameters: queryParams);
      if (response.statusCode != 200) {
        return null;
      }
      return SubjectSearchResult.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }
}
