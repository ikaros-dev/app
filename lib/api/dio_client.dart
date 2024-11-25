import 'package:dio/dio.dart';
import 'package:ikaros/api/dio_interceptors.dart';

import 'auth/AuthApi.dart';
import 'auth/AuthParams.dart';

class DioClient {
  static BaseOptions _options = BaseOptions();
  static bool _isInitialized = false;
  static Dio _dio = Dio();

  static Future<Dio> getDio() async {
    if (!_isInitialized) {
      await rebuild();
      _isInitialized = true;
    }
    return _dio;
  }

  static Future<void> rebuild({String baseUrl = ""}) async {
    if (baseUrl != "") {
      _options = BaseOptions(baseUrl: baseUrl);
    } else {
      AuthParams? authParams = await AuthApi().getAuthParams();
      _options = BaseOptions(baseUrl: authParams?.baseUrl ?? "");
    }
    _options.connectTimeout = const Duration(milliseconds: 5000);
    _options.receiveTimeout = const Duration(milliseconds: 5000);
    _dio = Dio(_options);
    // 添加拦截器
    _dio.interceptors.addAll([
      // LogInterceptor(requestBody: true, responseBody: true), // 日志拦截器
      AuthInterceptor(), // 认证拦截器
      AuthExpireInterceptor(), // Token失效重新刷新拦截器
    ]);
  }

}
