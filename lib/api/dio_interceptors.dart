import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';

import 'dio_client.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      debugPrint('[AuthInterceptor] token empty, skip auth header for ${options.path}');
    }
    super.onRequest(options, handler);
  }

  Future<String?> getToken() async {
    AuthParams? authParams = await AuthApi().getAuthParams();
    if (authParams == null) {
      debugPrint('[AuthInterceptor] getAuthParams returned null');
      return "";
    }
    return authParams.token;
  }
}

class AuthExpireInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('[AuthExpireInterceptor] status=${err.response?.statusCode}, path=${err.requestOptions.path}');
    if (err.response?.statusCode == 401) {
      AuthParams? authParams = await AuthApi().getAuthParams();
      if (authParams == null) {
        debugPrint('[AuthExpireInterceptor] no auth params, logout');
        await AuthApi().logout();
      } else {
        try {
          debugPrint('[AuthExpireInterceptor] refreshing token');
          String newToken = await AuthApi().refreshToken(authParams.refreshToken);
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
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
          return handler.resolve(retryResponse);
        } catch (e) {
          debugPrint('[AuthExpireInterceptor] refresh failed: $e');
          await AuthApi().logout();
          return handler.reject(err);
        }
      }
    }
    handler.next(err);
  }
}
