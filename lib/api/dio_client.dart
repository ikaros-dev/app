import 'package:dio/dio.dart';
import 'package:ikaros/api/dio_interceptors.dart';

import 'auth/AuthApi.dart';
import 'auth/AuthParams.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  Dio _dio = Dio();
  BaseOptions _options = BaseOptions();
  bool _isInitialized = false;

  DioClient._internal();

  static DioClient get instance => _instance;

  Future<void> rebuild({String baseUrl = ""}) async {
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
      AuthExpireInterceptor(), // 重试拦截器
    ]);
  }

  void ensureInit() {
    if (!_isInitialized) {
      rebuild().then((_) {
        _isInitialized = true;
      });
    }
  }

  Dio get dio => _dio;
}
