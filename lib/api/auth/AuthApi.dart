import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/auth/LoginResult.dart';
import 'package:ikaros/api/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {
  static const String SharedPreferencesKeyAuthBaseUrl = "AUTH_BASE_URL";
  static const String SharedPreferencesKeyAuthUsername = "AUTH_USERNAME";
  static const String SharedPreferencesKeyAuthToken = "AUTH_Token";
  static const String SharedPreferencesKeyAuthRefreshToken = "AUTH_Refresh_Token";

  Future<AuthParams?> getAuthParams() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString(SharedPreferencesKeyAuthUsername);
    String? token = prefs.getString(SharedPreferencesKeyAuthToken);
    String? baseUrl = prefs.getString(SharedPreferencesKeyAuthBaseUrl);
    String? refreshToken = prefs.getString(SharedPreferencesKeyAuthRefreshToken);
    if (username == null ||
        username.isEmpty ||
        token == null ||
        token.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        baseUrl == null ||
        baseUrl.isEmpty) {
      return Future(() => null);
    }
    var authParams = AuthParams();
    authParams.baseUrl = baseUrl;
    authParams.username = username;
    authParams.token = token;
    authParams.refreshToken = refreshToken;
    return Future(() => authParams);
  }

  Future<LoginResult> login(String baseUrl, String username, String password,
      {String code = ""}) async {
    String url = "$baseUrl/api/v1/security/auth/token/jwt/apply";
    try {
      Response response = await Dio().post(url, data: {
        "authType": "USERNAME_PASSWORD",
        "username": username,
        "password": password,
        "phoneNum": "",
        "email": "",
        "code": code
      });
      // 检测是否需要2FA
      if (response.data is Map &&
          response.data['twoFactorRequired'] == true) {
        return LoginResult(
            success: false,
            twoFactorRequired: true,
            message: "需要两步验证，请输入验证码");
      }
      // 登录成功，保存凭据
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPreferencesKeyAuthBaseUrl, baseUrl);
      await prefs.setString(SharedPreferencesKeyAuthUsername, username);
      await prefs.setString(
          SharedPreferencesKeyAuthToken, response.data['accessToken']);
      await prefs.setString(
          SharedPreferencesKeyAuthRefreshToken, response.data['refreshToken']);
      await DioClient.rebuild(baseUrl: baseUrl);
      return LoginResult(success: true);
    } on DioException catch (e) {
      var msg = "登录失败";
      if (e.response?.data is Map) {
        var data = e.response!.data as Map;
        if (data['twoFactorRequired'] == true) {
          return LoginResult(
              success: false,
              twoFactorRequired: true,
              message: "需要两步验证，请输入验证码");
        }
        if (data['message'] != null) {
          msg = data['message'].toString();
        }
      }
      return LoginResult(success: false, message: msg);
    }
  }

  Future logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPreferencesKeyAuthBaseUrl);
    await prefs.remove(SharedPreferencesKeyAuthUsername);
    await prefs.remove(SharedPreferencesKeyAuthToken);
    await prefs.remove(SharedPreferencesKeyAuthRefreshToken);
  }

  Future<String> refreshToken(String refreshToken) async {
    String url = "/api/v1/security/auth/token/jwt/refresh";
    Dio dio = await DioClient.getDio();
    var response = await dio.put(url, data: refreshToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPreferencesKeyAuthToken, response.data);
    return response.data;
  }
}
