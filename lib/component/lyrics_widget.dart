import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ikaros/utils/lyrics_parser.dart';

/// 歌词显示方向
enum LyricsOrientation { vertical, horizontal }

/// 卡拉OK歌词组件
/// 支持竖排列表和横排单行两种布局
class LyricsWidget extends StatefulWidget {
  /// 歌词数据
  final ParsedLyrics lyrics;

  /// 当前播放位置（毫秒）
  final double positionMs;

  /// 显示方向
  final LyricsOrientation orientation;

  /// 歌词颜色
  final Color textColor;

  /// 高亮颜色（卡拉OK当前字）
  final Color highlightColor;

  /// 已唱颜色
  final Color sungColor;

  /// 字体大小
  final double fontSize;

  const LyricsWidget({
    super.key,
    required this.lyrics,
    required this.positionMs,
    this.orientation = LyricsOrientation.vertical,
    this.textColor = Colors.white54,
    this.highlightColor = Colors.blue,
    this.sungColor = Colors.white,
    this.fontSize = 16,
  });

  @override
  State<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends State<LyricsWidget> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void didUpdateWidget(LyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.positionMs != widget.positionMs) {
      _autoScrollToCurrent();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _autoScrollToCurrent() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      final index = widget.lyrics.indexAt(widget.positionMs);
      if (index < 0) return;
      final itemHeight = widget.fontSize + 16; // 行高估算
      final target = index * itemHeight - 100;
      if (target > 0) {
        _scrollController.animateTo(
          target.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lyrics.isEmpty) {
      return const Center(child: Text("暂无歌词", style: TextStyle(color: Colors.white38)));
    }

    return widget.orientation == LyricsOrientation.vertical
        ? _buildVertical()
        : _buildHorizontal();
  }

  /// 竖排歌词列表
  Widget _buildVertical() {
    final currentIndex = widget.lyrics.indexAt(widget.positionMs);

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.lyrics.length,
      itemBuilder: (context, index) {
        final line = widget.lyrics.lines[index];
        final isCurrent = index == currentIndex;
        final isSung = index < currentIndex;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          child: line.words != null && isCurrent
              ? _buildKaraokeText(line, isSung: false)
              : Text(
                  line.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCurrent ? widget.fontSize + 2 : widget.fontSize,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isSung
                        ? widget.sungColor
                        : isCurrent
                            ? widget.highlightColor
                            : widget.textColor,
                  ),
                ),
        );
      },
    );
  }

  /// 横排单行卡拉OK（桌面歌词）
  Widget _buildHorizontal() {
    final currentIndex = widget.lyrics.indexAt(widget.positionMs);

    if (currentIndex < 0) {
      return const SizedBox.shrink();
    }

    final currentLine = widget.lyrics.lines[currentIndex];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: currentLine.words != null
            ? _buildKaraokeText(currentLine, isSung: false)
            : ShaderMask(
                shaderCallback: (bounds) {
                  final progress = currentLine.progressAt(widget.positionMs);
                  return LinearGradient(
                    colors: [widget.sungColor, widget.textColor],
                    stops: [progress, progress],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text(
                  currentLine.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.fontSize + 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  /// 逐字卡拉OK文本
  Widget _buildKaraokeText(LyricsLine line, {bool isSung = false}) {
    if (line.words == null || line.words!.isEmpty) {
      return Text(
        line.text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: widget.fontSize + 2,
          fontWeight: FontWeight.bold,
          color: isSung ? widget.sungColor : widget.highlightColor,
        ),
      );
    }

    final words = line.words!;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          for (int i = 0; i < words.length; i++)
            _buildWordSpan(words[i], i, line),
        ],
      ),
    );
  }

  TextSpan _buildWordSpan(WordTiming word, int index, LyricsLine line) {
    final isActive = line.wordIndexAt(widget.positionMs) == index;
    final wordProgress = line.wordProgressAt(widget.positionMs);

    if (isActive && wordProgress > 0) {
      // 当前正在唱的字的卡拉OK渐变色
      return TextSpan(
        text: word.word,
        style: TextStyle(
          fontSize: widget.fontSize + 2,
          fontWeight: FontWeight.bold,
          foreground: Paint()
            ..shader = LinearGradient(
              colors: [widget.sungColor, widget.highlightColor],
              stops: [wordProgress, wordProgress],
            ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
        ),
      );
    }

    return TextSpan(
      text: word.word,
      style: TextStyle(
        fontSize: widget.fontSize + 2,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: isActive ? widget.highlightColor : widget.sungColor,
      ),
    );
  }
}
