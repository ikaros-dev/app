import 'package:dio/dio.dart';
import 'package:ikaros/api/dio_client.dart';

/// 音乐模块 API.
/// 对接服务端 music 模块的 REST 接口.
class MusicApi {
  /// 查询专辑列表
  Future<List<Map<String, dynamic>>> listAlbums(
      {int page = 1, int size = 20}) async {
    final apiUrl = "/api/v1/music/albums/$page/$size";
    final dio = await DioClient.getDio();
    final response = await dio.get(apiUrl);
    if (response.statusCode != 200) {
      throw Exception("查询专辑失败，HTTP ${response.statusCode}");
    }
    return _parseAlbumList(response.data);
  }

  /// 查询专辑下的歌曲
  Future<List<Map<String, dynamic>>> listSongs(String albumId) async {
    String apiUrl = "/api/v1/music/album/$albumId/songs";
    Dio dio = await DioClient.getDio();
    final response = await dio.get(apiUrl);
    if (response.statusCode != 200) {
      throw Exception("查询歌曲失败，HTTP ${response.statusCode}");
    }
    if (response.data is! List) {
      throw const FormatException("歌曲列表响应格式错误");
    }
    final songs = _parseObjectList(response.data, "歌曲");
    return songs.map((song) {
      song["nameCn"] ??= song["name_cn"];
      song["subjectId"] ??= song["subject_id"];
      if (song["sequence"] is num) {
        song["sequence"] = (song["sequence"] as num).toInt();
      }
      return song;
    }).toList();
  }

  /// 搜索专辑
  Future<List<Map<String, dynamic>>> searchAlbums(
      String keyword, int page, int size) async {
    final encodedKeyword = Uri.encodeComponent(keyword);
    final apiUrl = "/api/v1/music/search/$encodedKeyword/$page/$size";
    final dio = await DioClient.getDio();
    final response = await dio.get(apiUrl);
    if (response.statusCode != 200) {
      throw Exception("搜索专辑失败，HTTP ${response.statusCode}");
    }
    return _parseAlbumList(response.data);
  }

  List<Map<String, dynamic>> _parseAlbumList(dynamic data) {
    return _parseObjectList(data, "专辑").map((album) {
      album["nameCn"] ??= album["name_cn"];
      album["songCount"] ??= album["song_count"];
      album["airTime"] ??= album["air_time"];
      return album;
    }).toList();
  }

  List<Map<String, dynamic>> _parseObjectList(dynamic data, String label) {
    if (data is! List) {
      throw FormatException("$label列表响应格式错误");
    }
    return data.map((item) {
      if (item is! Map) {
        throw FormatException("$label列表中包含无效数据");
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}
