
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';

import 'model/User.dart';

class UserApi {

  Future<User?> getMe() async {
    AuthParams authParams = await AuthApi().getAuthParams();
    if (authParams.baseUrl == '' ||
        authParams.username == '' ||
        authParams.authHeader == '') {
      return null;
    }
    String baseUrl = authParams.baseUrl;
    String basicAuth = authParams.authHeader;
    String apiUrl = "$baseUrl/api/v1alpha1/user/me";
    try {
      BaseOptions options = BaseOptions();
      options.headers.putIfAbsent("Authorization", () => basicAuth);

      Response response =
          await Dio(options).get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return null;
      }
      Map<String, dynamic> data = response.data;
      return User.fromJson(data['entity']);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

}