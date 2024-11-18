import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {

  static const String SharedPreferencesKeyAuthBaseUrl = "AUTH_BASE_URL";
  static const String SharedPreferencesKeyAuthUsername = "AUTH_USERNAME";
  static const String SharedPreferencesKeyAuthPassword = "AUTH_PASSWORD";
  static const String SharedPreferencesKeyUserId = "AUTH_USER_ID";

  Future<AuthParams> getAuthParams() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString(SharedPreferencesKeyAuthUsername);
    String? password = prefs.getString(SharedPreferencesKeyAuthPassword);
    String? baseUrl = prefs.getString(SharedPreferencesKeyAuthBaseUrl);
    String? userId = prefs.getString(SharedPreferencesKeyUserId);
    if(username == null || username.isEmpty
        || password == null || password.isEmpty
        || baseUrl == null || baseUrl.isEmpty) {
      return Future(() => AuthParams());
    }
    var authParams = AuthParams();
    authParams.baseUrl = baseUrl;
    authParams.username = username;
    authParams.password = password;
    authParams.userId = userId!;
    var auth = "Basic ${base64Encode(utf8.encode('$username:$password'))}";
    authParams.basicAuth = auth;
    return Future(() => authParams);
  }

  Future login(String baseUrl, String username, String password) async {
    String url = "$baseUrl/login";
    Response response = await Dio().post(url, data: {
      "username": username,
      "password": password
    }, options: Options(
      contentType: "application/x-www-form-urlencoded"
    ));
    Map<String, dynamic> rspMap = response.data;
    Map<String, dynamic> userMap = rspMap.remove("entity");
    int userId = userMap.remove("id");
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(SharedPreferencesKeyAuthBaseUrl, baseUrl);
    prefs.setString(SharedPreferencesKeyAuthUsername, username);
    prefs.setString(SharedPreferencesKeyAuthPassword, password);
    prefs.setString(SharedPreferencesKeyUserId, userId.toString());
  }

  Future logout()async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    prefs.reload();
  }
}