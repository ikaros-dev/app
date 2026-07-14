import 'dart:math';

/// 歌词元数据标签
class LyricsTag {
  final String ti; // 歌曲标题
  final String ar; // 演唱者
  final String al; // 专辑
  final String by; // 制作人
  final double offset; // 时间偏移（秒）

  const LyricsTag({
    this.ti = "",
    this.ar = "",
    this.al = "",
    this.by = "",
    this.offset = 0.0,
  });
}

/// 歌词单词时间戳（A2 格式用）
class WordTiming {
  final String word;
  final double startMs;
  final double durationMs;

  const WordTiming({
    required this.word,
    required this.startMs,
    required this.durationMs,
  });
}

/// 单行歌词
class LyricsLine {
  /// 行开始时间（毫秒）
  final double startMs;

  /// 行文本
  final String text;

  /// A2 逐字时间（可选）
  final List<WordTiming>? words;

  const LyricsLine({
    required this.startMs,
    required this.text,
    this.words,
  });

  /// 当前时间在这一行内的进度（0.0 ~ 1.0）
  double progressAt(double currentMs) {
    if (words == null || words!.isEmpty) return 0.0;
    final totalMs = words!.last.startMs + words!.last.durationMs - startMs;
    if (totalMs <= 0) return 0.0;
    return ((currentMs - startMs) / totalMs).clamp(0.0, 1.0);
  }

  /// 当前时间对应的单词索引
  int wordIndexAt(double currentMs) {
    if (words == null || words!.isEmpty) return -1;
    final relativeMs = currentMs - startMs;
    for (int i = 0; i < words!.length; i++) {
      final w = words![i];
      if (relativeMs >= w.startMs &&
          relativeMs <= w.startMs + w.durationMs) {
        return i;
      }
    }
    return -1;
  }

  /// 当前时间对应的单词进度
  double wordProgressAt(double currentMs) {
    final idx = wordIndexAt(currentMs);
    if (idx < 0 || words == null || idx >= words!.length) return 0.0;
    final w = words![idx];
    if (w.durationMs <= 0) return 0.0;
    return ((currentMs - startMs - w.startMs) / w.durationMs).clamp(0.0, 1.0);
  }

  Duration get start => Duration(milliseconds: startMs.round());
}

/// LRC/A2 歌词解析结果
class ParsedLyrics {
  final LyricsTag tag;
  final List<LyricsLine> lines;

  const ParsedLyrics({required this.tag, required this.lines});

  bool get isEmpty => lines.isEmpty;
  int get length => lines.length;

  /// 获取当前时间对应的歌词行索引
  int indexAt(double currentMs) {
    if (lines.isEmpty) return -1;
    for (int i = lines.length - 1; i >= 0; i--) {
      if (currentMs >= lines[i].startMs) return i;
    }
    return -1;
  }
}

/// LRC/A2 歌词解析器
class LyricsParser {
  /// 解析 LRC 或 A2 格式的歌词文本
  static ParsedLyrics parse(String text) {
    final tag = _parseTags(text);
    final lines = _parseLines(text);
    return ParsedLyrics(tag: tag, lines: lines);
  }

  /// 解析元数据标签
  static LyricsTag _parseTags(String text) {
    String ti = "", ar = "", al = "", by = "";
    double offset = 0.0;

    final tagRegex = RegExp(r'^\[(\w+):(.+)\]$', multiLine: true);
    for (final match in tagRegex.allMatches(text)) {
      final key = match.group(1)!.toLowerCase();
      final value = match.group(2)!.trim();
      switch (key) {
        case 'ti':
          ti = value;
          break;
        case 'ar':
          ar = value;
          break;
        case 'al':
          al = value;
          break;
        case 'by':
          by = value;
          break;
        case 'offset':
          offset = double.tryParse(value) ?? 0.0;
          break;
      }
    }
    return LyricsTag(ti: ti, ar: ar, al: al, by: by, offset: offset);
  }

  /// 解析歌词行（支持 LRC 和 A2 格式）
  static List<LyricsLine> _parseLines(String text) {
    final lines = <LyricsLine>[];
    // 匹配 [mm:ss.xx] 或 [mm:ss] 或 [mm:ss.xxx]
    final lineRegex = RegExp(
      r'^\[(\d{1,3}):(\d{2})(?:[\.:](\d{2,3}))?\](.*)$',
      multiLine: true,
    );

    for (final match in lineRegex.allMatches(text)) {
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final millisStr = match.group(3);
      int millis = 0;
      if (millisStr != null) {
        millis = int.parse(millisStr);
        if (millisStr.length == 2) millis *= 10; // .xx → xxx
      }
      final startMs = (minutes * 60 + seconds) * 1000.0 + millis;
      final rawText = match.group(4)?.trim() ?? "";

      // 检测是否为 A2 格式（含 <time> 标签）
      final words = _parseWordTimings(startMs, rawText);
      if (words != null && words.isNotEmpty) {
        // A2 格式
        final cleanText = words.map((w) => w.word).join();
        lines.add(LyricsLine(startMs: startMs, text: cleanText, words: words));
      } else {
        // 标准 LRC 格式
        lines.add(LyricsLine(startMs: startMs, text: rawText));
      }
    }

    lines.sort((a, b) => a.startMs.compareTo(b.startMs));
    return lines;
  }

  /// 解析 A2 格式的逐字时间戳
  /// 格式: <mm:ss.xx>字 或 <ss.xx>字
  static List<WordTiming>? _parseWordTimings(
      double lineStartMs, String rawText) {
    if (!rawText.contains('<')) return null;

    final words = <WordTiming>[];
    // 匹配 <mm:ss.xx>文本 或 <ss.xx>文本
    final wordRegex = RegExp(r'<(\d{1,3}):(\d{2})[\.:](\d{2,3})>([^<]*)');
    bool hasMatch = false;

    for (final match in wordRegex.allMatches(rawText)) {
      hasMatch = true;
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final millisStr = match.group(3)!;
      int millis = int.parse(millisStr);
      if (millisStr.length == 2) millis *= 10;

      final wordStartMs = (minutes * 60 + seconds) * 1000.0 + millis;
      final word = match.group(4) ?? "";

      // 计算持续时间（到下一个词或行尾）
      words.add(WordTiming(word: word, startMs: wordStartMs, durationMs: 0));
    }

    if (!hasMatch) return null;

    // 计算每个词的持续时间（基于下一个词的起始时间）
    for (int i = 0; i < words.length - 1; i++) {
      words[i] = WordTiming(
        word: words[i].word,
        startMs: words[i].startMs - lineStartMs,
        durationMs: words[i + 1].startMs - words[i].startMs,
      );
    }
    if (words.isNotEmpty) {
      // 最后一个词持续到行结束（估算 1000ms）
      final last = words.last;
      final idx = words.length - 1;
      words[idx] = WordTiming(
        word: last.word,
        startMs: last.startMs - lineStartMs,
        durationMs: 1000.0,
      );
    }

    return words;
  }
}
