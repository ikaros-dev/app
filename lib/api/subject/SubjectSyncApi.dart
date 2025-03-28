
import 'package:dio/dio.dart';
import 'package:ikaros/api/dio_client.dart';
import 'package:ikaros/api/subject/model/SubjectSync.dart';


class SubjectSyncApi {
  Future<List<SubjectSync>> getSyncsBySubjectId(int subjectId) async {
    String apiUrl = "/api/v1alpha1/subject/syncs/subjectId/$subjectId";
    try {

      // print("queryParams: $queryParams");
      Dio dio = await DioClient.getDio();
      Response<List<dynamic>?> response = await dio.get<List>(apiUrl);
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
