import 'package:flutter/material.dart';
import 'package:ikaros/api/attachment/AttachmentApi.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
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
  Episode? _currentChapter;
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

  void _openChapter(Episode chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComicChapterPage(
          chapter: chapter,
          title: _subject?.nameCn ?? _subject?.name ?? "漫画",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_subject?.nameCn ?? _subject?.name ?? "漫画阅读器")),
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
          leading: Icon(Icons.auto_stories, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          subtitle: Text("第 ${chapter.sequence.toInt()} 话"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openChapter(chapter),
        );
      },
    );
  }
}

/// 漫画章节阅读页
class ComicChapterPage extends StatefulWidget {
  final Episode chapter;
  final String title;

  const ComicChapterPage({super.key, required this.chapter, required this.title});

  @override
  State<ComicChapterPage> createState() => _ComicChapterPageState();
}

class _ComicChapterPageState extends State<ComicChapterPage> {
  List<String> _pageUrls = [];
  bool _isLoading = true;
  bool _isListMode = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    setState(() => _isLoading = true);
    try {
      List<EpisodeResource> resources =
          await EpisodeApi().getEpisodeResourcesRefs(widget.chapter.id);
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
      // 按名称排序（页面编号）
      resources.sort((a, b) => a.name.compareTo(b.name));
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapterTitle = widget.chapter.nameCn ?? widget.chapter.name;
    return Scaffold(
      appBar: AppBar(
        title: Text("$chapterTitle — ${_currentPage + 1}/${_pageUrls.length}"),
        actions: [
          IconButton(
            icon: Icon(_isListMode ? Icons.view_column : Icons.view_carousel),
            tooltip: _isListMode ? "单页模式" : "列表模式",
            onPressed: () => setState(() => _isListMode = !_isListMode),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pageUrls.isEmpty
              ? const Center(child: Text("暂无页面", style: TextStyle(color: Colors.white)))
              : _isListMode ? _buildListMode() : _buildPageMode(),
    );
  }

  Widget _buildPageMode() {
    return GestureDetector(
      onTap: () {},
      child: PageView.builder(
        controller: _pageController,
        itemCount: _pageUrls.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                _pageUrls[index],
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
          );
        },
      ),
    );
  }

  Widget _buildListMode() {
    return ListView.builder(
      itemCount: _pageUrls.length,
      itemBuilder: (context, index) {
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            _pageUrls[index],
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
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
    );
  }
}
