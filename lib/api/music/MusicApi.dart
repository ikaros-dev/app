import 'package:dio/dio.dart';
import 'package:ikaros/api/dio_client.dart';

/// 音乐模块 API.
/// 对接服务端 music 模块的 REST 接口.
class MusicApi {
  /// 查询专辑列表
  Future<Map<String, dynamic>> listAlbums(
      {int page = 1, int size = 20}) async {
    String apiUrl = "/api/v1/music/album/list";
    Dio dio = await DioClient.getDio();
    final response =
        await dio.get(apiUrl, queryParameters: {"page": page, "size": size});
    if (response.statusCode != 200) {
      throw Exception("查询专辑失败，HTTP ${response.statusCode}");
    }
    if (response.data is! Map) {
      throw const FormatException("专辑列表响应格式错误");
    }
    return Map<String, dynamic>.from(response.data as Map);
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
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// 搜索专辑
  Future<Map<String, dynamic>> searchAlbums(
      String keyword, int page, int size) async {
    String apiUrl = "/api/v1/music/album/search";
    Dio dio = await DioClient.getDio();
    final response = await dio.get(apiUrl, queryParameters: {
      "keyword": keyword,
      "page": page,
      "size": size,
    });
    if (response.statusCode != 200) {
      throw Exception("搜索专辑失败，HTTP ${response.statusCode}");
    }
    if (response.data is! Map) {
      throw const FormatException("专辑搜索响应格式错误");
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}
