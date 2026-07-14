import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ikaros/api/attachment/AttachmentApi.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/component/full_screen_Image.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 漫画阅读器主页
class ComicReaderPage extends StatefulWidget {
  final String subjectId;

  const ComicReaderPage({super.key, required this.subjectId});

  @override
  State<ComicReaderPage> createState() => _ComicReaderPageState();
}

class _ComicReaderPageState extends State<ComicReaderPage> {
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

      // 恢复上次阅读位置
      final prefs = await SharedPreferences.getInstance();
      _lastChapterIndex = prefs.getInt("${widget.subjectId}_comic_last_chapter");
    } catch (e) {
      if (mounted) Toast.show(context, "加载漫画数据失败: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _openChapter(Episode chapter, {int chapterIndex = 0}) async {
    // 保存阅读进度
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("${widget.subjectId}_comic_last_chapter", chapterIndex);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComicChapterPage(
          chapter: chapter,
          chapterIndex: chapterIndex,
          allChapters: _chapters,
          subjectId: widget.subjectId,
          title: _subject?.nameCn ?? _subject?.name ?? "漫画",
        ),
      ),
    ).then((_) => _loadData()); // 返回时刷新进度
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_subject?.nameCn ?? _subject?.name ?? "漫画阅读器"),
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
        final isLastRead = _lastChapterIndex == index;
        return ListTile(
          selected: isLastRead,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          leading: Icon(
            isLastRead ? Icons.auto_stories : Icons.book_outlined,
            color: isLastRead
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          title: Text(title,
              style: TextStyle(
                  fontWeight: isLastRead ? FontWeight.bold : null)),
          subtitle: Row(
            children: [
              Text("第 ${chapter.sequence.toInt()} 话"),
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
          onTap: () => _openChapter(chapter, chapterIndex: index),
        );
      },
    );
  }
}

/// 漫画章节阅读页
class ComicChapterPage extends StatefulWidget {
  final Episode chapter;
  final int chapterIndex;
  final List<Episode> allChapters;
  final String subjectId;
  final String title;

  const ComicChapterPage({
    super.key,
    required this.chapter,
    required this.chapterIndex,
    required this.allChapters,
    required this.subjectId,
    required this.title,
  });

  @override
  State<ComicChapterPage> createState() => _ComicChapterPageState();
}

