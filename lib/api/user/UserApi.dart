import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ikaros/api/dio_client.dart';

import 'model/User.dart';

class UserApi {
  Future<User?> getMe() async {
    String apiUrl = "/api/v1alpha1/user/me";
    try {
      Dio dio = await DioClient.getDio();
      Response response = await dio.get(apiUrl);
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
