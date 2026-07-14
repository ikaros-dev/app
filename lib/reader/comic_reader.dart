import 'package:flutter/material.dart';
import 'package:ikaros/api/attachment/AttachmentApi.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/component/full_screen_Image.dart';
import 'package:ikaros/utils/message_utils.dart';

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
        Toast.show(context, "加载漫画数据失败: $e");
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _openChapter(Episode chapter, {int chapterIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComicChapterPage(
          chapter: chapter,
          chapterIndex: chapterIndex,
          allChapters: _chapters,
          title: _subject?.nameCn ?? _subject?.name ?? "漫画",
        ),
      ),
    );
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
        return ListTile(
          leading:
              Icon(Icons.auto_stories, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          subtitle: Text("第 ${chapter.sequence.toInt()} 话"),
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
  final String title;

  const ComicChapterPage({
    super.key,
    required this.chapter,
    required this.chapterIndex,
    required this.allChapters,
    required this.title,
  });

  @override
  State<ComicChapterPage> createState() => _ComicChapterPageState();
}

class _ComicChapterPageState extends State<ComicChapterPage> {
  List<String> _pageUrls = [];
  bool _isLoading = true;
  bool _isListMode = false;
  bool _rightToLeft = false; // 右向左阅读（日漫风格）
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
      // 按名称排序保证页面顺序
      resources.sort((a, b) => a.name.compareTo(b.name));

      List<String> urls = [];
      for (var res in resources) {
        if (res.url.isNotEmpty) {
          urls.add(res.url);
        } else if (res.attachmentId.isNotEmpty) {
          String readUrl =
              await AttachmentApi().findReadUrlByAttachmentId(res.attachmentId);
          if (readUrl.isNotEmpty) {
            urls.add(readUrl);
          }
        }
      }
      _pageUrls = urls;
    } catch (e) {
      if (mounted) {
        Toast.show(context, "加载页面失败: $e");
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
          title: widget.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapterTitle = widget.chapter.nameCn ?? widget.chapter.name;
    return Scaffold(
      appBar: AppBar(
        title: Text("$chapterTitle — ${_currentPage + 1}/${_pageUrls.length}"),
        actions: [
          // 阅读方向切换
          IconButton(
            icon: Icon(_rightToLeft ? Icons.arrow_back : Icons.arrow_forward),
            tooltip: _rightToLeft ? "右→左（日漫）" : "左→右（正常）",
            onPressed: () => setState(() => _rightToLeft = !_rightToLeft),
          ),
          // 模式切换
          IconButton(
            icon:
                Icon(_isListMode ? Icons.view_carousel : Icons.view_column),
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
                  child: Text("暂无页面", style: TextStyle(color: Colors.white)))
              : _isListMode
                  ? _buildListMode()
                  : _buildPageMode(),
    );
  }

  Widget _buildPageMode() {
    final reversedPages = _rightToLeft
        ? _pageUrls.reversed.toList()
        : _pageUrls;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              // 左右滑动切换章节
              if (details.primaryVelocity != null) {
                final velocity = details.primaryVelocity!;
                // 考虑阅读方向
                bool goNext;
                if (_rightToLeft) {
                  goNext = velocity < -200; // 左滑下一章
                } else {
                  goNext = velocity < -200;
                }
                if (goNext) {
                  _goToChapter(widget.chapterIndex + 1);
                } else if (velocity > 200) {
                  _goToChapter(widget.chapterIndex - 1);
                }
              }
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: reversedPages.length,
              onPageChanged: (index) => setState(() {
                _currentPage = _rightToLeft
                    ? reversedPages.length - 1 - index
                    : index;
              }),
              itemBuilder: (context, index) {
                final actualIndex = _rightToLeft
                    ? reversedPages.length - 1 - index
                    : index;
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _showPageActions(),
                      child: Image.network(
                        _pageUrls[actualIndex],
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // 底部章节进度条
        _buildChapterProgress(),
      ],
    );
  }

  Widget _buildListMode() {
    return Stack(
      children: [
        ListView.builder(
          itemCount: _pageUrls.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                _pageUrls[index],
                fit: BoxFit.contain,
                width: double.infinity,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
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
                  heroTag: "prev",
                  onPressed: () => _goToChapter(widget.chapterIndex - 1),
                  child: const Icon(Icons.chevron_left),
                ),
              const SizedBox(width: 8),
              if (widget.chapterIndex < widget.allChapters.length - 1)
                FloatingActionButton.small(
                  heroTag: "next",
                  onPressed: () => _goToChapter(widget.chapterIndex + 1),
                  child: const Icon(Icons.chevron_right),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChapterProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.black54,
      child: Row(
        children: [
          // 上一章
          if (widget.chapterIndex > 0)
            TextButton.icon(
              onPressed: () => _goToChapter(widget.chapterIndex - 1),
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              label: const Text("上一章",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          const Spacer(),
          // 章节选择器
          TextButton(
            onPressed: () => _showChapterPicker(),
            child: Text(
              "${widget.chapterIndex + 1} / ${widget.allChapters.length}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const Spacer(),
          // 下一章
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

  void _showPageActions() {
    // 点击页面弹出操作菜单
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
              leading: Icon(_isListMode
                  ? Icons.view_carousel
                  : Icons.view_column, color: Colors.white70),
              title: Text(
                  _isListMode ? "切换到单页模式" : "切换到列表模式",
                  style: const TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _isListMode = !_isListMode);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen() {
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
