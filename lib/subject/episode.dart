import 'dart:async';
import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart' as DartVlc;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/api/attachment/AttachmentApi.dart';
import 'package:ikaros/api/attachment/AttachmentRelationApi.dart';
import 'package:ikaros/api/attachment/SubtitleDownloader.dart';
import 'package:ikaros/api/attachment/model/VideoSubtitle.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/EpisodeCollectionApi.dart';
import 'package:ikaros/api/collection/model/EpisodeCollection.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/enums/EpisodeGroup.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeRecord.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/component/dynamic_bar_icon.dart';
import 'package:ikaros/component/subject/subject.dart';
import 'package:ikaros/consts/subject_const.dart';
import 'package:ikaros/player/player_audio_desktop.dart';
import 'package:ikaros/player/player_audio_mobile.dart';
import 'package:ikaros/player/player_video_desktop.dart';
import 'package:ikaros/player/player_video_mobile.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/number_utils.dart';
import 'package:ikaros/utils/screen_utils.dart';
import 'package:ikaros/utils/time_utils.dart';
import 'package:ikaros/utils/url_utils.dart';
import 'package:intl/intl.dart';

class SubjectEpisodesPage extends StatefulWidget {
  final int subjectId;
  final double? selectEpisodeSequence;
  final String? selectEpisodeGroup;

  const SubjectEpisodesPage({super.key, required this.subjectId, this.selectEpisodeGroup, this.selectEpisodeSequence});

  @override
  State<StatefulWidget> createState() {
    return _SubjectEpisodesState();
  }
}

class _SubjectEpisodesState extends State<SubjectEpisodesPage> {
  Subject? _subject;
  List<EpisodeRecord> _episodeRecords = [];
  List<EpisodeCollection> _episodeCollections = List.empty();
  late GlobalKey<MobileVideoPlayerState> _mobilePlayer;
  late GlobalKey<MobileAudioPlayerState> _mobileAudioPlayer;
  late GlobalKey<DesktopVideoPlayerState> _desktopPlayer;
  late GlobalKey<DesktopAudioPlayerState> _desktopAudioPlayer;

  bool _isFullScreen = false;
  String _apiBaseUrl = "";
  final ValueNotifier<EpisodeRecord?> _currentEpisodeRecord =
      ValueNotifier(null);
  int _currentEpisodeResourceIndex = 0;
  int _danmuCount = 0;

  Future<void> _loadSubjectWithId() async {
    _subject = await SubjectApi().findById(widget.subjectId);
    setState(() {});
  }

  Future<void> _loadEpisodeRecordsWithSubjectId() async {
    _episodeRecords =
        await EpisodeApi().findRecordsBySubjectId(widget.subjectId);
    _episodeRecords
        .sort((r1, r2) => r1.episode.sequence.compareTo(r2.episode.sequence));
    setState(() {});
  }

  Future<void> _loadEpisodeCollectionsWithSubjectId() async {
    _episodeCollections =
        await EpisodeCollectionApi().findListBySubjectId(widget.subjectId);
    setState(() {});
  }

