import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SubtitleDownloader {
  /// 下载ASS字幕到临时目录并返回本地文件路径
  static Future<String> downloadAssToTempDirectory(String assUrl) async {
    try {
      // 1. 获取临时目录
      final tempDir = await getTemporaryDirectory();

      // 2. 从URL提取文件名，确保是.ass扩展名
      String fileName = _extractFileNameFromUrl(assUrl);
      if (!fileName.toLowerCase().endsWith('.ass')) {
        fileName = 'subtitle_${DateTime.now().millisecondsSinceEpoch}.ass';
      }

      // 3. 创建本地文件路径
      final localPath = path.join(tempDir.path, fileName);
      final file = File(localPath);

      // 4. 下载文件
      final response = await http.get(Uri.parse(assUrl));

      if (response.statusCode == 200) {
        // 写入文件
        await file.writeAsBytes(response.bodyBytes);
        print('ASS字幕已下载到: $localPath');
        return localPath;
      } else {
        throw Exception('下载失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('下载出错: $e');
      rethrow;
    }
  }

  /// 从URL提取合适的文件名
  static String _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        String fileName = pathSegments.last;
        // 确保文件名有效
        if (fileName.contains('.')) {
          return fileName;
        }
      }
    } catch (_) {}

    // 默认文件名
    return 'subtitle_${DateTime.now().millisecondsSinceEpoch}.ass';
  }

  /// 生成可被视频播放器读取的file:// URL
  static String generateFileUrl(String localPath) {
    // 转换为file://格式的URI
    return Uri.file(localPath).toString();
  }

  /// 清理临时字幕文件（可选）
  static Future<void> cleanupTempFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        print('已清理临时文件: $localPath');
      }
    } catch (e) {
      print('清理文件出错: $e');
    }
  }
}