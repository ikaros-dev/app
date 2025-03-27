import 'package:dio/dio.dart';
import 'package:ikaros/api/dio_client.dart';
import 'package:ikaros/api/subject/model/SubjectRelation.dart';

class SubjectRelationApi {
  Future<List<SubjectRelation>> findById(int id) async {
    String apiUrl = "/api/v1alpha1/subject/relations/$id";
    try {
      // print("queryParams: $queryParams");
      Dio dio = await DioClient.getDio();
      var response = await dio.get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return [];
      }
      List<dynamic> data = response.data;
      List<SubjectRelation> results =
          data.map((json) => SubjectRelation.fromJson(json)).toList();
      return results;
    } catch (e) {
      print(e);
      return [];
    }
  }
}
