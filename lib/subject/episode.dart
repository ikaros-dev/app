import 'dart:async';
import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart' as DartVlc;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/api/attachment/AttachmentRelationApi.dart';
import 'package:ikaros/api/attachment/model/VideoSubtitle.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/EpisodeCollectionApi.dart';
import 'package:ikaros/api/collection/model/EpisodeCollection.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
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
import 'package:ikaros/utils/shared_prefs_utils.dart';
import 'package:ikaros/utils/time_utils.dart';
import 'package:ikaros/utils/url_utils.dart';
import 'package:intl/intl.dart';

class SubjectEpisodePage extends StatefulWidget {
  final Episode episode;
  final Subject? subject;

  const SubjectEpisodePage({super.key, required this.episode, this.subject});

  @override
  State<StatefulWidget> createState() {
    return _SubjectEpisodeState();
  }
}

class _SubjectEpisodeState extends State<SubjectEpisodePage> {
  late String _apiBaseUrl = "";
  late Episode _episode;

  bool _isFullScreen = false;
  String _videoUrl = '';
  List<String> _videoSubtitleUrls = [];
  String _videoTitle = '';
  String _episodeResName = '';
  int _progress = 0;
  late EpisodeResource? _currentResource = null;
  late List<EpisodeResource> _episodeResList = [];

  late GlobalKey<MobileVideoPlayerState> _mobilePlayer;
  late GlobalKey<MobileAudioPlayerState> _mobileAudioPlayer;
  late GlobalKey<DesktopVideoPlayerState> _desktopPlayer;
  late GlobalKey<DesktopAudioPlayerState> _desktopAudioPlayer;

  Future<AuthParams> _loadBaseUrl() async {
    return AuthApi().getAuthParams();
  }

  @override
  void initState() {
    super.initState();
    _episode = widget.episode;
    _mobilePlayer = GlobalKey<MobileVideoPlayerState>();
    _mobileAudioPlayer = GlobalKey<MobileAudioPlayerState>();
    _desktopPlayer = GlobalKey<DesktopVideoPlayerState>();
    _desktopAudioPlayer = GlobalKey<DesktopAudioPlayerState>();

    _videoTitle =
        "${_episode.sequence}: ${(_episode.nameCn != null && _episode.nameCn != '') ? _episode.nameCn! : _episode.name}";

    _fetchEpisodeResources();
  }

  Future<void> _fetchEpisodeResources() async {
    var id = widget.episode.id;
    _episodeResList = await EpisodeApi().getEpisodeResourcesRefs(id);
    if (_episodeResList.isNotEmpty) {
      _videoUrl = _episodeResList.first.url;
      _loadEpisodeResource(_episodeResList.first);
    }
    setState(() {});
  }

  // void release() {
  //   Duration current = Duration.zero;
  //   Duration duration = Duration.zero;
  //
  //   if (Platform.isAndroid || Platform.isIOS) {
  //     current = _mobilePlayer.currentState?.getPosition() ?? Duration.zero;
  //     duration = _mobilePlayer.currentState?.getDuration() ?? Duration.zero;
  //   } else {
  //     current = _desktopPlayer.currentState?.getPosition() ?? Duration.zero;
  //     duration = _desktopPlayer.currentState?.getDuration() ?? Duration.zero;
  //   }
  //
  //   if (current.inMilliseconds.toInt() > 0) {
  //     EpisodeCollectionApi().updateCollection(
  //         widget.episode.id, current, duration);
  //     print("保存剧集进度成功");
  //   }
  //
  // }

  void _onFullScreenChange() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize:
              Size.fromHeight(MediaQuery.of(context).size.height * 0.07),
          child: Visibility(
            visible: !_isFullScreen,
            child: AppBar(
              leading: IconButton(
                tooltip: "Back",
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(widget.episode.name),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: _buildEpisodePage(),
        ));
  }

