import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';

/// Subsonic API 客户端.
/// 用于音频流播放和音乐库浏览.
class SubsonicApi {
  /// 获取歌曲的音频流 URL
  static Future<String> getStreamUrl(String songId) async {
    AuthParams? authParams = await AuthApi().getAuthParams();
    if (authParams == null || authParams.baseUrl.isEmpty) {
      return "";
    }
    String baseUrl = authParams.baseUrl;
    // Subsonic streaming: /rest/stream?id={songId}&u={user}&p={pass}&f=json
    return "$baseUrl/rest/stream?id=$songId&u=${authParams.username}&p=enc:${authParams.token}&c=ikaros_app&f=json";
  }

  /// 获取专辑封面图 URL
  static Future<String> getCoverArtUrl(String albumId) async {
    AuthParams? authParams = await AuthApi().getAuthParams();
    if (authParams == null || authParams.baseUrl.isEmpty) {
      return "";
    }
    String baseUrl = authParams.baseUrl;
    return "$baseUrl/rest/getCoverArt?id=al-$albumId&u=${authParams.username}&p=enc:${authParams.token}&c=ikaros_app";
  }

  /// 获取播放列表
  static Future<String> getPlaylistUrl() async {
    AuthParams? authParams = await AuthApi().getAuthParams();
    if (authParams == null || authParams.baseUrl.isEmpty) {
      return "";
    }
    String baseUrl = authParams.baseUrl;
    return "$baseUrl/rest/getPlaylists?u=${authParams.username}&p=enc:${authParams.token}&c=ikaros_app&f=json";
  }

  /// 发送 Scrobble 记录
  static Future<String> getScrobbleUrl(String songId, {int time = 0}) async {
    AuthParams? authParams = await AuthApi().getAuthParams();
    if (authParams == null || authParams.baseUrl.isEmpty) {
      return "";
    }
    String baseUrl = authParams.baseUrl;
    return "$baseUrl/rest/scrobble?id=$songId&time=$time&u=${authParams.username}&p=enc:${authParams.token}&c=ikaros_app&f=json";
  }
}
