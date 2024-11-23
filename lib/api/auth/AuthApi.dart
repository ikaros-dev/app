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
    prefs.setString(SharedPreferencesKeyAuthBaseUrl, baseUrl);
    prefs.setString(SharedPreferencesKeyAuthUsername, username);
    prefs.setString(SharedPreferencesKeyAuthToken, response.data['accessToken']);
    prefs.setString(SharedPreferencesKeyAuthRefreshToken, response.data['refreshToken']);
    DioClient.instance.rebuild(baseUrl: baseUrl);
  }

  Future logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(SharedPreferencesKeyAuthBaseUrl);
    prefs.remove(SharedPreferencesKeyAuthUsername);
    prefs.remove(SharedPreferencesKeyAuthToken);
    prefs.remove(SharedPreferencesKeyAuthRefreshToken);
    prefs.reload();
  }

  Future<String> refreshToken(String refreshToken) async {
    String url = "/api/v1alpha1/security/auth/token/jwt/refresh";
    var response = await DioClient.instance.dio.put(url);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(SharedPreferencesKeyAuthToken, response.data);
    return response.data;
  }
}
