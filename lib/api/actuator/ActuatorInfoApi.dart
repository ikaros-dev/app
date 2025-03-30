import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ikaros/api/dio_client.dart';

class ActuatorInfo {
  Future<String?> getVersion() async {
    String apiUrl = "/actuator/info";
    try {
      Dio dio = await DioClient.getDio();
      Response response = await dio.get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return null;
      }
      Map<String, dynamic> data = response.data;
      return data['build']['version'];
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }
}