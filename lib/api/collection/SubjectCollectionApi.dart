import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/enums/CollectionType.dart';
import 'package:ikaros/api/collection/model/SubjectCollection.dart';
import 'package:ikaros/api/common/PagingWrap.dart';

class SubjectCollectionApi {
  SubjectCollection error = SubjectCollection(
      id: -1,
      userId: -1,
      subjectId: -1,
      type: CollectionType.WISH,
      isPrivate: false,
      name: "name",
      nsfw: false,
      cover: "cover");
  PagingWrap errors =
      PagingWrap(page: -1, size: -1, total: -1, items: List.empty());

  Future<PagingWrap> fetchSubjectCollections(
      int? page, int? size, CollectionType? type) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return errors;
    }

    page ??= 1;
    size ??= 12;

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String userId = authParams.userId;
    String apiUrl = "$baseUrl/api/v1alpha1/subject/collections/$userId"
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
        return errors;
      }
      return PagingWrap.fromJson(response.data);
    } catch (e) {
      print(e);
      return errors;
    }
  }

  Future<SubjectCollection> findCollectionBySubjectId(int subjectId) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '' ||
        authParams.userId == '') {
      return error;
    }

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String userId = authParams.userId;
    String apiUrl = "$baseUrl/api/v1alpha1/subject/collection/$userId/$subjectId";

    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      var response = await Dio(options).get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return error;
      }
      return SubjectCollection.fromJson(response.data);
    } catch (e) {
      print(e);
      return error;
    }
  }

  Future updateCollection(int subjectId, CollectionType type, bool? isPrivate) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '' ||
        authParams.userId == '') {
      return error;
    }

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String userId = authParams.userId;
    String apiUrl = "$baseUrl/api/v1alpha1/subject/collection/collect"
    "?userId=$userId&subjectId=$subjectId&type=${type.name}";

    if(isPrivate != null) {
      apiUrl = "$apiUrl&isPrivate=$isPrivate";
    }

    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      var response = await Dio(options).post(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return error;
      }
      return ;
    } catch (e) {
      print(e);
      return error;
    }
  }

  Future removeCollection(int subjectId,) async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '' ||
        authParams.userId == '') {
      return error;
    }

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String userId = authParams.userId;
    String apiUrl = "$baseUrl/api/v1alpha1/subject/collection/collect"
    "?userId=$userId&subjectId=$subjectId";

    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      var response = await Dio(options).delete(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return error;
      }
      return ;
    } catch (e) {
      print(e);
      return error;
    }
  }
}
