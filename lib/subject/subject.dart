import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/EpisodeCollectionApi.dart';
import 'package:ikaros/api/collection/SubjectCollectionApi.dart';
import 'package:ikaros/api/collection/enums/CollectionType.dart';
import 'package:ikaros/api/collection/model/EpisodeCollection.dart';
import 'package:ikaros/api/collection/model/SubjectCollection.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/enums/EpisodeGroup.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeRecord.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/component/full_screen_Image.dart';
import 'package:ikaros/consts/collection-const.dart';
import 'package:ikaros/consts/subject_const.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/shared_prefs_utils.dart';
import 'package:ikaros/utils/url_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import 'episode.dart';

class SubjectPage extends StatefulWidget {
  final String? id;

  const SubjectPage({super.key, required this.id});

  @override
  State<StatefulWidget> createState() {
    return _SubjectState();
  }
}

class _SubjectState extends State<SubjectPage> {
  late String _apiBaseUrl;
  late Subject _subject;
  late List<Episode> _episodes = [];
  late List<EpisodeRecord> _episodeRecords = [];
  late SubjectCollection? _subjectCollection;
  late CollectionType _collectionType;
  late SettingConfig _settingConfig = SettingConfig();

  var _loadSubjectWithIdFuture;
  var _loadApiBaseUrlFuture;

  List<EpisodeCollection> _episodeCollections = List.empty();

  Future<Subject> _loadSubjectWithId() async {
    _subject = await SubjectApi().findById(int.parse(widget.id.toString()));
    _episodeCollections = await EpisodeCollectionApi()
        .findListBySubjectId(int.parse(widget.id.toString()));
    return _subject;
  }

  bool _episodeIsFinish(int episodeId) {
    if (_episodeCollections.isEmpty) {
      return false;
    }
    EpisodeCollection? epColl = _episodeCollections
        .where((ep) => ep.episodeId == episodeId)
        .firstOrNull;
    return epColl?.finish ?? false;
  }

  Future<AuthParams> _loadBaseUrl() async {
    return AuthApi().getAuthParams();
  }

