import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
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

  Future login(String baseUrl, String username, String password) async {
    String url = "$baseUrl/api/v1alpha1/security/auth/token/jwt/apply";
    Response response = await Dio().post(url, data: {
      "authType": "USERNAME_PASSWORD",
      "username": username,
      "password": password,
      "phoneNum": "",
      "email": "",
      "code": ""
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPreferencesKeyAuthBaseUrl, baseUrl);
    await prefs.setString(SharedPreferencesKeyAuthUsername, username);
    await prefs.setString(SharedPreferencesKeyAuthToken, response.data['accessToken']);
    await prefs.setString(SharedPreferencesKeyAuthRefreshToken, response.data['refreshToken']);
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
    String url = "/api/v1alpha1/security/auth/token/jwt/refresh";
    Dio dio = await DioClient.getDio();
    var response = await dio.put(url, data: refreshToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPreferencesKeyAuthToken, response.data);
    return response.data;
  }
}
