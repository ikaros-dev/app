import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/auth/LoginResult.dart';
import 'package:ikaros/api/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {
  static const String SharedPreferencesKeyAuthBaseUrl = "AUTH_BASE_URL";
  static const String SharedPreferencesKeyAuthUsername = "AUTH_USERNAME";
  static const String SharedPreferencesKeyAuthToken = "AUTH_TOKEN";
  static const String SharedPreferencesKeyAuthRefreshToken = "AUTH_REFRESH_TOKEN";

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

  /// 第一步：用户名密码登录，返回结果可能包含 totpRequired
  Future<LoginResult> login(String baseUrl, String username, String password) async {
    String url = "$baseUrl/api/v1/security/auth/token/jwt/apply";
    try {
      Response response = await Dio().post(url, data: {
        "authType": "USERNAME_PASSWORD",
        "username": username,
        "password": password,
        "phoneNum": "",
        "email": "",
        "code": ""
      });
      var data = response.data is Map ? response.data as Map : {};
      if (data['totpRequired'] == true) {
        return LoginResult(
          success: false,
          totpRequired: true,
          tempToken: data['tempToken']?.toString(),
          message: "需要二步验证，请输入验证码",
        );
      }
      var accessToken = data['accessToken']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        return LoginResult(
          success: false,
          message: data['message']?.toString() ?? "登录失败",
        );
      }
      await _saveCredentials(baseUrl, username,
          accessToken, data['refreshToken']?.toString() ?? "");
      return LoginResult(success: true);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("[AuthApi] login error: type=${e.type}, status=${e.response?.statusCode}, body=${e.response?.data}");
      }
      var msg = "登录失败";
      if (e.response?.data is Map) {
        var data = e.response!.data as Map;
        if (data['totpRequired'] == true) {
          return LoginResult(
            success: false,
            totpRequired: true,
            tempToken: data['tempToken']?.toString(),
            message: "需要二步验证，请输入验证码",
          );
        }
        msg = data['message']?.toString() ?? data['error']?.toString() ?? msg;
      } else if (e.response?.data is String) {
        msg = e.response!.data as String;
      }
      return LoginResult(success: false, message: msg);
    } catch (e) {
      if (kDebugMode) print("[AuthApi] login unexpected error: $e");
      return LoginResult(success: false, message: e.toString());
    }
  }

  /// 第二步：验证TOTP验证码，获取正式JWT令牌
  Future<LoginResult> validateTotp(
      String baseUrl, String tempToken, String code) async {
    String url = "$baseUrl/api/v1/security/auth/totp/validate";
    try {
      Response response = await Dio().post(url, data: {
        "tempToken": tempToken,
        "code": code,
      });
      var data = response.data is Map ? response.data as Map : {};
      var accessToken = data['accessToken']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        return LoginResult(
          success: false,
          message: data['message']?.toString() ?? "验证失败",
        );
      }
      await _saveCredentials(baseUrl, "",
          accessToken, data['refreshToken']?.toString() ?? "");
      return LoginResult(success: true);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("[AuthApi] validateTotp error: status=${e.response?.statusCode}, body=${e.response?.data}");
      }
      var msg = "验证失败";
      if (e.response?.data is Map) {
        var data = e.response!.data as Map;
        msg = data['message']?.toString() ?? data['error']?.toString() ?? msg;
      }
      return LoginResult(success: false, message: msg);
    } catch (e) {
      if (kDebugMode) print("[AuthApi] validateTotp unexpected error: $e");
      return LoginResult(success: false, message: e.toString());
    }
  }

  Future<void> _saveCredentials(String baseUrl, String username,
      String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPreferencesKeyAuthBaseUrl, baseUrl);
    await prefs.setString(SharedPreferencesKeyAuthUsername, username);
    await prefs.setString(SharedPreferencesKeyAuthToken, accessToken);
    await prefs.setString(SharedPreferencesKeyAuthRefreshToken, refreshToken);
    await DioClient.rebuild(baseUrl: baseUrl);
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
