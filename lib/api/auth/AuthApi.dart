import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {

  static const String SharedPreferencesKeyAuthBaseUrl = "AUTH_BASE_URL";
  static const String SharedPreferencesKeyAuthUsername = "AUTH_USERNAME";
  static const String SharedPreferencesKeyAuthPassword = "AUTH_PASSWORD";

  Future<AuthParams> getAuthParams() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString(SharedPreferencesKeyAuthUsername);
    String? password = prefs.getString(SharedPreferencesKeyAuthPassword);
    String? baseUrl = prefs.getString(SharedPreferencesKeyAuthBaseUrl);
    if(username == null || username.isEmpty
        || password == null || password.isEmpty
        || baseUrl == null || baseUrl.isEmpty) {
      return Future(() => AuthParams());
    }
    var authParams = AuthParams();
    authParams.baseUrl = baseUrl;
    authParams.username = username;
    authParams.password = password;
    var auth = "Basic ${base64Encode(utf8.encode('$username:$password'))}";
    authParams.basicAuth = auth;
    return Future(() => authParams);
  }
  Future login(String baseUrl, String username, String password) async {
    String url = "$baseUrl/login";
    await Dio().post(url, data: {
      "username": username,
      "password": password
    }, options: Options(
      contentType: "application/x-www-form-urlencoded"
    ));
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(SharedPreferencesKeyAuthBaseUrl, baseUrl);
    prefs.setString(SharedPreferencesKeyAuthUsername, username);
    prefs.setString(SharedPreferencesKeyAuthPassword, password);
  }
}