import 'package:flutter_test/flutter_test.dart';
import 'package:ikaros/utils/lyrics_parser.dart';

/// LRC/A2 歌词解析器单元测试
void main() {
  group('标准 LRC 格式', () {
    test('解析基本 LRC 行', () {
      const lrc = '''
[00:00.00]第一行歌词
[00:05.00]第二行歌词
[00:10.00]第三行歌词
''';
      final parsed = LyricsParser.parse(lrc);
      expect(parsed.lines.length, 3);
      expect(parsed.lines[0].text, "第一行歌词");
      expect(parsed.lines[0].startMs, 0);
      expect(parsed.lines[1].startMs, 5000);
      expect(parsed.lines[2].startMs, 10000);
    });

    test('解析带毫秒的 LRC', () {
      const lrc = "[01:30.500]一行带精确毫秒的歌词\n[02:00.000]另一行";
      final parsed = LyricsParser.parse(lrc);
      expect(parsed.lines.length, 2);
      expect(parsed.lines[0].startMs, 90500.0);
      expect(parsed.lines[1].startMs, 120000.0);
    });

    test('解析元数据标签', () {
      const lrc = '''
[ti:测试歌曲]
[ar:测试歌手]
[al:测试专辑]
[by:制作人]
[offset:500]
[00:00.00]开始
''';
      final parsed = LyricsParser.parse(lrc);
      expect(parsed.tag.ti, "测试歌曲");
      expect(parsed.tag.ar, "测试歌手");
      expect(parsed.tag.al, "测试专辑");
      expect(parsed.tag.by, "制作人");
      expect(parsed.tag.offset, 500.0);
    });

    test('空歌词返回空列表', () {
      final parsed = LyricsParser.parse("");
      expect(parsed.lines, isEmpty);
      expect(parsed.isEmpty, true);
    });

    test('无时间戳的文本返回空', () {
      final parsed = LyricsParser.parse("这是一段没有时间戳的文字");
      expect(parsed.lines, isEmpty);
    });
  });

  group('A2 逐字歌词格式', () {
    test('解析 A2 逐字歌词', () {
      const a2 = '''
[00:01.00]<00:00.50>第<00:00.80>一<00:00.60>行
[00:04.00]<00:00.40>第<00:00.70>二<00:00.50>行
''';
      final parsed = LyricsParser.parse(a2);

      expect(parsed.lines.length, 2);

      // 第一行
      final line0 = parsed.lines[0];
      expect(line0.words, isNotNull);
      expect(line0.words!.length, 3);
      expect(line0.words![0].word, "第");
      expect(line0.words![1].word, "一");
      expect(line0.words![2].word, "行");

      // 验证 cleanText
      expect(line0.text, "第一行");
    });

    test('A2 格式的单词进度', () {
      const a2 = "[00:00.00]<00:00.10>A<00:00.20>B<00:00.30>C";
      final parsed = LyricsParser.parse(a2);
      final line = parsed.lines[0];

      expect(line.words!.length, 3);

      // 在 50ms 时（第0个字进度50%）
      expect(line.wordIndexAt(50), 0);
      expect(line.wordProgressAt(50), greaterThan(0));

      // 在 150ms 时（第1个字进度50%）
      expect(line.wordIndexAt(150), 1);

      // 在 350ms 时（第2个字进度50%）
      expect(line.wordIndexAt(350), 2);
    });
  });

  group('索引计算', () {
    test('当前时间对应的行索引', () {
      const lrc = '''
[00:00.00]第一行
[00:10.00]第二行
[00:20.00]第三行
''';
      final parsed = LyricsParser.parse(lrc);

      expect(parsed.indexAt(0), 0);
      expect(parsed.indexAt(5000), 0);
      expect(parsed.indexAt(10000), 1);
      expect(parsed.indexAt(15000), 1);
      expect(parsed.indexAt(20000), 2);
      expect(parsed.indexAt(99999), 2);
    });

    test('开始前返回 -1', () {
      const lrc = "[00:10.00]第一行";
      final parsed = LyricsParser.parse(lrc);
      expect(parsed.indexAt(0), -1);
    });

    test('行进度计算', () {
      const lrc = "[00:00.00]<00:00.10>测<00:00.20>试";
      final parsed = LyricsParser.parse(lrc);
      final line = parsed.lines[0];

      // 50ms 时进度 ~50%
      final progress = line.progressAt(50);
      expect(progress, greaterThan(0));
      expect(progress, lessThan(0.6)); // 非精确值，A2 格式估算

      // 300ms 时进度 100%
      expect(line.progressAt(300), greaterThan(0.9));
    });
  });

  group('时长格式化', () {
    test('line.start 返回 Duration', () {
      const lrc = "[01:30.500]测试";
      final parsed = LyricsParser.parse(lrc);
      expect(parsed.lines[0].start, const Duration(
          minutes: 1, seconds: 30, milliseconds: 500));
    });
  });
}
