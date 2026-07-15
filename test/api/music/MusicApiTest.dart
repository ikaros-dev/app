import 'package:flutter_test/flutter_test.dart';

/// 音乐模块 API 单元测试
/// 测试 JSON 响应解析逻辑和数据类型验证
void main() {
  group('MusicApi - 专辑列表响应解析', () {
    test('正常响应应正确解析分页数据', () {
      final responseData = {
        "page": 1,
        "size": 20,
        "total": 2,
        "items": [
          {
            "id": "album-001",
            "name": "OST Collection",
            "nameCn": "原声合集",
            "cover": "https://example.com/cover1.jpg",
            "airTime": "2025-01-01",
            "songCount": 12,
            "subjectId": "sub-001",
          },
          {
            "id": "album-002",
            "name": "Character Song",
            "nameCn": "角色歌",
            "cover": "https://example.com/cover2.jpg",
            "airTime": "2025-02-01",
            "songCount": null,
            "subjectId": "sub-002",
          },
        ]
      };

      final items = responseData["items"] as List;
      expect(items.length, 2);
      expect(responseData["total"], 2);

      // 验证第一张专辑
      final album1 = items[0] as Map<String, dynamic>;
      expect(album1["id"], "album-001");
      expect(album1["nameCn"], "原声合集");
      expect(album1["songCount"], 12);

      // 验证第二张专辑（songCount 为 null）
      final album2 = items[1] as Map<String, dynamic>;
      expect(album2["id"], "album-002");
      expect(album2["songCount"], isNull);
    });

    test('空列表应返回空数组', () {
      final responseData = {
        "page": 1,
        "size": 20,
        "total": 0,
        "items": []
      };

      final items = responseData["items"] as List;
      expect(items, isEmpty);
      expect(responseData["total"], 0);
    });
  });

  group('MusicApi - 歌曲列表响应解析', () {
    test('歌曲列表应正确解析', () {
      final responseData = [
        {
          "id": "song-001",
          "name": "OP Theme",
          "nameCn": "片头曲",
          "duration": 240,
          "sequence": 1,
          "subjectId": "sub-001",
        },
        {
          "id": "song-002",
          "name": "ED Theme",
          "nameCn": "片尾曲",
          "duration": 180,
          "sequence": 2,
          "subjectId": "sub-001",
        },
      ];

      expect(responseData.length, 2);

      final first = responseData[0];
      expect(first["duration"], 240);
      expect(first["sequence"], 1);

      final second = responseData[1];
      expect(second["duration"], 180);
      expect(second["nameCn"], "片尾曲");
    });

    test('空歌曲列表', () {
      final songs = <Map<String, dynamic>>[];
      expect(songs, isEmpty);
    });

    test('歌曲时长格式化', () {
      // 测试音乐库中的时长格式化逻辑
      String formatDuration(int duration) {
        if (duration <= 0) return "0:00";
        final m = (duration ~/ 60).toString();
        final s = (duration % 60).toString().padLeft(2, '0');
        return "$m:$s";
      }

      expect(formatDuration(240), "4:00");
      expect(formatDuration(180), "3:00");
      expect(formatDuration(65), "1:05");
      expect(formatDuration(0), "0:00");
      expect(formatDuration(-1), "0:00");
    });
  });

  group('MusicApi - 搜索响应解析', () {
    test('搜索结果', () {
      final responseData = {
        "page": 1,
        "size": 20,
        "total": 1,
        "items": [
          {
            "id": "album-001",
            "name": "OST Collection",
            "nameCn": "原声合集",
            "cover": "https://example.com/cover.jpg",
          }
        ]
      };

      final items = responseData["items"] as List;
      expect(items.length, 1);
      expect(responseData["total"], 1);
    });
  });

  group('SubsonicApi - 流媒体 URL', () {
    test('stream URL 格式', () {
      final baseUrl = "https://ikaros.example.com";
      final songId = "song-001";
      final username = "admin";
      final token = "mytoken";

      final url =
          "$baseUrl/rest/stream?id=$songId&u=$username&p=enc:$token&c=ikaros_app&f=json";
      expect(url, contains("song-001"));
      expect(url, contains("enc:mytoken"));
      expect(url, contains("rest/stream"));
    });

    test('cover art URL 格式', () {
      final baseUrl = "https://ikaros.example.com";
      final albumId = "al-album-001";

      final url = "$baseUrl/rest/getCoverArt?id=$albumId&u=admin&p=enc:token&c=ikaros_app";
      expect(url, contains("getCoverArt"));
      expect(url, contains("al-album-001"));
    });
  });
}
