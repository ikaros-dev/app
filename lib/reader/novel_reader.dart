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
    } catch (e) {
      if (mounted) {
        Toast.show(context, "加载小说数据失败: $e");
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
        return ListTile(
          leading: Icon(Icons.menu_book,
              color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          subtitle: desc != null && desc.isNotEmpty
              ? Text(desc.length > 50 ? "${desc.substring(0, 50)}…" : desc,
                  maxLines: 1, overflow: TextOverflow.ellipsis)
              : Text("第 ${chapter.sequence.toInt()} 章"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openChapter(chapter),
        );
      },
    );
  }

  void _openChapter(Episode chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovelChapterPage(
          chapter: chapter,
          subjectName: _subject?.nameCn ?? _subject?.name ?? "",
          allChapters: _chapters,
        ),
      ),
    );
  }
}

/// 小说章节阅读页
class NovelChapterPage extends StatefulWidget {
  final Episode chapter;
  final String subjectName;
  final List<Episode> allChapters;

  const NovelChapterPage({
    super.key,
    required this.chapter,
    required this.subjectName,
    required this.allChapters,
  });

  @override
  State<NovelChapterPage> createState() => _NovelChapterPageState();
}

class _NovelChapterPageState extends State<NovelChapterPage> {
  String _content = "";
  bool _isLoading = true;
  double _fontSize = 18.0;
  bool _showControls = true;

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allChapters.indexOf(widget.chapter);
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      String? text = await _fetchChapterContent(widget.chapter);
      if (mounted) {
        setState(() {
          _content = text ?? "（本章暂无内容）";
          _isLoading = false;
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

  /// 从章节描述或附件文件中获取文字内容
  Future<String?> _fetchChapterContent(Episode chapter) async {
    // 优先使用 description 字段
    if (chapter.description != null && chapter.description!.isNotEmpty) {
      return chapter.description;
    }
    // 尝试从附件读取文本
    try {
      List<EpisodeResource> resources =
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
    } catch (_) {
      // ignore fetch error
    }
    return null;
  }

  void _nextChapter() {
    if (_currentIndex < widget.allChapters.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NovelChapterPage(
            chapter: widget.allChapters[_currentIndex + 1],
            subjectName: widget.subjectName,
            allChapters: widget.allChapters,
          ),
        ),
      );
    }
  }

  void _prevChapter() {
    if (_currentIndex > 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NovelChapterPage(
            chapter: widget.allChapters[_currentIndex - 1],
            subjectName: widget.subjectName,
            allChapters: widget.allChapters,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapterTitle = widget.chapter.nameCn ?? widget.chapter.name;
    return Scaffold(
      appBar: _showControls
          ? AppBar(
              title: Text(chapterTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.text_increase),
                  tooltip: "字体大小",
                  onPressed: _showFontSizeDialog,
                ),
              ],
            )
          : null,
      backgroundColor: const Color(0xFFF5F0E8),
      body: Column(
        children: [
          if (!_showControls)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                "$chapterTitle — ${widget.subjectName}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    onTap: () =>
                        setState(() => _showControls = !_showControls),
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! < -200) {
                          _nextChapter();
                        } else if (details.primaryVelocity! > 200) {
                          _prevChapter();
                        }
                      }
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: SelectableText(
                        _content,
                        style: TextStyle(
                          fontSize: _fontSize,
                          height: 1.6,
                          color: const Color(0xFF333333),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
          ),
          if (_showControls) _buildBottomBar(chapterTitle),
        ],
      ),
    );
  }

  Widget _buildBottomBar(String chapterTitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
            Text(
              "${_currentIndex + 1} / ${widget.allChapters.length}",
              style: const TextStyle(color: Colors.grey),
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

  Future<void> _showFontSizeDialog() async {
    double tempSize = _fontSize;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("字体大小"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("当前: ${tempSize.round()}px"),
              Slider(
                value: tempSize,
                min: 12,
                max: 32,
                divisions: 20,
                label: "${tempSize.round()}",
                onChanged: (v) => setDialogState(() => tempSize = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("取消")),
            TextButton(
              onPressed: () {
                setState(() => _fontSize = tempSize);
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
