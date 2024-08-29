import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AttachmentApi {

  Future<String> fetchPartialFileMd5(String url)async {
    List<int> bytes = await fetchPartialFile(url);
    Digest md5Digest = md5.convert(bytes);
    return md5Digest.toString();
  }

  Future<List<int>> fetchPartialFile(String url) async {
    if (url == "" || !url.startsWith("http:")) return List.empty();

    try {
      // 使用 range 头部请求文件的前 16MB 数据
      Response<List<int>> response = await Dio().get<List<int>>(
        url, // 替换为你的文件URL
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Range': 'bytes=0-16777215', // 请求文件的前 16MB 字节 (16 * 1024 * 1024 - 1)
          },
        ),
      );

      if (response.statusCode == 206) { // 206 表示部分内容获取成功
        return response.data!;
      } else {
        if (kDebugMode) {
          print('请求未能返回部分内容。');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('请求失败: $e');
      }
    }
    return List.empty();
  }
}