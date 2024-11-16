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
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeRecord.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/component/subject/subject.dart';
import 'package:ikaros/consts/collection-const.dart';
import 'package:ikaros/consts/subject_const.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/shared_prefs_utils.dart';
import 'package:ikaros/utils/url_utils.dart';
import 'package:intl/intl.dart';
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

  static const double _globalPadding = 10.0;

  List<EpisodeCollection> _episodeCollections = List.empty();

  late String _selectedCollectBtnLabelVal = "收藏";
  late IconData _selectedCollectBtnIconData = Icons.star_border_outlined;
  late MenuController _collectMenuController;

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
      body: FutureBuilder<Subject>(
          future: _loadSubjectWithIdFuture,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Text("Load subject error: ${snapshot.error}");
              } else {
                _subject = snapshot.data;
                return SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(_globalPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubjectDisplayRow(),
                          const SizedBox(height: 10),
                          _buildEpisodeAndCollectionButtonsRow(),
                          const SizedBox(height: 10),
                          _buildMultiTabs(),
                        ],
                      )),
                );
              }
            } else {
              return const LinearProgressIndicator();
            }
          }),
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

  String _getSubjectTitle() {
    if (_subject.nameCn != null && "" != _subject.nameCn) {
      return _subject.nameCn!;
    }
    return _subject.name;
  }

  Row _buildSubjectDisplayRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左边封面图片
        Column(
          children: [_buildSubjectCover()],
        ),
        const SizedBox(width: 10),
        // 右边标题
        Expanded(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getSubjectTitle(),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black),
            ),
            const SizedBox(height: 10),
            Chip(
              label: Text(_getAirTimeStr()),
            ),
            const SizedBox(height: 10),
            Text("${SubjectConst.typeCnMap[_subject.type.name]} "
                "- 全${_episodeRecords.isNotEmpty ? _episodeRecords.length : _episodes.length}话")
          ],
        ))
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
                child: SubjectCover(
                  url: UrlUtils.getCoverUrl(_apiBaseUrl, _subject.cover),
                  nsfw: _subject.nsfw,
                ),
              );
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
        Text(
          _subject.nameCn ?? _subject.name,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        OutlinedButton(onPressed: () {}, child: const Text('2020 年 10 月')),
        // const Text("类型", style: TextStyle(fontWeight: FontWeight.bold),),
        // Text(_subject.type.toString(), overflow: TextOverflow.ellipsis,),

        Text(
          _subject.name,
          overflow: TextOverflow.ellipsis,
        ),

        Text(_subject.nameCn!, overflow: TextOverflow.ellipsis),
        Text(_subject.nameCn!, overflow: TextOverflow.ellipsis),
        Text(_subject.nameCn!, overflow: TextOverflow.ellipsis),

        Text(_subject.nsfw == true ? "是" : "否",
            overflow: TextOverflow.ellipsis),

        Text("${_episodes.length}", overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Future<bool?> showEpisodesDialog() {
    if (_subject.type == SubjectType.GAME ||
        _subject.type == SubjectType.COMIC ||
        _subject.type == SubjectType.NOVEL ||
        _subject.type == SubjectType.OTHER) {
      Toast.show(context,
          "当前条目类型[${SubjectConst.typeCnMap[_subject.type.name] ?? "未知"}]不支持视频播放");
      return Future.value();
    }
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "选集播放",
            style: TextStyle(color: Colors.black),
          ),
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
            _buildCollectionMenuAnchor(),
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
    return OutlinedButton.icon(
      onPressed: () async {
        await showEpisodesDialog();
      },
      label: const Text(
        "选集",
        style: TextStyle(color: Colors.black),
      ),
      icon: const Icon(
        Icons.view_cozy_outlined,
        color: Colors.black,
      ),
    );
    ;
  }

  MenuAnchor _buildCollectionMenuAnchor() {
    final double btnWidth = MediaQuery.of(context).size.width * 0.3;
    return MenuAnchor(
      childFocusNode: FocusNode(),
      menuChildren: <Widget>[
        SizedBox(
          width: btnWidth,
          child: TextButton.icon(
            icon: Icon(Icons.calendar_month,
                color: _selectedCollectBtnIconData == Icons.calendar_month
                    ? Colors.blue
                    : Colors.black),
            label: Text("想看",
                style: TextStyle(
                    color: _selectedCollectBtnLabelVal == "已想看"
                        ? Colors.blue
                        : Colors.black)),
            onPressed: () async => {
              debugPrint("想看"),
              _selectedCollectBtnLabelVal = "已想看",
              _selectedCollectBtnIconData = Icons.calendar_month,
              _collectMenuController.close(),
              setState(() {}),
              await _postCollectSubjectWithoutRefresh(CollectionType.WISH),
            },
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // 去除圆角
              ),
            ),
          ),
        ),
        SizedBox(
          width: btnWidth,
          child: TextButton.icon(
            icon: Icon(Icons.play_circle_outline,
                color: _selectedCollectBtnIconData == Icons.play_circle_outline
                    ? Colors.blue
                    : Colors.black),
            label: Text("在看",
                style: TextStyle(
                    color: _selectedCollectBtnLabelVal == "已在看"
                        ? Colors.blue
                        : Colors.black)),
            onPressed: () async => {
              debugPrint("在看"),
              _selectedCollectBtnLabelVal = "已在看",
              _selectedCollectBtnIconData = Icons.play_circle_outline,
              _collectMenuController.close(),
              setState(() {}),
              await _postCollectSubjectWithoutRefresh(CollectionType.DOING),
            },
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // 去除圆角
              ),
            ),
          ),
        ),
        SizedBox(
          width: btnWidth,
          child: TextButton.icon(
            icon: Icon(Icons.check_circle_outlined,
                color:
                    _selectedCollectBtnIconData == Icons.check_circle_outlined
                        ? Colors.blue
                        : Colors.black),
            label: Text("看过",
                style: TextStyle(
                    color: _selectedCollectBtnLabelVal == "已看过"
                        ? Colors.blue
                        : Colors.black)),
            onPressed: () async => {
              debugPrint("看过"),
              _selectedCollectBtnLabelVal = "已看过",
              _selectedCollectBtnIconData = Icons.check_circle_outlined,
              _collectMenuController.close(),
              setState(() {}),
              await _postCollectSubjectWithoutRefresh(CollectionType.DONE),
            },
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // 去除圆角
              ),
            ),
          ),
        ),
        SizedBox(
          width: btnWidth,
          child: TextButton.icon(
            icon: Icon(Icons.access_time,
                color: _selectedCollectBtnIconData == Icons.access_time
                    ? Colors.blue
                    : Colors.black),
            label: Text("搁置",
                style: TextStyle(
                    color: _selectedCollectBtnLabelVal == "已搁置"
                        ? Colors.blue
                        : Colors.black)),
            onPressed: () async => {
              debugPrint("搁置"),
              _selectedCollectBtnLabelVal = "已搁置",
              _selectedCollectBtnIconData = Icons.access_time,
              _collectMenuController.close(),
              setState(() {}),
              await _postCollectSubjectWithoutRefresh(CollectionType.SHELVE),
            },
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // 去除圆角
              ),
            ),
          ),
        ),
        SizedBox(
          width: btnWidth,
          child: TextButton.icon(
            icon: Icon(Icons.not_interested_sharp,
                color: _selectedCollectBtnIconData == Icons.not_interested_sharp
                    ? Colors.blue
                    : Colors.black),
            label: Text("抛弃",
                style: TextStyle(
                    color: _selectedCollectBtnLabelVal == "已抛弃"
                        ? Colors.blue
                        : Colors.black)),
            onPressed: () async => {
              debugPrint("抛弃"),
              _selectedCollectBtnLabelVal = "已抛弃",
              _selectedCollectBtnIconData = Icons.not_interested_sharp,
              _collectMenuController.close(),
              setState(() {}),
              await _postCollectSubjectWithoutRefresh(CollectionType.DISCARD),
            },
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // 去除圆角
              ),
            ),
          ),
        ),
        SizedBox(
          width: btnWidth,
          child: TextButton.icon(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.black,
            ),
            label: const Text(
              "取消",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async => {
              debugPrint("取消"),
              _selectedCollectBtnLabelVal = "收藏",
              _selectedCollectBtnIconData = Icons.star_border_outlined,
              _collectMenuController.close(),
              setState(() {}),
              await _postUnCollectSubject(),
            },
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // 去除圆角
              ),
            ),
          ),
        ),
      ],
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        _collectMenuController = controller;
        return SizedBox(
          width: btnWidth,
          child: OutlinedButton.icon(
            icon: Icon(
              _selectedCollectBtnIconData,
              color: Colors.black,
            ),
            label: Text(_selectedCollectBtnLabelVal,
                style: TextStyle(color: Colors.black)),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          ),
        );
        return OutlinedButton(
          child: Text("selected"),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
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
            const Row(
              children: [
                Text(
                  "简介",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black),
                )
              ],
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 2 * _globalPadding,
              child: Text(_subject.summary!),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildMultiTabs() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 550),
      child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(10),
                child: TabBar(
                  tabs: [
                    Tab(text: '介绍'),
                    Tab(text: '信息'),
                  ],
                ),
              ),
              Expanded(
                  child: TabBarView(
                children: [
                  Text(
                    _subject.summary!,
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                    maxLines: 40,
                    softWrap: true,
                  ),
                  Text(
                    _subject.infobox!,
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                    maxLines: 40,
                    softWrap: true,
                  ),
                ],
              )),
            ],
          )),
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
                    builder: (context) => SubjectEpisodesPage(
                          episodeRecord: record,
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

    if (_subjectCollection == null) {
      _selectedCollectBtnLabelVal = "收藏";
      _selectedCollectBtnIconData = Icons.star_border_outlined;
    }

    if (_subjectCollection?.type != null) {
      _collectionType = _subjectCollection!.type;
    }
    if (_subjectCollection == null && kDebugMode) {
      debugPrint("获取条目收藏信息失败");
    }

    if (_collectionType == CollectionType.WISH) {
      _selectedCollectBtnLabelVal = "已想看";
      _selectedCollectBtnIconData = Icons.calendar_month;
    } else if (_collectionType == CollectionType.DOING) {
      _selectedCollectBtnLabelVal = "已在看";
      _selectedCollectBtnIconData = Icons.play_circle_outline;
    } else if (_collectionType == CollectionType.DONE) {
      _selectedCollectBtnLabelVal = "已看过";
      _selectedCollectBtnIconData = Icons.check_circle_outlined;
    } else if (_collectionType == CollectionType.SHELVE) {
      _selectedCollectBtnLabelVal = "已搁置";
      _selectedCollectBtnIconData = Icons.access_time;
    } else if (_collectionType == CollectionType.DISCARD) {
      _selectedCollectBtnLabelVal = "已抛弃";
      _selectedCollectBtnIconData = Icons.not_interested_sharp;
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
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //       builder: (context) => SubjectPage(id: _subject.id.toString())),
    // );
  }

  String _getAirTimeStr() {
    if (_subject.airTime == null || "" == _subject.airTime) return "1970 年 1 月";
    DateTime dateTime = DateTime.parse(_subject.airTime!);
    return DateFormat('yyyy 年 MM 月').format(dateTime);
  }
}
