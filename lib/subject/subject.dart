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
import 'package:ikaros/api/subject/SubjectRelationApi.dart';
import 'package:ikaros/api/subject/enums/SubjectRelationType.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeRecord.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/api/subject/model/SubjectRelation.dart';
import 'package:ikaros/component/subject/subject.dart';
import 'package:ikaros/consts/subject_const.dart';
import 'package:ikaros/layout.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/screen_utils.dart';
import 'package:ikaros/utils/url_utils.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/platform_utils.dart';
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
  String _apiBaseUrl = "";
  Subject? _subject;
  List<SubjectRelation> _subjectRelations = [];
  List<Episode> _episodes = [];
  List<EpisodeRecord> _episodeRecords = [];
  SubjectCollection? _subjectCollection;
  CollectionType? _collectionType;

  static const double _globalPadding = 10.0;

  List<EpisodeCollection> _episodeCollections = List.empty();

  String _selectedCollectBtnLabelVal = "收藏";
  IconData _selectedCollectBtnIconData = Icons.star_border_outlined;
  late MenuController _collectMenuController;

  Future<void> _loadSubjectWithId() async {
    _subject = await SubjectApi().findById(int.parse(widget.id.toString()));
    _episodeCollections = await EpisodeCollectionApi()
        .findListBySubjectId(int.parse(widget.id.toString()));
    setState(() {});
  }

  Future<void> _loadSubjectRelationsWithId() async {
    _subjectRelations =
        await SubjectRelationApi().findById(int.parse(widget.id.toString()));
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

  Future<void> _loadBaseUrl() async {
    AuthParams? authParams = await AuthApi().getAuthParams();
    setState(() {
      _apiBaseUrl = authParams?.baseUrl ?? "";
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSubjectWithId();
    _loadSubjectRelationsWithId();
    _loadBaseUrl();
    _fetchSubjectEpisodes();
    _fetchSubjectEpisodeRecords();
    _fetchSubjectCollection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 96,
        leading: Row(
          children: [
            IconButton(
              tooltip: "Back",
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            IconButton(onPressed: (){
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => ScreenUtils.screenWidthGt600(context)
                    ? const DesktopLayout()
                    : const MobileLayout()),
                    (Route<dynamic> route) => false,
              );
            }, icon: const Icon(Icons.home_outlined))
          ],
        ),
        actions: [_buildLinkIconButton()],
      ),
      body: _subject == null
          ? const LinearProgressIndicator()
          : SingleChildScrollView(
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
            ),
    );
  }

  Widget _buildLinkIconButton() {
    return IconButton(
        onPressed: () async {
          if (_apiBaseUrl == "") {
            await _loadBaseUrl();
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
    var name = (_subject?.nameCn != null && _subject?.nameCn != '')
        ? _subject?.nameCn!
        : _subject?.name;
    return Text(
      name ?? "",
      overflow: TextOverflow.ellipsis,
      style:
          const TextStyle(color: Colors.black, backgroundColor: Colors.white),
    );
  }

  String _getSubjectTitle() {
    if (_subject?.nameCn != null && "" != _subject?.nameCn) {
      return _subject?.nameCn ?? "";
    }
    return _subject?.name ?? "";
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
            Text("${SubjectConst.typeCnMap[_subject?.type.name]} "
                "- 全${_episodeRecords.isNotEmpty ? _episodeRecords.length : _episodes.length}话")
          ],
        ))
      ],
    );
  }

  Widget _buildSubjectCover() {
    if (_apiBaseUrl == "") return const LinearProgressIndicator();
    return SizedBox(
      width: 120,
      child: SubjectCover(
        url: UrlUtils.getCoverUrl(_apiBaseUrl, _subject?.cover ?? ""),
        nsfw: _subject?.nsfw,
      ),
    );
  }

  Widget _buildSubjectTitleInfo() {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        Text(
          _subject?.nameCn ?? _subject?.name ?? "",
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        OutlinedButton(onPressed: () {}, child: const Text('2020 年 10 月')),
        // const Text("类型", style: TextStyle(fontWeight: FontWeight.bold),),
        // Text(_subject.type.toString(), overflow: TextOverflow.ellipsis,),

        Text(
          _subject?.name ?? "",
          overflow: TextOverflow.ellipsis,
        ),

        Text(_subject?.nameCn ?? "", overflow: TextOverflow.ellipsis),
        Text(_subject?.nameCn ?? "", overflow: TextOverflow.ellipsis),
        Text(_subject?.nameCn ?? "", overflow: TextOverflow.ellipsis),

        Text(_subject?.nsfw == true ? "是" : "否",
            overflow: TextOverflow.ellipsis),

        Text("${_episodes.length}", overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Row _buildEpisodeAndCollectionButtonsRow() {
    SubjectType? type = _subject?.type;
    bool allowType = true;
    if (type == SubjectType.GAME ||
        type == SubjectType.COMIC ||
        type == SubjectType.NOVEL) {
      // Toast.show(context, "当前类型[$type]不支持进入剧集页展示，请期待后续的新功能更新。");
      allowType = false;
    }
    bool hasResource = false;
    for (var r in _episodeRecords) {
      if (r.resources.isNotEmpty) {
        hasResource = true;
        break;
      }
    }
    bool toEpisodeBtnEnable = (hasResource && allowType);
    String displayTitle = "继续观看";
    if (!toEpisodeBtnEnable) {
      if (!hasResource) {
        displayTitle = "剧集无资源";
      }
      if (!allowType) {
        displayTitle = "类型[${SubjectConst.typeCnMap[type?.name]}]不支持";
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildCollectionMenuAnchor(),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: !toEpisodeBtnEnable
                  ? null
                  : () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SubjectEpisodesPage(
                                subjectId: _subject?.id ?? -1,
                              )));
                    },
              style: OutlinedButton.styleFrom(
                  disabledMouseCursor: SystemMouseCursors.forbidden),
              label: Text(
                displayTitle,
                style: TextStyle(
                    color: !toEpisodeBtnEnable ? Colors.grey : Colors.black),
              ),
              icon: Icon(
                toEpisodeBtnEnable
                    ? Icons.play_circle_outline
                    : Icons.error_outline_sharp,
                color: !toEpisodeBtnEnable ? Colors.grey : Colors.black,
              ),
            ),
            // _buildEpisodeSelectButton(),
          ],
        ),
      ],
    );
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
                style: const TextStyle(color: Colors.black)),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMultiTabs() {
    List<Tab> barTabs = [
      const Tab(text: '介绍'),
      const Tab(text: '信息'),
    ];
    int viewLength = 2;
    List<Widget> barViews = [
      Text(
        _subject?.summary ?? "",
        style: const TextStyle(overflow: TextOverflow.ellipsis),
        maxLines: 40,
        softWrap: true,
      ),
      SingleChildScrollView(
        child: Text(
          _subject?.infobox ?? "",
          style: const TextStyle(overflow: TextOverflow.ellipsis),
          maxLines: 100,
          softWrap: true,
        ),
      ),
    ];
    if (_subjectRelations.isNotEmpty) {
      barTabs.add(const Tab(
        text: "关联",
      ));
      viewLength = 3;
      barViews.add(_buildSubjectRelationsMultiTabs());
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 550),
      child: DefaultTabController(
          length: viewLength,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TabBar(
                  tabs: barTabs,
                ),
              ),
              Expanded(
                  child: TabBarView(
                children: barViews,
              )),
            ],
          )),
    );
  }

  Widget _buildSubjectRelationsMultiTabs() {
    Set<SubjectRelationType> types =
        _subjectRelations.map((subRel) => subRel.relationType).toSet();
    int viewLength = types.length;
    List<Tab> barTabs = types
        .map((type) => SubjectConst.relationTypeCnMap[type.name])
        .map((name) => Tab(
              text: name,
            ))
        .toList();
    List<Widget> barViews = [];
    for (var type in types) {
      var relSubIds = _subjectRelations
          .where((subRel) => subRel.relationType == type)
          .first
          .relationSubjects;
      List<Widget> views = relSubIds
          .map((id) => FutureBuilder<Subject?>(
              future: SubjectApi().findById(id),
              builder: (context, AsyncSnapshot<Subject?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return SizedBox(
                    width: ScreenUtils.isDesktop(context) ? 240 : 120,
                    child: Column(
                      children: [
                        SubjectCover(
                          url: UrlUtils.getCoverUrl(
                              _apiBaseUrl, snapshot.data?.cover ?? "Not Cover"),
                          nsfw: snapshot.data?.nsfw,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => SubjectPage(
                                  id: snapshot.data?.id.toString(),
                                )));
                          },
                        ),
                        Flexible(
                            child: Text(
                              ((snapshot.data?.nameCn == null ||
                                  snapshot.data?.nameCn == '')
                                  ? snapshot.data?.name
                                  : snapshot.data?.nameCn) ?? "Unknown",
                              maxLines: 2,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            )),
                      ],
                    )
                  );
                }
              }))
          .map((subCov) => Padding(
                padding: const EdgeInsets.all(_globalPadding),
                child: subCov,
              ))
          .toList();

      SingleChildScrollView view = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(_globalPadding),
          child: Row(
            children: views,
          ),
        ),
      );
      barViews.add(view);
    }

    return DefaultTabController(
        length: viewLength,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: TabBar(
                tabs: barTabs,
              ),
            ),
            Expanded(
                child: TabBarView(
              children: barViews,
            )),
          ],
        ));
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
    } else {
      /// _collectionType is null
      _selectedCollectBtnLabelVal = "收藏";
      _selectedCollectBtnIconData = Icons.star_border_outlined;
    }
  }

  String? _getSubjectName() {
    if (_subject?.nameCn != null && _subject?.nameCn != "") {
      return _subject?.nameCn;
    }
    return _subject?.name;
  }

  Future<void> _postCollectSubject() async {
    await _postCollectSubjectWithoutRefresh(CollectionType.WISH);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => SubjectPage(id: _subject?.id.toString())),
    );
  }

  Future<void> _postCollectSubjectWithoutRefresh(CollectionType type) async {
    if (_subject == null) return;
    await SubjectCollectionApi()
        .updateCollection(_subject!.id, type, _subject!.nsfw);
    Toast.show(context, "收藏番剧[${_getSubjectName()}]成功.");
  }

  Future<void> _postUnCollectSubject() async {
    if (_subject == null) return;
    await SubjectCollectionApi().removeCollection(_subject!.id);
    Toast.show(context, "取消收藏番剧[${_getSubjectName()}]成功.");
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //       builder: (context) => SubjectPage(id: _subject.id.toString())),
    // );
  }

  String _getAirTimeStr() {
    if (_subject == null) return "";
    if (_subject!.airTime == null || "" == _subject!.airTime) {
      return "1970 年 1 月";
    }
    DateTime dateTime = DateTime.parse(_subject!.airTime!);
    return DateFormat('yyyy 年 MM 月').format(dateTime);
  }
}
