import 'package:dio/dio.dart';
import 'package:ikaros/api/collection/enums/CollectionType.dart';
import 'package:ikaros/api/collection/model/SubjectCollection.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/dio_client.dart';

class SubjectCollectionApi {



  Future<PagingWrap?> fetchSubjectCollections(
      int? page, int? size, CollectionType? type) async {
    page ??= 1;
    size ??= 12;

    String apiUrl = "/api/v1alpha1/collection/subjects"
        "?page=$page&size=$size";
    if (type != null) {
      apiUrl = "$apiUrl&type=${type.name}";
    }

    try {
      Dio dio = await DioClient.getDio();
      var response = await dio.get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return null;
      }
      return PagingWrap.fromJson(response.data);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<SubjectCollection?> findCollectionBySubjectId(int subjectId) async {
    String apiUrl = "/api/v1alpha1/collection/subject/$subjectId";
    try {
      Dio dio = await DioClient.getDio();
      var response = await dio.get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return null;
      }
      return SubjectCollection.fromJson(response.data);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> updateCollection(
      int subjectId, CollectionType? type, bool? isPrivate) async {
    String apiUrl = "/api/v1alpha1/collection/subject/collect"
        "?subjectId=$subjectId";
    if (type != null) {
      apiUrl += "&type=${type.name}";
    }

    if (isPrivate != null) {
      apiUrl = "$apiUrl&isPrivate=$isPrivate";
    }

    try {
      Dio dio = await DioClient.getDio();
      var response = await dio.post(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return;
      }
      return;
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> removeCollection(int subjectId) async {
    String apiUrl = "/api/v1alpha1/collection/subject/collect"
        "?subjectId=$subjectId";
    try {
      Dio dio = await DioClient.getDio();
      var response = await dio.delete(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return;
      }
      return;
    } catch (e) {
      print(e);
      return;
    }
  }
}