  @override
  void initState() {
    super.initState();
    _loadSubjectWithIdFuture = _loadSubjectWithId();
    _loadApiBaseUrlFuture = _loadBaseUrl();
    _fetchSubjectEpisodes();
    _fetchSubjectEpisodeRecords();
    _fetchSettingConfig();
    _fetchSubjectCollection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: "Back",
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [_buildLinkIconButton()],
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<Subject>(
            future: _loadSubjectWithIdFuture,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Text("Load subject error: ${snapshot.error}");
                } else {
                  _subject = snapshot.data;
                  return Padding(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        children: [
                          _buildSubjectDisplayRow(),
                          _buildEpisodeAndCollectionButtonsRow(),
                          _buildDetailsRow(),
                          // _buildEpisodesGroupTabsRow(),
                        ],
                      ));
                  return Column(
                    children: [
                      _buildSubjectDisplayRow(),
                      _buildEpisodeAndCollectionButtonsRow(),
                      _buildDetailsRow(),
                      // _buildEpisodesGroupTabsRow(),
                    ],
                  );
                }
              } else {
                return Container(
                  margin: const EdgeInsets.only(top: 20.0), // 设置顶部边距为20像素
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ), // 替换为你要使用的组件
                );
              }
            }),
      ),
    );
  }

  Widget _buildLinkIconButton() {
    return IconButton(
        onPressed: () async {
          if (_apiBaseUrl == "") {
            _apiBaseUrl = (await _loadBaseUrl()).baseUrl;
          }
          var url =
              "$_apiBaseUrl/console/#/subjects/subject/details/${widget.id}";
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            Toast.show(context, "无法启动外部链接：$url");
          }
        },
        icon: const Icon(
          Icons.link,
          color: Colors.black,
        ));
  }

  Text _buildSubjectTitle() {
    var name = (_subject.nameCn != null && _subject.nameCn != '')
        ? _subject.nameCn!
        : _subject.name;
    return Text(
      name,
      overflow: TextOverflow.ellipsis,
      style:
          const TextStyle(color: Colors.black, backgroundColor: Colors.white),
    );
  }

  Row _buildSubjectDisplayRow() {
    return Row(
      children: [
        // 左边封面图片
        Column(
          children: [_buildSubjectCover()],
        ),
        const SizedBox(width: 10),
        // 右边标题
        Expanded(
          child: _buildSubjectTitleInfo(),
        )
      ],
    );
  }

  Widget _buildSubjectCover() {
    return FutureBuilder<AuthParams>(
        future: _loadApiBaseUrlFuture,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text("Load api base url error: ${snapshot.error}");
            } else {
              _apiBaseUrl = (snapshot.data as AuthParams).baseUrl;
              return SizedBox(
                  width: 120,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: AspectRatio(
                      aspectRatio: 7 / 10, // 设置图片宽高比例
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImagePage(
                                imageUrl: UrlUtils.getCoverUrl(
                                    _apiBaseUrl, _subject.cover), // 替换为你的图片URL
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Hero(
                              tag: UrlUtils.getCoverUrl(
                                  _apiBaseUrl, _subject.cover),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(
                                  UrlUtils.getCoverUrl(
                                      _apiBaseUrl, _subject.cover),
                                  fit: BoxFit.cover,

                                ),
                              ),
                              
                            ),
                            if (_subject.nsfw)
                              Positioned(
                                top: 8,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.only(
                                    left: 2, right: 2, top: 2, bottom: 1
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.orangeAccent,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                      topRight: Radius.circular(0),
                                      bottomRight: Radius.circular(0),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'NSFW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 6,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ));
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  Widget _buildSubjectTitleInfo() {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        // const Text("类型", style: TextStyle(fontWeight: FontWeight.bold),),
        // Text(_subject.type.toString(), overflow: TextOverflow.ellipsis,),
        const Text(
          "名称",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          _subject.name,
          overflow: TextOverflow.ellipsis,
        ),
        const Text(
          "中文名称",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(_subject.nameCn!, overflow: TextOverflow.ellipsis),
        const Text(
          "NSFW",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(_subject.nsfw == true ? "是" : "否",
            overflow: TextOverflow.ellipsis),
        const Text(
          "剧集总数",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("${_episodes.length}", overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Future<bool?> showEpisodesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("选集播放"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: _buildEpisodeSelectTabs(),
          ),
          actions: <Widget>[
            // TextButton(
            //   child: Text("确认"),
            //   onPressed: () {
            //     //关闭对话框并返回true
            //     Navigator.of(context).pop(true);
            //   },
            // ),
            // TextButton(
            //   child: const Text("取消"),
            //   onPressed: () => Navigator.of(context).pop(), // 关闭对话框
            // ),
          ],
        );
      },
    );
  }

  Row _buildEpisodeAndCollectionButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildCollectOperateWidget(),
            _buildCollectTypeOperateWidget(),
          ],
        ),
        Row(
          children: [_buildEpisodeSelectButton()],
        ),
      ],
    );
  }

  Widget _buildEpisodeSelectButton() {
    // 根据APP设置是否拆分剧集资源接口
    return ElevatedButton(
      onPressed: () async {
        await showEpisodesDialog();
      },
      child: const Text("选集"),
    );
    ;
  }

  Widget _buildEnableEpisodeApiSplitButton() {
    return Container();
  }

  Widget _buildCollectOperateWidget() {
    if (_subjectCollection == null) {
      return ElevatedButton(
        onPressed: () {
          _postCollectSubject();
        },
        child: const Text("收藏"),
      );
    } else {
      return ElevatedButton(
        onPressed: () {
          _postUnCollectSubject();
        },
        child: const Text("取消收藏"),
      );
    }
    ;
  }

  Widget _buildCollectTypeOperateWidget() {
    if (_subjectCollection != null) {
      return DropdownButton(
        borderRadius: BorderRadius.circular(5),
        value: _collectionType,
        onChanged: (newValue) {
          if (newValue == null) return;
          setState(() {
            _collectionType = newValue;
          });
          _postCollectSubjectWithoutRefresh(newValue);
        },
        items: CollectionType.values
            .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(CollectionConst.typeCnMap[type.name] ?? "未知"),
                ))
            .toList(),
      );
    }
    return Container();
  }

  Row _buildDetailsRow() {
    return Row(
      children: [
        Wrap(
          direction: Axis.vertical,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            const Text(
              "简介",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 4,
              child: Text(_subject.summary!),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildEpisodeSelectTabs() {
    var groups = _getEpisodeGroupEnums();
    var len = 0;
    if (groups.isNotEmpty) len = groups.length;
    if (len == 0) return Container();
    return DefaultTabController(
        length: len,
        child: Column(
          children: [
            Material(
              //这里设置tab的背景色
              child: _buildEpisodeSelectTabBar(),
            ),
            Expanded(flex: 1, child: _buildEpisodeSelectTabView()),
          ],
        ));
  }

  List<EpisodeGroup> _getEpisodeGroupEnums() {
    var epGroups = <EpisodeGroup>[];
    Set<String?> groupSet;
    if (_settingConfig.enableEpisodeApiSplit) {
      if (_episodes.isEmpty) return epGroups;
      groupSet = _episodes.map((e) => e.group).toSet();
    } else {
      if (_episodeRecords.isEmpty) return epGroups;
      groupSet = _episodeRecords.map((e) => e.episode.group).toSet();
    }
    if (groupSet.isEmpty) return epGroups;
    for (var group in groupSet) {
      var findEpGroups = EpisodeGroup.values.where((ep) => ep.name == group);
      if (findEpGroups.isEmpty) continue;
      var epGroup = findEpGroups.first;
      epGroups.add(epGroup);
    }
    epGroups.sort((a, b) => Enum.compareByIndex(a, b));
    return epGroups;
  }

  Widget _buildEpisodeSelectTabBar() {
    var groups = _getEpisodeGroupEnums();
    var tabs = groups
        .map((g) => Text(
              key: Key(g.toString()),
              SubjectConst.episodeGroupCnMap[g.name]!,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ))
        .map((text) => Tab(
              key: text.key,
              child: text,
            ))
        .toList();
    if (tabs.isEmpty) return const TabBar(tabs: []);
    return TabBar(
        tabs: tabs, isScrollable: groups.isNotEmpty && groups.length != 1);
  }

  List<Episode>? _getEpisodesByGroup(String group) {
    if (_episodes.isEmpty) return [];
    var episodes = _episodes.where((ep) => ep.group == group).toList();
    episodes.sort((me, ot) => me.sequence.compareTo(ot.sequence));
    return episodes;
  }

  List<EpisodeRecord>? _getEpisodeRecordsByGroup(String group) {
    if (_episodeRecords.isEmpty) return [];
    var records = _episodeRecords
        .where((record) => record.episode.group == group)
        .toList();
    records
        .sort((me, ot) => me.episode.sequence.compareTo(ot.episode.sequence));
    return records;
  }

  Widget _buildEpisodeButtonWidget(Episode ep) {
    return FutureBuilder(
        future: EpisodeApi().getEpisodeResourcesRefs(ep.id),
        builder: (BuildContext context,
            AsyncSnapshot<List<EpisodeResource>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text(
                  "Load EpisodeApi getEpisodeResourcesRefs error: ${snapshot.error}");
            } else {
              List<EpisodeResource> epResList = snapshot.data ?? List.empty();
              return GestureDetector(
                onLongPress: () async {
                  bool isFinish = _episodeIsFinish(ep.id);
                  await EpisodeCollectionApi()
                      .updateCollectionFinish(ep.id, !isFinish);
                  Toast.show(context, "更新剧集收藏状态为: ${isFinish ? "未看" : "看完"}");
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SubjectPage(id: widget.id.toString())),
                  );
                },
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _episodeIsFinish(ep.id)
                        ? Colors.green
                        : Colors.lightBlueAccent,
                    disabledBackgroundColor: Colors.grey[400],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                  onPressed: epResList.isEmpty
                      ? null
                      : () {
                          Toast.show(context, "已自动加载第一个附件，剧集加载比较耗时，请耐心等待");
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => SubjectEpisodePage(
                                    episode: ep,
                                    subject: _subject,
                                  )));
                        },
                  child: Text(
                    "${ep.sequence} : ${ep.name}",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }
          } else {
            return const Center(
              child: SizedBox(
                width: 20, // 控制宽度
                height: 20, // 控制高度
                child: CircularProgressIndicator(),
              ),
            );
          }
        });
  }

  Widget _buildEpisodeRecordButtonWidget(EpisodeRecord record) {
    List<EpisodeResource> epResList = record.resources;
    return GestureDetector(
      onLongPress: () async {
        bool isFinish = _episodeIsFinish(record.episode.id);
        await EpisodeCollectionApi()
            .updateCollectionFinish(record.episode.id, !isFinish);
        Toast.show(context, "更新剧集收藏状态为: ${isFinish ? "未看" : "看完"}");
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => SubjectPage(id: widget.id.toString())),
        );
      },
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _episodeIsFinish(record.episode.id)
              ? Colors.green
              : Colors.lightBlueAccent,
          disabledBackgroundColor: Colors.grey[400],
          disabledForegroundColor: Colors.grey[600],
        ),
        onPressed: epResList.isEmpty
            ? null
            : () {
                Toast.show(context, "已自动加载第一个附件，剧集加载比较耗时，请耐心等待");
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => SubjectEpisodePage(
                          episode: record.episode,
                          subject: _subject,
                        )));
              },
        child: Text(
          "${record.episode.sequence} : ${record.episode.name}",
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _getEpisodesTabViewByGroup(String group) {
    List<Container>? buttons;
    if (_settingConfig.enableEpisodeApiSplit) {
      buttons = _getEpisodesByGroup(group)
          ?.map((ep) => Container(
                margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                child:
                    SizedBox(height: 40, child: _buildEpisodeButtonWidget(ep)),
              ))
          .toList();
    } else {
      buttons = _getEpisodeRecordsByGroup(group)
          ?.map((ep) => Container(
                margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                child: SizedBox(
                    height: 40, child: _buildEpisodeRecordButtonWidget(ep)),
              ))
          .toList();
    }

    if (buttons == null) return Container();

    return ListView(
      children: buttons,
    );
  }

  TabBarView _buildEpisodeSelectTabView() {
    var groups = _getEpisodeGroupEnums();
    var tabViews =
        groups.map((g) => _getEpisodesTabViewByGroup(g.name)).toList();
    if (tabViews.isEmpty) {
      return const TabBarView(
        children: [],
      );
    }
    return TabBarView(
      children: tabViews,
    );
  }

  Future<void> _fetchSubjectEpisodes() async {
    _episodes =
        await EpisodeApi().findBySubjectId(int.parse(widget.id.toString()));
    if (_episodes.isEmpty) {
      debugPrint("获取条目剧集失败");
    }

    setState(() {});
  }

  Future<void> _fetchSubjectEpisodeRecords() async {
    _episodeRecords = await EpisodeApi()
        .findRecordsBySubjectId(int.parse(widget.id.toString()));
    if (_episodeRecords.isEmpty) {
      debugPrint("获取条目剧集Record失败");
    }
    setState(() {});
  }

  Future<void> _fetchSettingConfig() async {
    _settingConfig = await SharedPrefsUtils.getSettingConfig();
    setState(() {});
  }

  Future<void> _fetchSubjectCollection() async {
    _subjectCollection = await SubjectCollectionApi()
        .findCollectionBySubjectId(int.parse(widget.id.toString()));
    if (_subjectCollection?.type != null) {
      _collectionType = _subjectCollection!.type;
    }
    if (_subjectCollection == null && kDebugMode) {
      print("获取条目收藏信息失败");
    }
  }

  String? _getSubjectName() {
    if (_subject.nameCn != null && _subject.nameCn != "")
      return _subject.nameCn;
    return _subject.name;
  }

  Future<void> _postCollectSubject() async {
    await _postCollectSubjectWithoutRefresh(CollectionType.WISH);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => SubjectPage(id: _subject.id.toString())),
    );
  }

  Future<void> _postCollectSubjectWithoutRefresh(CollectionType type) async {
    await SubjectCollectionApi()
        .updateCollection(_subject.id, type, _subject.nsfw);
    Toast.show(context, "收藏番剧[${_getSubjectName()}]成功.");
  }

  Future<void> _postUnCollectSubject() async {
    await SubjectCollectionApi().removeCollection(_subject.id);
    Toast.show(context, "取消收藏番剧[${_getSubjectName()}]成功.");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => SubjectPage(id: _subject.id.toString())),
    );
  }
}
