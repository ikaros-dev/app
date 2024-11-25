import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';

import 'dio_client.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await getToken(); // 从本地存储获取 Token
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  Future<String?> getToken() async {
    AuthParams? authParams = await AuthApi().getAuthParams();
    if (authParams == null) return "";
    return authParams.token;
  }
}

class AuthExpireInterceptor extends Interceptor {

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('Error: ${err.response?.statusCode}');
    if (err.response?.statusCode == 401) {
      AuthParams? authParams = await AuthApi().getAuthParams();
      if (authParams == null) {
        await AuthApi().logout();
      } else {
        try {
          String newToken = await AuthApi().refreshToken(authParams.refreshToken);
          // 2. 更新请求头
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';

          // 3. 重新发起请求
          final dio = await DioClient.getDio();
          final retryResponse = await dio.request(
            options.path,
            options: Options(
              method: options.method,
              headers: options.headers,
            ),
            data: options.data,
            queryParameters: options.queryParameters,
          );

          // 成功则将结果返回
          return handler.resolve(retryResponse);
        } catch (e) {
          // 刷新 Token 或重试失败，抛出错误
          await AuthApi().logout();
          return handler.reject(err);
        }
      }
    }

    // 对于其他错误，直接抛出
    handler.next(err);
  }
}
