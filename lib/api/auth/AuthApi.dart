import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {
  static const String SharedPreferencesKeyAuthBaseUrl = "AUTH_BASE_URL";
  static const String SharedPreferencesKeyAuthUsername = "AUTH_USERNAME";
  static const String SharedPreferencesKeyAuthToken = "AUTH_Token";

  Future<AuthParams> getAuthParams() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString(SharedPreferencesKeyAuthUsername);
    String? token = prefs.getString(SharedPreferencesKeyAuthToken);
    String? baseUrl = prefs.getString(SharedPreferencesKeyAuthBaseUrl);
    if (username == null ||
        username.isEmpty ||
        token == null ||
        token.isEmpty ||
        baseUrl == null ||
        baseUrl.isEmpty) {
      return Future(() => AuthParams());
    }
    var authParams = AuthParams();
    authParams.baseUrl = baseUrl;
    authParams.username = username;
    authParams.token = token;
    var auth = "Bearer $token";
    authParams.authHeader = auth;
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
    prefs.setString(SharedPreferencesKeyAuthToken, response.data);
  }

  Future logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    prefs.reload();
  }
}
