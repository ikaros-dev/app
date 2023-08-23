import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/enums/CollectionType.dart';
import 'package:ikaros/api/collection/model/SubjectCollection.dart';
import 'package:ikaros/api/common/PagingWrap.dart';

class SubjectCollectionApi {
  PagingWrap error = PagingWrap(page: -1, size: -1, total: -1, items: List.empty());

  Future<PagingWrap> fetchSubjectCollections(int? page, int? size, CollectionType? type) async  {

    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.basicAuth == '') {
      return error;
    }

    page ??= 1;
    size ??= 12;

    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.basicAuth;
    String userId = authParams.userId;
    String apiUrl =
        "$baseUrl/api/v1alpha1/collection/subject/$userId"
    "?page=$page&size=$size";
    if(type !=  null) {
      apiUrl = "${apiUrl}&type=${type.name}";
    }


    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      var response = await Dio(options).get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return error;
      }
      return PagingWrap.fromJson(response.data);
    } catch (e) {
      print(e);
      return error;
    }
  }
}