class _ComicChapterPageState extends State<ComicChapterPage> {
  List<String> _pageUrls = [];
  bool _isLoading = true;
  bool _isListMode = false;
  bool _rightToLeft = false;
  bool _fitToWidth = true; // 适应宽度还是高度
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int? _lastPageIndex;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPages() async {
    setState(() => _isLoading = true);
    try {
      List<EpisodeResource> resources =
          await EpisodeApi().getEpisodeResourcesRefs(widget.chapter.id);
      resources.sort((a, b) => a.name.compareTo(b.name));

      List<String> urls = [];
      for (var res in resources) {
        if (res.url.isNotEmpty) {
          urls.add(res.url);
        } else if (res.attachmentId.isNotEmpty) {
          String readUrl =
              await AttachmentApi().findReadUrlByAttachmentId(res.attachmentId);
          if (readUrl.isNotEmpty) urls.add(readUrl);
        }
      }
      _pageUrls = urls;

      // 恢复上次阅读页
      final prefs = await SharedPreferences.getInstance();
      _lastPageIndex = prefs.getInt("${widget.subjectId}_${widget.chapter.id}_page");
      if (_lastPageIndex != null && _lastPageIndex! < urls.length && !_isListMode) {
        _currentPage = _lastPageIndex!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isListMode && _rightToLeft) {
            _pageController.jumpToPage(urls.length - 1 - _lastPageIndex!);
          } else if (!_isListMode) {
            _pageController.jumpToPage(_lastPageIndex!);
          }
        });
      }
    } catch (e) {
      if (mounted) Toast.show(context, "加载页面失败: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProgress(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("${widget.subjectId}_${widget.chapter.id}_page", page);
    await prefs.setInt("${widget.subjectId}_comic_last_chapter", widget.chapterIndex);
  }

  void _goToChapter(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.allChapters.length) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ComicChapterPage(
          chapter: widget.allChapters[newIndex],
          chapterIndex: newIndex,
          allChapters: widget.allChapters,
          subjectId: widget.subjectId,
          title: widget.title,
        ),
      ),
    );
  }

  /// 处理键盘事件
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_isListMode) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        if (!_rightToLeft) {
          _pageController.nextPage(duration: Durations.short1, curve: Curves.ease);
        } else {
          _pageController.previousPage(duration: Durations.short1, curve: Curves.ease);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (!_rightToLeft) {
          _pageController.previousPage(duration: Durations.short1, curve: Curves.ease);
        } else {
          _pageController.nextPage(duration: Durations.short1, curve: Curves.ease);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (widget.chapterIndex > 0) _goToChapter(widget.chapterIndex - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (widget.chapterIndex < widget.allChapters.length - 1) {
          _goToChapter(widget.chapterIndex + 1);
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapterTitle = widget.chapter.nameCn ?? widget.chapter.name;
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Text("$chapterTitle — ${_currentPage + 1}/${_pageUrls.length}"),
          actions: [
            IconButton(
              icon: Icon(_rightToLeft ? Icons.arrow_back : Icons.arrow_forward),
              tooltip: _rightToLeft ? "右→左（日漫）" : "左→右（正常）",
              onPressed: () => setState(() => _rightToLeft = !_rightToLeft),
            ),
            IconButton(
              icon: Icon(_fitToWidth ? Icons.fit_screen : Icons.fit_page),
              tooltip: _fitToWidth ? "适应宽度" : "适应高度",
              onPressed: () => setState(() => _fitToWidth = !_fitToWidth),
            ),
            IconButton(
              icon: Icon(_isListMode ? Icons.view_carousel : Icons.view_column),
              tooltip: _isListMode ? "单页模式" : "列表模式",
              onPressed: () => setState(() => _isListMode = !_isListMode),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pageUrls.isEmpty
                ? const Center(
                    child: Text("暂无页面",
                        style: TextStyle(color: Colors.white)))
                : _isListMode ? _buildListMode() : _buildPageMode(),
      ),
    );
  }

  Widget _buildPageMode() {
    final reversedPages =
        _rightToLeft ? _pageUrls.reversed.toList() : _pageUrls;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! < -200) {
                _goToChapter(widget.chapterIndex + 1);
              } else if (details.primaryVelocity! > 200) {
                _goToChapter(widget.chapterIndex - 1);
              }
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: reversedPages.length,
              onPageChanged: (index) {
                final actualIndex = _rightToLeft
                    ? reversedPages.length - 1 - index
                    : index;
                setState(() => _currentPage = actualIndex);
                _saveProgress(actualIndex);
              },
              itemBuilder: (context, index) {
                final actualIndex = _rightToLeft
                    ? reversedPages.length - 1 - index
                    : index;
                // 预加载前后页面
                return _ComicPageWidget(
                  url: _pageUrls[actualIndex],
                  fitToWidth: _fitToWidth,
                );
              },
            ),
          ),
        ),
        // 加载过渡：当前正在加载时显示页面跳转进度
        _buildChapterProgress(),
      ],
    );
  }

  Widget _buildChapterProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.black54,
      child: Row(
        children: [
          if (widget.chapterIndex > 0)
            TextButton.icon(
              onPressed: () => _goToChapter(widget.chapterIndex - 1),
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              label: const Text("上一章",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          const Spacer(),
          // 页面进度指示（用小圆点）
          SizedBox(
            width: 120,
            child: Center(
              child: Text(
                "${_currentPage + 1} / ${_pageUrls.length} 页",
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ),
          const Spacer(),
          if (widget.chapterIndex < widget.allChapters.length - 1)
            TextButton.icon(
              onPressed: () => _goToChapter(widget.chapterIndex + 1),
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
              label: const Text("下一章",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildListMode() {
    return Stack(
      children: [
        ListView.builder(
          itemCount: _pageUrls.length,
          itemBuilder: (context, index) {
            return _ComicPageWidget(
              url: _pageUrls[index],
              fitToWidth: true, // 列表模式下始终适应宽度
            );
          },
        ),
        // 章节切换悬浮按钮
        Positioned(
          bottom: 16,
          right: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.chapterIndex > 0)
                FloatingActionButton.small(
                  heroTag: "prev_${widget.chapterIndex}",
                  onPressed: () => _goToChapter(widget.chapterIndex - 1),
                  child: const Icon(Icons.chevron_left),
                ),
              const SizedBox(width: 8),
              if (widget.chapterIndex < widget.allChapters.length - 1)
                FloatingActionButton.small(
                  heroTag: "next_${widget.chapterIndex}",
                  onPressed: () => _goToChapter(widget.chapterIndex + 1),
                  child: const Icon(Icons.chevron_right),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChapterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (ctx) => SizedBox(
        height: 400,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text("选择章节 — ${widget.title}",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: widget.allChapters.length,
                itemBuilder: (_, i) {
                  final ch = widget.allChapters[i];
                  final isCurrent = i == widget.chapterIndex;
                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor: Colors.white12,
                    title: Text(
                      ch.nameCn ?? ch.name,
                      style: TextStyle(
                        color: isCurrent ? Colors.blue : Colors.white70,
                        fontWeight: isCurrent ? FontWeight.bold : null,
                      ),
                    ),
                    subtitle: Text("第 ${ch.sequence.toInt()} 话",
                        style: const TextStyle(color: Colors.white38)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _goToChapter(i);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.zoom_in, color: Colors.white70),
              title: const Text("全屏查看",
                  style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                _openFullScreen();
              },
            ),
            ListTile(
              leading: Icon(_fitToWidth ? Icons.fit_page : Icons.fit_screen,
                  color: Colors.white70),
              title: Text(
                  _fitToWidth ? "切换到适应高度" : "切换到适应宽度",
                  style: const TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _fitToWidth = !_fitToWidth);
              },
            ),
            ListTile(
              leading: Icon(
                  _isListMode ? Icons.view_carousel : Icons.view_column,
                  color: Colors.white70),
              title: Text(
                  _isListMode ? "单页模式" : "列表模式",
                  style: const TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _isListMode = !_isListMode);
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_right_alt, color: Colors.white70),
              title: Text(
                  _rightToLeft ? "切换到左→右" : "切换到右→左",
                  style: const TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _rightToLeft = !_rightToLeft);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen() {
    if (_currentPage >= 0 && _currentPage < _pageUrls.length) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullScreenImagePage(
            imageUrl: _pageUrls[_currentPage],
          ),
        ),
      );
    }
  }
}

/// 漫画单页组件，支持 InteractiveViewer
class _ComicPageWidget extends StatelessWidget {
  final String url;
  final bool fitToWidth;

  const _ComicPageWidget({required this.url, required this.fitToWidth});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          url,
          fit: fitToWidth ? BoxFit.contain : BoxFit.fitHeight,
          width: fitToWidth ? double.infinity : null,
          height: fitToWidth ? null : double.infinity,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            final loaded = progress.cumulativeBytesLoaded;
            final total = progress.expectedTotalBytes;
            return Center(
              child: total != null
                  ? CircularProgressIndicator(
                      value: loaded / total,
                      strokeWidth: 2,
                    )
                  : const CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, __, ___) => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white38, size: 48),
              SizedBox(height: 8),
              Text("图片加载失败",
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
