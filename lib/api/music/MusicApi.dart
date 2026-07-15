import 'package:dio/dio.dart';
import 'package:ikaros/api/dio_client.dart';

/// 音乐模块 API.
/// 对接服务端 music 模块的 REST 接口.
class MusicApi {
  /// 查询专辑列表
  Future<Map<String, dynamic>> listAlbums(
      {int page = 1, int size = 20}) async {
    String apiUrl = "/api/v1/music/album/list";
    try {
      Dio dio = await DioClient.getDio();
      var response =
          await dio.get(apiUrl, queryParameters: {"page": page, "size": size});
      if (response.statusCode != 200) {
        return {"items": [], "total": 0};
      }
      return response.data is Map ? response.data as Map<String, dynamic> : {};
    } catch (e) {
      return {"items": [], "total": 0};
    }
  }

  /// 查询专辑下的歌曲
  Future<List<Map<String, dynamic>>> listSongs(String albumId) async {
    String apiUrl = "/api/v1/music/album/$albumId/songs";
    try {
      Dio dio = await DioClient.getDio();
      var response = await dio.get(apiUrl);
      if (response.statusCode != 200) {
        return [];
      }
      List<dynamic> list = response.data is List ? response.data as List : [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// 搜索专辑
  Future<Map<String, dynamic>> searchAlbums(
      String keyword, int page, int size) async {
    String apiUrl = "/api/v1/music/album/search";
    try {
      Dio dio = await DioClient.getDio();
      var response = await dio.get(apiUrl, queryParameters: {
        "keyword": keyword,
        "page": page,
        "size": size,
      });
      if (response.statusCode != 200) {
        return {"items": [], "total": 0};
      }
      return response.data is Map ? response.data as Map<String, dynamic> : {};
    } catch (e) {
      return {"items": [], "total": 0};
    }
  }
}
