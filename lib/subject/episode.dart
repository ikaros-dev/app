import 'dart:async';
import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart' as DartVlc;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ikaros/api/attachment/AttachmentRelationApi.dart';
import 'package:ikaros/api/attachment/model/VideoSubtitle.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Video.dart';
import 'package:ikaros/video/vlc_player_with_controls.dart';

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
  late GlobalKey<VlcPlayerWithControlsState> _childKey;
  String _videoUrl = "http://";
  List<String> _videoSubtitleUrls = [];
  String _videoTitle = '';
  String _episodeTitle = '';
  late int _currentEpisodeId = 0;
  List<Video> _videoList = <Video>[];
  late EpisodeResource? _currentResource = null;

  // Windows and Linux Dart Vlc Player
  late DartVlc.Player _dartVlcPlayer;

  Future<AuthParams> _loadBaseUrl() async {
    return AuthApi().getAuthParams();
  }

  @override
  void initState() {
    super.initState();
    _episode = widget.episode;
    _childKey = GlobalKey<VlcPlayerWithControlsState>();

    if (Platform.isWindows || Platform.isLinux) {
      _dartVlcPlayer = DartVlc.Player(id: hashCode);
    }
    if (_episode.resources != null && _episode.resources!.isNotEmpty) {
      _loadEpisodeResource(_episode.resources!.first);
    }
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
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: _buildEpisodePage(),
        ));
  }

  Widget _buildEpisodePage(){
    if (_episode.resources == null ||
        _episode.resources!.isEmpty) {
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
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
    bool useDartVlcPlayer = Platform.isWindows || Platform.isLinux;
    if (_currentResource == null) {
      return const CircularProgressIndicator();
    }
    return SizedBox(
      height: _isFullScreen ? MediaQuery.of(context).size.height : 200,
      child: useDartVlcPlayer ?
        DartVlc.Video(
          player: _dartVlcPlayer,
          showControls: true,
        )
      :
      VlcPlayerWithControls(
        key: _childKey,
        updateIsFullScreen: (val) => _updateIsFullScreen(val),
        videoUrl: _videoUrl, videoTitle: _videoTitle, episodeId: _currentEpisodeId,
        subtitleUrls: _videoSubtitleUrls,
      ),
    );
  }

  _updateIsFullScreen(bool val) {
    _isFullScreen = val;
  }

  Future callChildMethod2ChangePlayerDatasource() async {
    final childState = _childKey.currentState;
    if (childState != null) {
      await childState.changeDatasource(_episode.id, _videoUrl,
          _videoSubtitleUrls, _videoTitle, _episodeTitle);
    } else {
      print("child state is null when callChildMethod2ChangePlayerDatasource");
    }
  }

  Future setVideoUrl() async {
    if (Platform.isWindows || Platform.isLinux) {
      _dartVlcPlayer.open(
        DartVlc.Media.network(_videoUrl),
        autoStart: true, // default
      );
      return;
    }
    try {
      print("update video url: $_videoUrl");
      await callChildMethod2ChangePlayerDatasource();
    } catch (error) {
      Fluttertoast.showToast(
          msg: "Video play exception: $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      print("播放-异常: $error");
    }
  }

  Future _loadApiBaseUrl() async {
    if (_apiBaseUrl.isEmpty) {
      _apiBaseUrl = (await AuthApi().getAuthParams()).baseUrl;
    }
  }

  Future _initVideoList() async {
    if (_videoList.isNotEmpty) {
      return;
    }

    await _loadApiBaseUrl();

    String episodeTitle =
        "${_episode.sequence}: ${(_episode.nameCn != null && _episode.nameCn != '') ? _episode.nameCn! : _episode.name}";
    if (_episode.resources!.isNotEmpty) {
      List<Video> videos = [];
      for (int i = 0; i < _episode.resources!.length; i++) {
        EpisodeResource resource = _episode.resources![i];
        String resourceName = resource.name;
        String url = _apiBaseUrl + resource.url;
        List<VideoSubtitle> videoSubtitles = await AttachmentRelationApi()
            .findByAttachmentId(resource.attachmentId);
        List<String> subtitleUrls = [];
        for (var element in videoSubtitles) {
          var subUrl = _apiBaseUrl + element.url;
          subtitleUrls.add(subUrl);
        }

        Video video = Video(
            episodeId: _episode.id,
            subjectId: _episode.subjectId,
            url: url,
            title: episodeTitle,
            subhead: resourceName,
            subtitleUrls: subtitleUrls);
        videos.add(video);
      }

      if (mounted) {
        setState(() {
          _videoList.addAll(videos);
        });
      }
    }
    return;
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
    _episodeTitle = episodeResource.name;
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
          subUrl = _apiBaseUrl + episodeResource.url;
        }
        subtitleUrls.add(subUrl);
      }
      setState(() {
        _videoSubtitleUrls = subtitleUrls;
      });
      print("video subtitle urls: $_videoSubtitleUrls");
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
    return ListView(
      children: items,
    );
  }
}
