import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ikaros/video/other/temp_value.dart';
import 'package:ikaros/video/utils/video_player_utils.dart';
import 'package:ikaros/video/widget/video_player_bottom.dart';
import 'package:ikaros/video/widget/video_player_center.dart';
import 'package:ikaros/video/widget/video_player_gestures.dart';
import 'package:ikaros/video/widget/video_player_top.dart';
import 'package:ikaros/api/subject/model/Subject.dart';

import '../../api/auth/AuthApi.dart';
import '../../api/auth/AuthParams.dart';
import '../../api/subject/model/Episode.dart';
import '../../api/subject/model/EpisodeResource.dart';

class VideoPlayerPage extends StatefulWidget {
  final Subject subject;
  const VideoPlayerPage({Key? key, required this.subject}) : super(key: key);
  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  // 是否全屏
  bool get _isFullScreen => MediaQuery.of(context).orientation == Orientation.landscape;
  Size get _window => MediaQueryData.fromWindow(window).size;
  double get _width => _isFullScreen ? _window.width : _window.width;
  double get _height => _isFullScreen ? _window.height : _window.width*9/16;
  Widget? _playerUI;
  VideoPlayerTop? _top;
  VideoPlayerBottom? _bottom;
  LockIcon? _lockIcon; // 控制是否沉浸式的widget


  late String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    _getFirstEpisodeResource()
    .then((firstEpisodeResource) => {
      VideoPlayerUtils.playerHandle(firstEpisodeResource.url,autoPlay: false),
          VideoPlayerUtils.initializedListener(key: this, listener: (initialize,widget){
            if(initialize){
              _top ??= VideoPlayerTop(title: firstEpisodeResource.name);
              _lockIcon ??= LockIcon(lockCallback: (){
                _top!.opacityCallback(!TempValue.isLocked);
                _bottom!.opacityCallback(!TempValue.isLocked);
              },);
              _bottom ??= VideoPlayerBottom();
              _playerUI = widget;
              if(!mounted) return;
              setState(() {});
            }
          })
    });

  }

  @override
  void dispose() {
    // TODO: implement dispose
    VideoPlayerUtils.removeInitializedListener(this);
    VideoPlayerUtils.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen ? null : AppBar(title: Text(
          (widget.subject.nameCn != null && widget.subject.nameCn != '')
              ? widget.subject.nameCn!
              : widget.subject.name
      ),),
      body: _isFullScreen ? safeAreaPlayerUI() : Column(
        children: [
          safeAreaPlayerUI(),
          // const SizedBox(height: 100,),
          // InkWell(
          //   // 切换视频
          //   onTap: () => _changeVideo(),
          //   child: Container(
          //     alignment: Alignment.center,
          //     width: 120, height: 60,
          //     color: Colors.orangeAccent,
          //     child: const Text("切换视频",style: TextStyle(fontSize: 18),),
          //   ),
          // )
        ],
      )
    );
  }

  Widget safeAreaPlayerUI(){
    return SafeArea( // 全屏的安全区域
      top: !_isFullScreen,
      bottom: !_isFullScreen,
      left: !_isFullScreen,
      right: !_isFullScreen,
      child: SizedBox(
        height: _height,
        width: _width,
        child: _playerUI != null ? VideoPlayerGestures(
          appearCallback: (appear){
            _top!.opacityCallback(appear);
            _lockIcon!.opacityCallback(appear);
            _bottom!.opacityCallback(appear);
            },
          children: [
            Center(
              child: _playerUI,
            ),
            _top!,
            _lockIcon!,
            _bottom!
          ],
        ) : Container(
          alignment: Alignment.center,
          color: Colors.black26,
          child: const CircularProgressIndicator(
            strokeWidth: 3,
          ),
        )
      ),
    );
  }

  Future<String> getBaseUrl() async {
    if (_baseUrl == '') {
      AuthParams authParams = await AuthApi().getAuthParams();
      _baseUrl = authParams.baseUrl;
    }
    return _baseUrl;
  }

  Future<Episode> _getFirstEpisode() async {
    return Future(() => Stream.fromIterable(widget.subject.episodes!)
        .where((e) => 1.0 == e.sequence)
        .first);
  }

  Future<EpisodeResource> _getFirstEpisodeResource() async {
    Episode episode = await _getFirstEpisode();
    String baseUrl = await getBaseUrl();
    EpisodeResource episodeResource = episode.resources![0];
    episodeResource = EpisodeResource(
        fileId: episodeResource.fileId,
        episodeId: episodeResource.episodeId,
        url: baseUrl + episodeResource.url,
        // name: "${episode.sequence}: ${((episode.nameCn != null && episode.nameCn != '') ? episode.nameCn : episode.name)}"
      name: episodeResource.name
    );
    return episodeResource;
  }

  // void _changeVideo(){
  //   _playerUI = null;
  //   setState(() {});
  //   VideoPlayerUtils.playerHandle(_urls[_index]);
  //   _index += 1;
  //   if(_index == _urls.length){
  //     _index = 0;
  //   }
  // }
  // final List<String> _urls = [
  //   "http://nas:9999/files/2023/7/6/fa5e4ccd4e1d4d93866d073cbebfb9ff.mp4",
  // ];
  // int _index = 1;
}