  /// 当前未看的 && 有附件绑定的 && 正片 => 第一个
  Future<void> _loadCurrentEpisodeRecord() async {
    _currentEpisodeRecord.value = _episodeRecords
        .where((epRecord) => !_episodeIsFinish(epRecord.episode.id))
        .where((epRecord) => epRecord.resources.isNotEmpty)
        .where((epRecord) => epRecord.episode.group == EpisodeGroup.MAIN.name)
        .firstOrNull;
    // 如果指定了剧集参数，则使用剧集参数覆盖当前剧集
    if (widget.selectEpisodeSequence != null && widget.selectEpisodeGroup != null) {
      var newSelectEpisodeRecord = _episodeRecords
          .where((epRecord) => widget.selectEpisodeGroup == epRecord.episode.group
       && widget.selectEpisodeSequence == epRecord.episode.sequence
      && epRecord.resources.isNotEmpty).firstOrNull;
      if (newSelectEpisodeRecord != null) {
        _currentEpisodeRecord.value = newSelectEpisodeRecord;
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _mobilePlayer = GlobalKey<MobileVideoPlayerState>();
    _mobileAudioPlayer = GlobalKey<MobileAudioPlayerState>();
    _desktopPlayer = GlobalKey<DesktopVideoPlayerState>();
    _desktopAudioPlayer = GlobalKey<DesktopAudioPlayerState>();
    _currentEpisodeRecord.addListener(reloadMediaPlayer);

    _loadApiBaseUrl();
    _loadSubjectWithId();
    _loadEpisodeRecordsWithSubjectId().then((_) {
      _loadEpisodeCollectionsWithSubjectId().then((_) {
        _loadCurrentEpisodeRecord();
      });
    });
  }

  void _onPlayCompleted() {
    Toast.show(context, "剧集已经播放完成，3秒后切换下一集！", duration: const Duration(seconds: 3));
    Future.delayed(const Duration(seconds: 3), (){
      Toast.show(context, "切换下一集中...");
      if (_currentEpisodeRecord.value == null) { return; }
      _episodeRecords.where((epRecord) => epRecord.episode.group == _currentEpisodeRecord.value?.episode.group);
      final index = _episodeRecords.indexOf(_currentEpisodeRecord.value!);
      final nextIndex = index + 1;
      if (nextIndex < _episodeRecords.length) {
        _currentEpisodeRecord.value = _episodeRecords[nextIndex];
      }
    });
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

  Future<void> reloadMediaPlayer() async {
    await _loadEpisodeCollectionsWithSubjectId();
    if (_currentEpisodeRecord.value == null || _subject == null) return;
    EpisodeRecord episodeRecord = _currentEpisodeRecord.value!;
    if (episodeRecord.resources.isEmpty) return;
    EpisodeResource episodeResource =
        episodeRecord.resources[_currentEpisodeResourceIndex];

    if (_apiBaseUrl == "") {
      await _loadApiBaseUrl();
    }

    String coverUrl = UrlUtils.getCoverUrl(_apiBaseUrl, _subject?.cover ?? "");
    // String videUrl = UrlUtils.getCoverUrl(_apiBaseUrl, episodeResource.url);
    String videUrl = await AttachmentApi().findReadUrlByAttachmentId(episodeResource.attachmentId);
    if (videUrl.startsWith("/")) videUrl = UrlUtils.getCoverUrl(_apiBaseUrl, videUrl);
    String videoTitle = _getEpisodeName(episodeRecord.episode);
    String videoSubTitle = episodeResource.name;

    // 音频
    if (_subject?.type == SubjectType.MUSIC) {
      if (Platform.isAndroid || Platform.isIOS) {
        _mobileAudioPlayer.currentState?.setTitle(videoTitle);
        _mobileAudioPlayer.currentState?.setCoverUrl(coverUrl);
        _mobileAudioPlayer.currentState?.reload(videUrl);
        if (kDebugMode) print("open audio player with videUrl:$videUrl");
        return;
      }
      _desktopAudioPlayer.currentState?.setTitle(videoTitle);
      _desktopAudioPlayer.currentState?.setCoverUrl(coverUrl);
      _desktopAudioPlayer.currentState?.reload(videUrl, autoStart: true);
      if (kDebugMode) print("open audio player with _videoUrl:$videUrl");
      return;
    }

    // 视频字幕
    List<VideoSubtitle> videoSubtitles = await AttachmentRelationApi()
        .findByAttachmentId(episodeResource.attachmentId);
    List<String> subtitleUrls = [];
    for (var element in videoSubtitles) {
      var subUrl = '';
      if (element.url.startsWith("http")) {
        subUrl = element.url;
      } else if(element.url.startsWith("/")) {
        subUrl = _apiBaseUrl + element.url;
      } else {
        // 诸如网盘文件提取码这种情况
        subUrl = _apiBaseUrl + element.url;
      }
      subtitleUrls.add(subUrl);
    }

    // 视频收藏
    EpisodeCollection? episodeCollection =
        await EpisodeCollectionApi().findCollection(episodeResource.episodeId);
    int progress = episodeCollection?.progress ?? 0;

    /// 移动端
    if (Platform.isAndroid || Platform.isIOS) {
      if (subtitleUrls.isNotEmpty) {
        _mobilePlayer.currentState?.setSubtitleUrls(subtitleUrls);
      }

      _mobilePlayer.currentState?.setTitle(videoTitle);
      _mobilePlayer.currentState?.setSubTitle(videoSubTitle);
      _mobilePlayer.currentState?.setEpisodeId(episodeRecord.episode.id);

      if (progress > 0) {
        _mobilePlayer.currentState?.setProgress(progress);
      }
      _mobilePlayer.currentState?.reload(videUrl, autoPlay: true);
      return;
    }

    /// 桌面端
    _desktopPlayer.currentState?.setTitle(videoTitle);
    _desktopPlayer.currentState?.setSubTitle(videoSubTitle);
    _desktopPlayer.currentState?.setEpisodeId(episodeRecord.episode.id);
    _desktopPlayer.currentState?.reload(videUrl, autoStart: true);

    if (subtitleUrls.isNotEmpty) {
      for (var subtitle in subtitleUrls) {
        _desktopPlayer.currentState
            ?.addSlave(DartVlc.MediaSlaveType.subtitle, subtitle, true);
      }
    }

    if (progress > 0) {
      _desktopPlayer.currentState?.seek(Duration(milliseconds: progress));
      if (kDebugMode) {
        print("seek video to : $progress");
      }
      Toast.show(context, "已请求跳转到上次的进度:${TimeUtils.convertMinSec(progress)}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ScreenUtils.screenWidthGt600(context)) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _isFullScreen
                  ? MediaQuery.of(context).size.width
                  : MediaQuery.of(context).size.width * 0.7,
              child: _buildMediaPlayer(),
            ),
            Visibility(
                visible: !_isFullScreen,
                child: Expanded(
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                  child: _buildOther(),
                ))),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: Column(
          children: [
            _buildMediaPlayer(),
            Visibility(
                visible: !_isFullScreen,
                child: Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                    child: _buildOther(),
                  ),
                )),
          ],
        ),
      );
    }
  }

  Widget _buildMediaPlayer() {
    if (_subject == null) return const LinearProgressIndicator();
    return SubjectType.MUSIC == _subject?.type
        ? _buildAudioPlayer()
        : _buildVideoPlayer();
  }

  Widget _buildAudioPlayer() {
    return Platform.isAndroid || Platform.isIOS
        ? MobileAudioPlayer(
            key: _mobileAudioPlayer,
          )
        : DesktopAudioPlayer(
            key: _desktopAudioPlayer,
          );
  }

  Widget _buildVideoPlayer() {
    return Container(
      color: Colors.black,
      height: ScreenUtils.screenWidthGt600(context)
          ? MediaQuery.of(context).size.height
          : _isFullScreen
              ? MediaQuery.of(context).size.height
              : 200,
      width: MediaQuery.of(context).size.width,
      child: Platform.isAndroid || Platform.isIOS
          ? MobileVideoPlayer(
              key: _mobilePlayer,
              onFullScreenChange: () {
                setState(() {
                  _isFullScreen = !_isFullScreen;
                });
              },
              onPlayCompleted: _onPlayCompleted,
              onDanmukuPoolInitialed: (int count) {
                setState(() {
                  _danmuCount = count;
                });
              },
            )
          : DesktopVideoPlayer(
              key: _desktopPlayer,
              onFullScreenChange: () {
                setState(() {
                  _isFullScreen = !_isFullScreen;
                });
              },
              onPlayCompleted: _onPlayCompleted,
              onDanmukuPoolInitialed: (int count) {
                setState(() {
                  _danmuCount = count;
                });
              },
            ),
    );
  }

  Widget _buildOther() {
    if (_subject == null || _apiBaseUrl == "") {
      return const LinearProgressIndicator();
    }

    bool hasResources = _currentEpisodeRecord.value != null &&
        _currentEpisodeRecord.value!.resources.isNotEmpty;
    bool resourcesSizeGtOne =
        hasResources && _currentEpisodeRecord.value!.resources.length > 1;
    bool selectResourcesButtonEnable = hasResources && resourcesSizeGtOne;

    return SingleChildScrollView(
      child: Material(
        color: Colors.white,
        child: Container(
          constraints:
              BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 5,
              ),
              _buildSubjectDisplayRow(),
              const SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        "当前剧集",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildEpisodeSelectButton(),
                      const SizedBox(
                        width: 10,
                      ),
                      OutlinedButton.icon(
                        onPressed: selectResourcesButtonEnable
                            ? () async {
                                await _showEpisodeResourcesDialog();
                              }
                            : null,
                        label: Text(
                          "选择附件",
                          style: TextStyle(
                            color: selectResourcesButtonEnable
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          disabledMouseCursor: SystemMouseCursors.forbidden,
                        ),
                        icon: Icon(
                          selectResourcesButtonEnable
                              ? Icons.snippet_folder_outlined
                              : Icons.folder_outlined,
                          color: selectResourcesButtonEnable
                              ? Colors.black
                              : Colors.grey,
                        ),
                      )
                    ],
                  ),
                ],
              ),
              _buildCurrentEpisodeRecordCard(),
              const SizedBox(
                height: 10,
              ),
              if (_danmuCount > 0)
                const Text(
                  "当前弹幕",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (_danmuCount > 0)
                Card(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 50),
                    child: ListTile(
                      leading: const Icon(Icons.subtitles_outlined),
                      title: const Text(
                        "弹弹Play",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "总计数量：$_danmuCount",
                        style: const TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentEpisodeRecordCard() {
    Episode? episode = _currentEpisodeRecord.value?.episode;
    debugPrint("episode:${_getEpisodeName(episode)}");

    String title = "未选中剧集";
    if (episode != null) {
      title =
          "${NumberUtils.doubleIsInt(episode.sequence) ? episode.sequence.toInt() : episode.sequence}: ${_getEpisodeName(episode)}";
    }
    return Card(
      // margin: const EdgeInsets.all(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        child: ListTile(
          leading: episode == null
              ? const Icon(Icons.play_circle_outline)
              : const DynamicBarIcon(),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            _getEpisodeResourceName(),
            style: const TextStyle(
              fontSize: 12,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  String _getEpisodeResourceName() {
    if (_currentEpisodeRecord.value == null) return "未选中剧集";
    EpisodeRecord episodeRecord = _currentEpisodeRecord.value!;
    if (episodeRecord.resources.isEmpty) return "无绑定附件";
    return episodeRecord.resources[_currentEpisodeResourceIndex].name;
  }

  Row _buildSubjectDisplayRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左边封面图片
        _buildSubjectCover(),
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
                  decoration: TextDecoration.none,
                  color: Colors.black),
            ),
            const SizedBox(height: 10),
            Material(
              child: Chip(
                label: Text(_getAirTimeStr()),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "${SubjectConst.typeCnMap[_subject?.type.name]} "
              "- 全${_episodeRecords.isNotEmpty ? _episodeRecords.length : _episodeRecords.length}话",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildSubjectCover() {
    return SizedBox(
      width: 120,
      child: SubjectCover(
        url: UrlUtils.getCoverUrl(_apiBaseUrl, _subject!.cover),
        nsfw: _subject?.nsfw,
      ),
    );
  }

  String _getSubjectTitle() {
    if (_subject == null) return "";
    if (_subject?.nameCn != null && "" != _subject?.nameCn) {
      return _subject?.nameCn ?? "";
    }
    return _subject?.name ?? "";
  }

  String _getAirTimeStr() {
    if (_subject == null) return "";
    if (_subject?.airTime == null || "" == _subject?.airTime) {
      return "1970 年 1 月";
    }
    DateTime dateTime = DateTime.parse(_subject!.airTime!);
    return DateFormat('yyyy 年 MM 月').format(dateTime);
  }

  Future<void> _loadApiBaseUrl() async {
    AuthParams? authParams = await AuthApi().getAuthParams();
    if (authParams == null) return;
    setState(() {
      _apiBaseUrl = authParams.baseUrl;
    });
  }

  Widget _buildEpisodeSelectButton() {
    // 根据APP设置是否拆分剧集资源接口
    return OutlinedButton.icon(
      onPressed: () async {
        await _showEpisodesDialog();
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
  }

  Future<bool?> _showEpisodesDialog() {
    if (_subject?.type == SubjectType.GAME ||
        _subject?.type == SubjectType.COMIC ||
        _subject?.type == SubjectType.NOVEL ||
        _subject?.type == SubjectType.OTHER) {
      Toast.show(context,
          "当前条目类型[${SubjectConst.typeCnMap[_subject?.type.name] ?? "未知"}]不支持视频播放");
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
            child: _buildEpisodeSelectTabs(context),
          ),
        );
      },
    );
  }

  Future<bool?> _showEpisodeResourcesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "选择剧集附件资源播放",
            style: TextStyle(color: Colors.black),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              children: _currentEpisodeRecord.value?.resources
                      .map((epRes) => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(5),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _currentEpisodeResourceIndex =
                                      _currentEpisodeRecord.value?.resources
                                              .indexOf(epRes) ??
                                          0;
                                  reloadMediaPlayer();
                                });
                                Navigator.pop(context);
                              },
                              label: Text(epRes.name),
                              icon: _currentEpisodeRecord.value?.resources
                                          .indexOf(epRes) ==
                                      _currentEpisodeResourceIndex
                                  ? const DynamicBarIcon()
                                  : const Icon(Icons.play_circle_outline),
                            ),
                          ))
                      .toList() ??
                  [],
            ),
          ),
        );
      },
    );
  }

  List<EpisodeGroup> _getEpisodeGroupEnums() {
    var epGroups = <EpisodeGroup>[];
    Set<String?> groupSet;
    if (_episodeRecords.isEmpty) return epGroups;
    groupSet = _episodeRecords.map((e) => e.episode.group).toSet();
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

  Widget _buildEpisodeSelectTabs(BuildContext context) {
    var groups = _getEpisodeGroupEnums();
    var len = 0;
    if (groups.isNotEmpty) len = groups.length;
    if (len == 0) return Container();
    return DefaultTabController(
        length: len,
        child: Column(
          children: [
            Material(
              child: _buildEpisodeSelectTabBar(),
            ),
            Expanded(flex: 1, child: _buildEpisodeSelectTabView(context)),
          ],
        ));
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

  TabBarView _buildEpisodeSelectTabView(BuildContext context) {
    var groups = _getEpisodeGroupEnums();
    var tabViews =
        groups.map((g) => _getEpisodesTabViewByGroup(g.name, context)).toList();
    return TabBarView(
      children: tabViews.isEmpty ? [] : tabViews,
    );
  }

  List<EpisodeRecord>? _getEpisodeRecordsByGroup(String group) {
    if (_episodeRecords.isEmpty) return [];
    var episodeRecords =
        _episodeRecords.where((ep) => ep.episode.group == group).toList();
    episodeRecords
        .sort((me, ot) => me.episode.sequence.compareTo(ot.episode.sequence));
    return episodeRecords;
  }

  Widget _getEpisodesTabViewByGroup(String group, BuildContext context) {
    List<Widget>? buttons = _getEpisodeRecordsByGroup(group)
        ?.map((epRecord) => _buildEpisodeRecordWidget(epRecord, context))
        .toList();

    if (buttons == null) return Container();

    return ListView(
      children: buttons,
    );
  }

  String _getEpisodeName(Episode? episode) {
    if (episode == null) return "剧集未设置标题";
    String? episodeName = episode.nameCn != "" ? episode.nameCn : episode.name;
    episodeName ??= "";
    episodeName = episodeName != "" ? episodeName : "剧集未设置标题";
    return episodeName;
  }

  Widget _buildEpisodeRecordWidget(EpisodeRecord epRecord, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints(minHeight: 60),
      child: OutlinedButton.icon(
        onLongPress: epRecord.resources.isEmpty
            ? null
            : () async {
                bool isFinish = _episodeIsFinish(epRecord.episode.id);
                await EpisodeCollectionApi()
                    .updateCollectionFinish(epRecord.episode.id, !isFinish);
                Toast.show(context, "更新剧集收藏状态为: ${isFinish ? "未看" : "看完"}");
                Navigator.pop(context);
                await _loadEpisodeCollectionsWithSubjectId();
              },
        onPressed: epRecord.resources.isEmpty
            ? null
            : () {
                setState(() {
                  _currentEpisodeResourceIndex = 0;
                  _currentEpisodeRecord.value = epRecord;
                });
                debugPrint(
                    "Select epRecord: ${epRecord.episode.sequence}:${epRecord.episode.name}");
                Navigator.pop(context);
              },
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          disabledBackgroundColor: Colors.grey[400],
          disabledForegroundColor: Colors.grey[600],
          enabledMouseCursor: SystemMouseCursors.click,
          disabledMouseCursor: SystemMouseCursors.forbidden,
        ),
        icon: (epRecord.episode.name ==
                    _currentEpisodeRecord.value?.episode.name &&
                epRecord.episode.sequence ==
                    _currentEpisodeRecord.value?.episode.sequence)
            ? const DynamicBarIcon()
            : (_episodeIsFinish(epRecord.episode.id)
                ? const Icon(Icons.check_circle_outline)
                : const Icon(Icons.play_circle_outline)),
        label: Text(
          "${NumberUtils.doubleIsInt(epRecord.episode.sequence) ? epRecord.episode.sequence.toInt() : epRecord.episode.sequence}: ${_getEpisodeName(epRecord.episode)}",
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