  Widget _buildEpisodePage() {
    if (_episodeResList.isEmpty) {
      return const LinearProgressIndicator();
    }
    return Column(
      children: [
        _buildMediaPlayer(),
        Visibility(
          visible: !_isFullScreen,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "资源",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              _buildResourceSelectListView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPlayer() {
    if (widget.subject != null &&
        widget.subject?.type != null &&
        widget.subject?.type == SubjectType.MUSIC) {
      if (Platform.isAndroid || Platform.isIOS) {
        return MobileAudioPlayer(
          key: _mobileAudioPlayer,
        );
      }
      return DesktopAudioPlayer(
        key: _desktopAudioPlayer,
      );
    }

    return _buildVideoPlayer();
  }

  Widget _buildVideoPlayer() {
    bool useMobileVideoPlayer = Platform.isAndroid || Platform.isIOS;
    bool gt600 = ScreenUtils.screenWidthGt600(context);
    return Container(
      color: Colors.black,
      height: gt600
          ? MediaQuery.of(context).size.height
          : _isFullScreen
              ? MediaQuery.of(context).size.height
              : 200,
      width: MediaQuery.of(context).size.width,
      child: useMobileVideoPlayer
          ? MobileVideoPlayer(
              key: _mobilePlayer,
              onFullScreenChange: _onFullScreenChange,
            )
          : DesktopVideoPlayer(
              key: _desktopPlayer,
              onFullScreenChange: _onFullScreenChange,
            ),
    );
  }

  Future setVideoUrl() async {
    // 音频
    if (widget.subject != null &&
        widget.subject?.type != null &&
        widget.subject?.type == SubjectType.MUSIC) {
      AuthParams authParams = await _loadBaseUrl();
      String coverUrl =
          UrlUtils.getCoverUrl(authParams.baseUrl, widget.subject?.cover ?? "");
      if (Platform.isAndroid || Platform.isIOS) {
        _mobileAudioPlayer.currentState?.setTitle(_videoTitle);
        _mobileAudioPlayer.currentState?.setCoverUrl(coverUrl);
        _mobileAudioPlayer.currentState?.open(_videoUrl, autoStart: true);
        if (kDebugMode) print("open audio player with _videoUrl:$_videoUrl");
        return;
      }
      _desktopAudioPlayer.currentState?.setTitle(_videoTitle);
      _desktopAudioPlayer.currentState?.setCoverUrl(coverUrl);
      _desktopAudioPlayer.currentState?.open(_videoUrl, autoStart: true);
      if (kDebugMode) print("open audio player with _videoUrl:$_videoUrl");
      return;
    }

    /// 移动端
    if (Platform.isAndroid || Platform.isIOS) {
      if (_videoSubtitleUrls.isNotEmpty) {
        _mobilePlayer.currentState?.setSubtitleUrls(_videoSubtitleUrls);
      }

      _mobilePlayer.currentState?.setTitle(_videoTitle);
      _mobilePlayer.currentState?.setSubTitle(_episodeResName);
      _mobilePlayer.currentState?.setEpisodeId(widget.episode.id);

      if (_progress > 0) {
        _mobilePlayer.currentState?.setProgress(_progress);
      }
      _mobilePlayer.currentState?.open(_videoUrl, autoPlay: true);
      setState(() {});
      return;
    }

    /// 桌面端
    _desktopPlayer.currentState?.setTitle(_videoTitle);
    _desktopPlayer.currentState?.setSubTitle(_episodeResName);
    _desktopPlayer.currentState?.setEpisodeId(widget.episode.id);

    _desktopPlayer.currentState?.open(_videoUrl, autoStart: true);

    if (_videoSubtitleUrls.isNotEmpty) {
      setState(() {
        for (var subtitle in _videoSubtitleUrls) {
          _desktopPlayer.currentState
              ?.addSlave(DartVlc.MediaSlaveType.subtitle, subtitle, true);
        }
      });
    }

    if (_progress > 0) {
      _desktopPlayer.currentState?.seek(Duration(milliseconds: _progress));
      if (kDebugMode) {
        print("seek video to : $_progress");
      }
      Toast.show(context, "已请求跳转到上次的进度:${TimeUtils.convertMinSec(_progress)}");
    }
  }

  Future _loadApiBaseUrl() async {
    if (_apiBaseUrl.isEmpty) {
      _apiBaseUrl = (await AuthApi().getAuthParams()).baseUrl;
    }
  }

  Future<List<VideoSubtitle>> _loadVideoSubtitlesByAttId(int attId) async {
    return AttachmentRelationApi().findByAttachmentId(attId);
  }

  Future<EpisodeResource> _loadEpisodeResource(
      EpisodeResource episodeResource) async {
    await _loadApiBaseUrl();

    if (episodeResource.attachmentId == _currentResource?.attachmentId) {
      return Future.value(episodeResource);
    }

    setState(() {
      _currentResource = episodeResource;
    });

    print(
        "[episode] sequence: ${_episode.sequence}, nameCn: ${_episode.nameCn}, name: ${_episode.name}");
    _videoTitle =
        "${_episode.sequence}: ${(_episode.nameCn != null && _episode.nameCn != '') ? _episode.nameCn! : _episode.name}";
    print("_episode video title: $_videoTitle");
    _episodeResName = episodeResource.name;
    print("episode title: $_videoTitle");
    if (episodeResource.url.startsWith("http")) {
      _videoUrl = episodeResource.url;
    } else {
      _videoUrl = _apiBaseUrl + episodeResource.url;
    }
    print("episode resource video url: $_videoUrl");
    if (_episodeResList.isNotEmpty) {
      List<VideoSubtitle> videoSubtitles = await AttachmentRelationApi()
          .findByAttachmentId(episodeResource.attachmentId);
      List<String> subtitleUrls = [];
      for (var element in videoSubtitles) {
        var subUrl = '';
        if (element.url.startsWith("http")) {
          subUrl = element.url;
        } else {
          subUrl = _apiBaseUrl + element.url;
        }
        subtitleUrls.add(subUrl);
      }
      setState(() {
        _videoSubtitleUrls = subtitleUrls;
      });
      print("video subtitle urls: $_videoSubtitleUrls");
    }

    // seek to
    EpisodeCollection episodeCollection =
        await EpisodeCollectionApi().findCollection(episodeResource.episodeId);
    if (episodeCollection.progress != null && episodeCollection.progress! > 0) {
      print("find episode collection progress:${episodeCollection.progress}");
      setState(() {
        _progress = episodeCollection.progress!;
      });
    }

    await setVideoUrl();
    return episodeResource;
  }

  Widget _buildResourceSelectListView() {
    if (_episodeResList.isEmpty) {
      return Container();
    }
    var items = _episodeResList
        .map((res) => MaterialButton(
            onPressed: () {
              _loadEpisodeResource(res);
            },
            color: (_currentResource != null &&
                    _currentResource!.attachmentId == res.attachmentId)
                ? Colors.lightBlue
                : Colors.white,
            shape: const RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.deepPurple,
                width: 1,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            child: Text(
              res.name,
              overflow: TextOverflow.ellipsis,
            )))
        .map((textBtn) => Container(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: SizedBox(
                height: 40,
                child: textBtn,
              ),
            ))
        .toList();
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: ListView(
        children: items,
      ),
    );
  }
}

class SubjectEpisodesPage extends StatefulWidget {
  final EpisodeRecord episodeRecord;
  final Subject subject;

  const SubjectEpisodesPage(
      {super.key, required this.episodeRecord, required this.subject});

  @override
  State<StatefulWidget> createState() {
    return _SubjectEpisodesState();
  }
}

class _SubjectEpisodesState extends State<SubjectEpisodesPage> {
  List<EpisodeRecord> _episodeRecords = [];
  late GlobalKey<MobileVideoPlayerState> _mobilePlayer;
  late GlobalKey<MobileAudioPlayerState> _mobileAudioPlayer;
  late GlobalKey<DesktopVideoPlayerState> _desktopPlayer;
  late GlobalKey<DesktopAudioPlayerState> _desktopAudioPlayer;

  bool _isFullScreen = false;
  var _loadApiBaseUrlFuture;
  String _apiBaseUrl = "";
  final ValueNotifier<EpisodeRecord?> _currentEpisodeRecord =
      ValueNotifier(null);
  int _currentEpisodeResourceIndex = 0;

  @override
  void initState() {
    super.initState();

    _mobilePlayer = GlobalKey<MobileVideoPlayerState>();
    _mobileAudioPlayer = GlobalKey<MobileAudioPlayerState>();
    _desktopPlayer = GlobalKey<DesktopVideoPlayerState>();
    _desktopAudioPlayer = GlobalKey<DesktopAudioPlayerState>();

    EpisodeApi()
        .findRecordsBySubjectId(int.parse(widget.subject.id.toString()))
        .then((epRecords) => setState(() {
              _episodeRecords = epRecords;
            }));

    _loadApiBaseUrlFuture = _loadBaseUrl();
    _currentEpisodeRecord.addListener(reloadMediaPlayer);
    _currentEpisodeRecord.value = widget.episodeRecord;
  }

  Future<void> reloadMediaPlayer() async {
    if (_currentEpisodeRecord.value == null) return;
    EpisodeRecord episodeRecord = _currentEpisodeRecord.value!;
    if (episodeRecord.resources.isEmpty) return;
    EpisodeResource episodeResource =
        episodeRecord.resources[_currentEpisodeResourceIndex];

    if (_apiBaseUrl == "") {
      AuthParams authParams = await AuthApi().getAuthParams();
      setState(() {
        _apiBaseUrl = authParams.baseUrl;
      });
    }

    String coverUrl =
        UrlUtils.getCoverUrl(_apiBaseUrl, widget.subject.cover ?? "");
    String videUrl = UrlUtils.getCoverUrl(_apiBaseUrl, episodeResource.url);
    String videoTitle = _getEpisodeName(episodeRecord.episode);
    String videoSubTitle = episodeResource.name;

    // 音频
    if (widget.subject.type == SubjectType.MUSIC) {
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
      } else {
        subUrl = _apiBaseUrl + element.url;
      }
      subtitleUrls.add(subUrl);
    }
    ;

    // 视频收藏
    EpisodeCollection episodeCollection =
        await EpisodeCollectionApi().findCollection(episodeResource.episodeId);
    int progress = episodeCollection.progress ?? 0;

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
      setState(() {});
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
    return SubjectType.MUSIC == widget.subject.type
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
              : 250,
      width: MediaQuery.of(context).size.width,
      child: Platform.isAndroid || Platform.isIOS
          ? MobileVideoPlayer(
              key: _mobilePlayer,
              onFullScreenChange: () {
                setState(() {
                  _isFullScreen = !_isFullScreen;
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
            ),
    );
  }

  Widget _buildOther() {
    if (_episodeRecords.isEmpty) return const LinearProgressIndicator();
    Episode episode = _currentEpisodeRecord.value!.episode;
    debugPrint("episode:${_getEpisodeName(episode)}");

    bool hasResources = _currentEpisodeRecord.value != null &&
        _currentEpisodeRecord.value!.resources.isNotEmpty;
    bool resourcesSizeGtOne =
        hasResources && _currentEpisodeRecord.value!.resources.length > 1;
    bool selectResourcesButtonEnable = hasResources && resourcesSizeGtOne;

    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Material(
              child: Card(
                // margin: const EdgeInsets.all(10),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: ListTile(
                    leading: DynamicBarIcon(),
                    title: Text(
                      "${NumberUtils.doubleIsInt(episode.sequence) ? episode.sequence.toInt() : episode.sequence}: ${_getEpisodeName(episode)}",
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
              ),
            ),
            // const Text(
            //   "当前弹幕",
            //   style: TextStyle(
            //     fontSize: 18,
            //     color: Colors.black,
            //     decoration: TextDecoration.none,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
          ],
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
              "${SubjectConst.typeCnMap[widget.subject.type.name]} "
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
                  url: UrlUtils.getCoverUrl(_apiBaseUrl, widget.subject.cover),
                  nsfw: widget.subject.nsfw,
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

  String _getSubjectTitle() {
    if (widget.subject.nameCn != null && "" != widget.subject.nameCn) {
      return widget.subject.nameCn!;
    }
    return widget.subject.name;
  }

  String _getAirTimeStr() {
    if (widget.subject.airTime == null || "" == widget.subject.airTime) {
      return "1970 年 1 月";
    }
    DateTime dateTime = DateTime.parse(widget.subject.airTime!);
    return DateFormat('yyyy 年 MM 月').format(dateTime);
  }

  Future<AuthParams> _loadBaseUrl() async {
    return AuthApi().getAuthParams();
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
    if (widget.subject.type == SubjectType.GAME ||
        widget.subject.type == SubjectType.COMIC ||
        widget.subject.type == SubjectType.NOVEL ||
        widget.subject.type == SubjectType.OTHER) {
      Toast.show(context,
          "当前条目类型[${SubjectConst.typeCnMap[widget.subject.type.name] ?? "未知"}]不支持视频播放");
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
                                  ? DynamicBarIcon()
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
              child: _buildEpisodeSelectTabBar(),
            ),
            Expanded(flex: 1, child: _buildEpisodeSelectTabView()),
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

  TabBarView _buildEpisodeSelectTabView() {
    var groups = _getEpisodeGroupEnums();
    var tabViews =
        groups.map((g) => _getEpisodesTabViewByGroup(g.name)).toList();
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

  Widget _getEpisodesTabViewByGroup(String group) {
    List<Widget>? buttons = _getEpisodeRecordsByGroup(group)
        ?.map((epRecord) => _buildEpisodeRecordWidget(epRecord))
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

  Widget _buildEpisodeRecordWidget(EpisodeRecord epRecord) {
    return Container(
      padding: const EdgeInsets.all(5),
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints(minHeight: 60),
      child: OutlinedButton.icon(
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
          disabledBackgroundColor: Colors.grey[400],
          disabledForegroundColor: Colors.grey[600],
        ),
        icon: epRecord == _currentEpisodeRecord.value
            ? DynamicBarIcon()
            : const Icon(Icons.play_circle_outline),
        label: Text(
          "${NumberUtils.doubleIsInt(epRecord.episode.sequence) ? epRecord.episode.sequence.toInt() : epRecord.episode.sequence}: ${_getEpisodeName(epRecord.episode)}",
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
