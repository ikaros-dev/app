import 'package:flutter/foundation.dart';
import 'package:ikaros/api/dio_client.dart';
import 'package:ikaros/api/search/model/SubjectSearchResult.dart';

class IndicesApi {
  Future<SubjectSearchResult?> searchSubject(String keyword, int limit) async {
    if (limit <= 0) limit = 20;
    String apiUrl = "/api/v1alpha1/indices/subject";
    try {
      final queryParams = {
        'limit': limit,
        'keyword': keyword,
        'highlightPreTag': "<B>",
        'highlightPostTag': "<\/B>",
        // 在这里添加更多查询参数
      };

      var response = await DioClient.instance.dio
          .get(apiUrl, queryParameters: queryParams);
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
