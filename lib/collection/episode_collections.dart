import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/EpisodeCollectionApi.dart';
import 'package:ikaros/api/collection/model/EpisodeCollection.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/Subject.dart';

class EpisodeCollectionsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return EpisodeCollectionsPageState();
  }
}

class EpisodeCollectionsPageState extends State<EpisodeCollectionsPage> {
  late final EasyRefreshController _easyRefreshController =
      EasyRefreshController();
  late final ScrollController _easyRefreshScrollController = ScrollController();
  List<HistoryItem> _historyItems = [];
  int _currentPage = 1;
  int _currentSize = 10;
  bool _hasMore = true;
  String _apiBaseUrl = "";

  @override
  void initState() {
    super.initState();
    _loadApiBaseUrl();
    _loadData();
  }

  @override
  void dispose() {
    _easyRefreshController.dispose();
    _easyRefreshScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadApiBaseUrl() async {
    if (_apiBaseUrl != '') return;
    AuthParams? authParams = await AuthApi().getAuthParams();
    if (authParams == null) return;
    setState(() {
      _apiBaseUrl = authParams.baseUrl;
    });
  }


  Future<void> _loadData() async {
    await _loadApiBaseUrl();

    PagingWrap pagingWrap = await EpisodeCollectionApi()
        .listCollectionsByCondition(_currentPage, _currentSize);

    List<HistoryItem> newItems = [];

    if (pagingWrap.items.isNotEmpty) {
      for (var epColMap in pagingWrap.items) {
        EpisodeCollection epCol = EpisodeCollection.fromJson(epColMap);
        Subject? subject = await SubjectApi().findById(epCol.subjectId ?? 0);
        Episode? episode = await EpisodeApi().findById(epCol.episodeId);
        var item = HistoryItem(episodeCollection: epCol, subject: subject, episode: episode);
        newItems.add(item);
      }
    }

    setState(() {
      _historyItems.addAll(newItems);
      _currentPage++;
      if (_historyItems.length >= pagingWrap.total) {
        if (mounted) {
          _hasMore = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: "返回",
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("历史纪录"),
      ),
      body: EasyRefresh(
        controller: _easyRefreshController,
        scrollController: _easyRefreshScrollController,
        footer: ClassicalFooter(
            loadingText: "加载中...",
            loadFailedText: "加载失败",
            loadReadyText: "加载就绪",
            loadedText: "已全部加载",
            noMoreText: "没有更多了",
            showInfo: false),
        onLoad: () async {
          await _loadData();
          if (!mounted) {
            return;
          }
          if (kDebugMode) {
            print("noMore: ${!_hasMore}");
          }
          _easyRefreshController.finishLoad(success: true, noMore: !_hasMore);
          _easyRefreshController.resetLoadState();
        },
        child: ListView.builder(
          itemCount: _historyItems.length,
          itemBuilder: (context, index) {
            return _buildHistoryItem(_historyItems[index]);
          },
        ),
      ),
    );
  }

  Future<HistoryItem> _loadHistoryItemWithCollection(
      EpisodeCollection collection) async {
    Subject? subject = await SubjectApi().findById(collection.subjectId ?? 0);
    Episode? episode = await EpisodeApi().findById(collection.episodeId);
    return HistoryItem(
        episodeCollection: collection, subject: subject, episode: episode);
  }

  Widget _buildHistoryItem(HistoryItem item) {
    Subject? subject = item.subject;
    Episode? episode = item.episode;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: InkWell(
        onTap: () {
          // 处理点击事件
          //print('点击了 ${item.title}');
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左边图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      _apiBaseUrl + subject!.cover,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 右边信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 剧集序号 + 标题
                        Row(
                          children: [
                            Text(
                              (episode?.sequence ?? "").toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                episode?.name ?? "剧集无名称",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        // 第一行描述
                        Text(
                          episode?.description ?? "剧集无描述",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // 观看信息
                        Text(
                          "当前为${episode?.group ?? "正片"}第${episode?.sequence ?? -1}话",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 更新时间
                        Text(
                          '更新于 ${item.episodeCollection.updateTime}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 进度条
              LinearProgressIndicator(
                value: ((item.episodeCollection.progress ?? 0) /
                    (item.episodeCollection.duration ?? 1)),
                backgroundColor: Colors.grey[200],
                valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: _hasMore
            ? const CircularProgressIndicator()
            : const Text('没有更多数据了', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

class HistoryItem {
  final EpisodeCollection episodeCollection;
  late final Subject? subject;
  late final Episode? episode;

  HistoryItem({required this.episodeCollection, this.subject, this.episode});
}
