import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/api/attachment/AttachmentApi.dart';
import 'package:ikaros/api/dio_client.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 阅读主题
class _ReadingTheme {
  final Color bgColor;
  final Color textColor;
  final String name;

  const _ReadingTheme({
    required this.bgColor,
    required this.textColor,
    required this.name,
  });

  static const _ReadingTheme light = _ReadingTheme(
    bgColor: Color(0xFFF5F0E8),
    textColor: Color(0xFF333333),
    name: "羊皮纸",
  );

  static const _ReadingTheme sepia = _ReadingTheme(
    bgColor: Color(0xFFC8B896),
    textColor: Color(0xFF3A2E1C),
    name: "护眼黄",
  );

  static const _ReadingTheme dark = _ReadingTheme(
    bgColor: Color(0xFF1A1A2E),
    textColor: Color(0xFFE0E0E0),
    name: "夜间黑",
  );

  static const List<_ReadingTheme> values = [light, sepia, dark];
}

/// 阅读设置键
class _PrefKeys {
  static String theme(String subjectId) => "${subjectId}_novel_theme";
  static String fontSize(String subjectId) => "${subjectId}_novel_fontsize";
  static String lineHeight(String subjectId) => "${subjectId}_novel_lineheight";
  static String textAlign(String subjectId) => "${subjectId}_novel_textalign";
}

/// 小说阅读器主页
class NovelReaderPage extends StatefulWidget {
  final String subjectId;

  const NovelReaderPage({super.key, required this.subjectId});

  @override
  State<NovelReaderPage> createState() => _NovelReaderPageState();
}

class _NovelReaderPageState extends State<NovelReaderPage> {
  Subject? _subject;
  List<Episode> _chapters = [];
  bool _isLoading = true;
  int? _lastChapterIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _subject = await SubjectApi().findById(widget.subjectId);
      _chapters = await EpisodeApi().findBySubjectId(widget.subjectId);
      _chapters.sort((a, b) => a.sequence.compareTo(b.sequence));

      // 恢复上次阅读章节
      final prefs = await SharedPreferences.getInstance();
      _lastChapterIndex =
          prefs.getInt("${widget.subjectId}_novel_last_chapter");
    } catch (e) {
      if (mounted) Toast.show(context, "加载小说数据失败: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _openChapter(Episode chapter, {int index = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovelChapterPage(
          chapter: chapter,
          chapterIndex: index,
          subjectName: _subject?.nameCn ?? _subject?.name ?? "",
          subjectId: widget.subjectId,
          allChapters: _chapters,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_subject?.nameCn ?? _subject?.name ?? "小说阅读器"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildChapterList(),
    );
  }

  Widget _buildChapterList() {
    if (_chapters.isEmpty) {
      return const Center(child: Text("暂无章节"));
    }
    return ListView.builder(
      itemCount: _chapters.length,
      itemBuilder: (context, index) {
        final chapter = _chapters[index];
        final title = chapter.nameCn ?? chapter.name;
        final desc = chapter.description;
        final isLastRead = _lastChapterIndex == index;
        return ListTile(
          selected: isLastRead,
          selectedTileColor: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withOpacity(0.3),
          leading: Icon(
            isLastRead ? Icons.menu_book : Icons.book_outlined,
            color: isLastRead
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          title: Text(title,
              style: TextStyle(
                  fontWeight: isLastRead ? FontWeight.bold : null)),
          subtitle: desc != null && desc.isNotEmpty
              ? Text(desc.length > 50 ? "${desc.substring(0, 50)}…" : desc,
                  maxLines: 1, overflow: TextOverflow.ellipsis)
              : Row(
                  children: [
                    Text("第 ${chapter.sequence.toInt()} 章"),
                    if (isLastRead)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text("继续阅读",
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary)),
                      ),
                  ],
                ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openChapter(chapter, index: index),
        );
      },
    );
  }
}

/// 小说章节阅读页
class NovelChapterPage extends StatefulWidget {
  final Episode chapter;
  final int chapterIndex;
  final String subjectName;
  final String subjectId;
  final List<Episode> allChapters;

  const NovelChapterPage({
    super.key,
    required this.chapter,
    required this.chapterIndex,
    required this.subjectName,
    required this.subjectId,
    required this.allChapters,
  });

  @override
  State<NovelChapterPage> createState() => _NovelChapterPageState();
}

