import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/enums/CollectionType.dart';
import 'package:ikaros/api/collection/model/SubjectCollection.dart';
import 'package:ikaros/api/common/PagingWrap.dart';

class SubjectCollectionApi {

  Future<PagingWrap?> fetchSubjectCollections(
      int? page, int? size, CollectionType? type) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.authHeader == '') {
      return null;
    }

    page ??= 1;
    size ??= 12;

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.authHeader;
    String apiUrl = "$baseUrl/api/v1alpha1/collection/subjects"
        "?page=$page&size=$size";
    if (type != null) {
      apiUrl = "${apiUrl}&type=${type.name}";
    }

    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      var response = await Dio(options).get(apiUrl);
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
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.authHeader == '' ) {
      return null;
    }

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.authHeader;
    String apiUrl = "$baseUrl/api/v1alpha1/collection/subject/$subjectId";

    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      var response = await Dio(options).get(apiUrl);
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

  Future<void> updateCollection(int subjectId, CollectionType? type, bool? isPrivate) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.authHeader == '') {
      return;
    }

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.authHeader;
    String apiUrl = "$baseUrl/api/v1alpha1/collection/subject/collect"
    "?subjectId=$subjectId";
    if (type != null) {
      apiUrl += "&type=${type.name}";
    }

    if(isPrivate != null) {
      apiUrl = "$apiUrl&isPrivate=$isPrivate";
    }

    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      var response = await Dio(options).post(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return;
      }
      return ;
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> removeCollection(int subjectId,) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.authHeader == '') {
      return;
    }

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.authHeader;
    String apiUrl = "$baseUrl/api/v1alpha1/collection/subject/collect"
    "?subjectId=$subjectId";

    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      var response = await Dio(options).delete(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return;
      }
      return ;
    } catch (e) {
      print(e);
      return;
    }
  }
}
