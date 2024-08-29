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
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/player/player_video_desktop.dart';
import 'package:ikaros/player/player_video_mobile.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/screen_utils.dart';
import 'package:ikaros/utils/time_utils.dart';

class SubjectEpisodePage extends StatefulWidget {
  final Episode episode;

  const SubjectEpisodePage({super.key, required this.episode});

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

  late GlobalKey<MobileVideoPlayerState> _mobilePlayer;
  late GlobalKey<DesktopVideoPlayerState> _desktopPlayer;

  Future<AuthParams> _loadBaseUrl() async {
    return AuthApi().getAuthParams();
  }

  @override
  void initState() {
    super.initState();
    _episode = widget.episode;
    _mobilePlayer = GlobalKey<MobileVideoPlayerState>();
    _desktopPlayer = GlobalKey<DesktopVideoPlayerState>();

    _videoTitle =
        "${_episode.sequence}: ${(_episode.nameCn != null && _episode.nameCn != '') ? _episode.nameCn! : _episode.name}";

    if (_episode.resources != null && _episode.resources!.isNotEmpty) {
      _videoUrl = _episode.resources!.first.url;
      _loadEpisodeResource(_episode.resources!.first);
    }
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
    if (_episode.resources == null || _episode.resources!.isEmpty) {
      return const Text("Current Episode Not Bind Attachment Resources.");
    }
    return Column(
      children: [
        _buildVideoPlayer(),
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
    if (_episode.resources != null && _episode.resources!.isNotEmpty) {
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
    if (_episode.resources == null || _episode.resources!.isEmpty) {
      return Container();
    }
    var items = _episode.resources!
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