class _NovelChapterPageState extends State<NovelChapterPage>
    with WidgetsBindingObserver {
  String _content = "";
  bool _isLoading = true;

  // 阅读设置
  double _fontSize = 18.0;
  double _lineHeight = 1.6;
  bool _showControls = true;
  _ReadingTheme _theme = _ReadingTheme.light;
  TextAlign _textAlign = TextAlign.left;

  // 自动滚动
  bool _autoScroll = false;
  Timer? _autoScrollTimer;
  double _autoScrollSpeed = 1.0; // 速度倍率

  // 滚动位置
  final ScrollController _scrollController = ScrollController();
  double _lastScrollFraction = 0.0;
  bool _scrollRestored = false;

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.allChapters.indexOf(widget.chapter);
    _loadSettings();
    _loadContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveProgress();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = widget.subjectId;
    if (mounted) {
      setState(() {
        _theme = _ReadingTheme.values[
            (prefs.getInt(_PrefKeys.theme(sid)) ?? 0).clamp(0, 2)];
        _fontSize = prefs.getDouble(_PrefKeys.fontSize(sid)) ?? 18.0;
        _lineHeight = prefs.getDouble(_PrefKeys.lineHeight(sid)) ?? 1.6;
        _textAlign = TextAlign
            .values[(prefs.getInt(_PrefKeys.textAlign(sid)) ?? 0)];
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = widget.subjectId;
    await prefs.setInt(
        _PrefKeys.theme(sid), _ReadingTheme.values.indexOf(_theme));
    await prefs.setDouble(_PrefKeys.fontSize(sid), _fontSize);
    await prefs.setDouble(_PrefKeys.lineHeight(sid), _lineHeight);
    await prefs.setInt(_PrefKeys.textAlign(sid), _textAlign.index);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("${widget.subjectId}_novel_last_chapter", _currentIndex);
    if (_scrollController.hasClients) {
      final fraction = _scrollController.position.pixels /
          _scrollController.position.maxScrollExtent;
      await prefs.setDouble(
          "${widget.subjectId}_${widget.chapter.id}_scroll", fraction);
    }
  }

  void _onScroll() {
    if (!_scrollRestored && _scrollController.hasClients) {
      _restoreScrollPosition();
    }
  }

  Future<void> _restoreScrollPosition() async {
    if (_scrollRestored || !_scrollController.hasClients) return;
    final prefs = await SharedPreferences.getInstance();
    final fraction = prefs.getDouble(
        "${widget.subjectId}_${widget.chapter.id}_scroll");
    if (fraction != null &&
        fraction > 0 &&
        _scrollController.position.maxScrollExtent > 0) {
      final target = fraction * _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(target.clamp(
          0.0, _scrollController.position.maxScrollExtent));
    }
    _scrollRestored = true;
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final text = await _fetchChapterContent(widget.chapter);
      if (mounted) {
        setState(() {
          _content = text ?? "（本章暂无内容）";
          _isLoading = false;
        });
        // 内容加载完成后恢复滚动位置
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreScrollPosition();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _content = "加载失败: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _fetchChapterContent(Episode chapter) async {
    if (chapter.description != null && chapter.description!.isNotEmpty) {
      return chapter.description;
    }
    try {
      final resources =
          await EpisodeApi().getEpisodeResourcesRefs(chapter.id);
      if (resources.isNotEmpty) {
        String url = resources.first.url;
        if (url.isEmpty && resources.first.attachmentId.isNotEmpty) {
          url = await AttachmentApi()
              .findReadUrlByAttachmentId(resources.first.attachmentId);
        }
        if (url.isNotEmpty) {
          final dio = await DioClient.getDio();
          final response = await dio.get(url,
              options: Options(
                responseType: ResponseType.plain,
                headers: {"Accept": "text/plain, text/html, */*"},
              ));
          if (response.statusCode == 200 && response.data is String) {
            return response.data;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  void _toggleAutoScroll() {
    if (_autoScroll) {
      _autoScrollTimer?.cancel();
    } else {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!_scrollController.hasClients) return;
        final delta = 0.5 * _autoScrollSpeed;
        final next = _scrollController.position.pixels + delta;
        if (next >= _scrollController.position.maxScrollExtent) {
          // 到底后自动切下一章
          _autoScrollTimer?.cancel();
          _nextChapter();
          return;
        }
        _scrollController.jumpTo(next);
      });
    }
    setState(() => _autoScroll = !_autoScroll);
  }

  void _nextChapter() {
    if (_currentIndex < widget.allChapters.length - 1) {
      _saveProgress();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NovelChapterPage(
            chapter: widget.allChapters[_currentIndex + 1],
            chapterIndex: _currentIndex + 1,
            subjectName: widget.subjectName,
            subjectId: widget.subjectId,
            allChapters: widget.allChapters,
          ),
        ),
      );
    }
  }

  void _prevChapter() {
    if (_currentIndex > 0) {
      _saveProgress();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NovelChapterPage(
            chapter: widget.allChapters[_currentIndex - 1],
            chapterIndex: _currentIndex - 1,
            subjectName: widget.subjectName,
            subjectId: widget.subjectId,
            allChapters: widget.allChapters,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapterTitle = widget.chapter.nameCn ?? widget.chapter.name;
    final themeData = ThemeData(
      scaffoldBackgroundColor: _theme.bgColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _theme.bgColor,
        foregroundColor: _theme.textColor,
        elevation: _showControls ? 1 : 0,
      ),
    );

    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: _showControls
            ? AppBar(
                title: Text(chapterTitle),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.palette),
                    tooltip: "阅读主题",
                    onPressed: _showThemePicker,
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_fields),
                    tooltip: "阅读设置",
                    onPressed: _showReadingSettings,
                  ),
                ],
              )
            : null,
        body: Column(
          children: [
            if (!_showControls)
              Container(
                color: _theme.bgColor,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  "$chapterTitle — ${widget.subjectName}",
                  style: TextStyle(
                      color: _theme.textColor.withOpacity(0.5), fontSize: 12),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: _theme.textColor,
                      ),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _showControls = !_showControls),
                      onVerticalDragEnd: (details) {
                        // 纵向滑动自动滚动变速
                        if (details.primaryVelocity != null) {
                          setState(() {
                            _autoScrollSpeed = (details.primaryVelocity! / 500)
                                .abs()
                                .clamp(0.5, 5.0);
                          });
                          if (!_autoScroll) _toggleAutoScroll();
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null) {
                          if (details.primaryVelocity! < -200) {
                            _nextChapter();
                          } else if (details.primaryVelocity! > 200) {
                            _prevChapter();
                          }
                        }
                      },
                      child: Container(
                        color: _theme.bgColor,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: SelectableText(
                            _content,
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: _lineHeight,
                              color: _theme.textColor,
                              letterSpacing: 0.5,
                            ),
                            textAlign: _textAlign,
                          ),
                        ),
                      ),
                    ),
            ),
            if (_showControls) _buildBottomBar(chapterTitle),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(String chapterTitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _theme.bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _currentIndex > 0 ? _prevChapter : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text("上一章"),
            ),
            // 自动滚动按钮
            IconButton(
              icon: Icon(
                  _autoScroll ? Icons.speed : Icons.speed_outlined,
                  color: _autoScroll ? Colors.blue : null),
              tooltip: _autoScroll ? "停止自动滚动" : "自动滚动",
              onPressed: _toggleAutoScroll,
            ),
            Text(
              "${_currentIndex + 1} / ${widget.allChapters.length}",
              style: TextStyle(color: _theme.textColor.withOpacity(0.5)),
            ),
            TextButton.icon(
              onPressed: _currentIndex < widget.allChapters.length - 1
                  ? _nextChapter
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text("下一章"),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker() async {
    int selectedIndex = _ReadingTheme.values.indexOf(_theme);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _ReadingTheme.values[selectedIndex].bgColor,
          title: const Text("阅读主题"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_ReadingTheme.values.length, (i) {
              final t = _ReadingTheme.values[i];
              return RadioListTile<int>(
                value: i,
                groupValue: selectedIndex,
                title: Text(t.name, style: TextStyle(color: t.textColor)),
                tileColor: t.bgColor,
                activeColor: t.textColor,
                onChanged: (v) {
                  setDialogState(() => selectedIndex = v!);
                },
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                setState(() => _theme = _ReadingTheme.values[selectedIndex]);
                _saveSettings();
                Navigator.pop(ctx);
              },
              child: const Text("确定"),
            ),
          ],
        ),
      ),
    );
  }

  void _showReadingSettings() {
    double tempFont = _fontSize;
    double tempLine = _lineHeight;
    int tempAlign = _textAlign.index;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _theme.bgColor,
          title: Text("阅读设置",
              style: TextStyle(color: _theme.textColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 字体大小
                Text("字体大小: ${tempFont.round()}px",
                    style: TextStyle(color: _theme.textColor)),
                Slider(
                  value: tempFont,
                  min: 12,
                  max: 32,
                  divisions: 20,
                  label: "${tempFont.round()}",
                  activeColor: Colors.blue,
                  onChanged: (v) =>
                      setDialogState(() => tempFont = v),
                ),
                const Divider(),
                // 行间距
                Text("行间距: ${tempLine.toStringAsFixed(1)}",
                    style: TextStyle(color: _theme.textColor)),
                Slider(
                  value: tempLine,
                  min: 1.0,
                  max: 3.0,
                  divisions: 20,
                  label: tempLine.toStringAsFixed(1),
                  activeColor: Colors.blue,
                  onChanged: (v) =>
                      setDialogState(() => tempLine = v),
                ),
                const Divider(),
                // 对齐方式
                Text("对齐方式",
                    style: TextStyle(color: _theme.textColor)),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text("左对齐")),
                    ButtonSegment(value: 1, label: Text("居中")),
                    ButtonSegment(value: 2, label: Text("两端对齐")),
                  ],
                  selected: {tempAlign},
                  onSelectionChanged: (v) =>
                      setDialogState(() => tempAlign = v.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _fontSize = tempFont;
                  _lineHeight = tempLine;
                  _textAlign = TextAlign.values[tempAlign];
                });
                _saveSettings();
                Navigator.pop(ctx);
              },
              child: const Text("确定"),
            ),
          ],
        ),
      ),
    );
  }
}
