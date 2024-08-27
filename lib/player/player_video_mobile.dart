import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:getwidget/components/toast/gf_toast.dart';
import 'package:getwidget/position/gf_toast_position.dart';
import 'package:ikaros/api/collection/EpisodeCollectionApi.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

/// basic on flutter_vlc_player.
class MobileVideoPlayer extends StatefulWidget {
  Function? onFullScreenChange;

  MobileVideoPlayer({super.key, this.onFullScreenChange});

  @override
  State<StatefulWidget> createState() {
    return MobileVideoPlayerState();
  }
}

class MobileVideoPlayerState extends State<MobileVideoPlayer>
    with SingleTickerProviderStateMixin {
  late VlcPlayerController _player;
  bool _isPlaying = false;
  bool _displayTapped = true;
  bool _isFullScreen = false; // 全屏控制
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late String _title = "主标题剧集信息";
  late String _subTitle = "副标题加载的附件名称";
  late int _episodeId = -1;
  late AnimationController playPauseController;
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0, 3.0];

  void listener() {
    if (!mounted) return;

    if (_player.value.isInitialized) {
      _position = _player.value.position;
      _duration = _player.value.duration;
    }

    if (_player.value.isPlaying) {
      _isPlaying = true;
      playPauseController.forward();
    } else {
      _isPlaying = false;
      playPauseController.reverse();
    }

    if (_player.value.isBuffering) {
      if (!isLoading.value) {
        isLoading.value = true;
      }
    } else {
      if (_player.value.isPlaying && isLoading.value) {
        isLoading.value = false;
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _player = VlcPlayerController.network(
      '', // 初始时不设置视频源
      autoPlay: false,
      hwAcc: HwAcc.full,
    );
    _player.addListener(listener);
    playPauseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    if (_episodeId > 0) {
      EpisodeCollectionApi().updateCollection(
          _episodeId, _player.value.position, _player.value.duration);
      print("保存剧集进度成功");
    }

    playPauseController.dispose();
    _player.dispose();
    super.dispose();
  }

  void setTitle(String title) {
    _title = title;
    setState(() {});
  }

  void setSubTitle(String subTitle) {
    _subTitle = subTitle;
    setState(() {});
  }

  void setEpisodeId(int episodeId) {
    _episodeId = episodeId;
    setState(() {});
  }

  void open(String url, {autoPlay = false}) async {
    print("open for autPlay=$autoPlay and url=$url");
    print("player.isReadyToInitialize=${_player.isReadyToInitialize}");
    setState(() {
      isLoading.value = true;
    });
    await _player.setMediaFromNetwork(url, autoPlay: autoPlay); // 设置视频源
    _isPlaying = true;
    setState(() {});
  }

  void addSlave(String url, bool select) {
    _player.addSubtitleFromNetwork(url, isSelected: select);
  }

  void _toggleDisplayTap() {
    print("_toggleDisplayTap");
    _displayTapped = !_displayTapped;
    setState(() {});
  }

  void _updateFullScreen() async {
    setState(() {
      _isFullScreen = !_isFullScreen;
      widget.onFullScreenChange?.call();
    });
    if (_isFullScreen) {
      _forceLandscape();
    } else {
      _forcePortrait();
    }
  }

  /// 全屏
  Future<void> _forceLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// 退出全屏
  Future<void> _forcePortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values); // to re-show bars
  }

  void _takeSnapshot() async {
    var status = await Permission.storage.status;

    if (status.isDenied) {
      // 如果权限被拒绝，直接请求权限
      status = await Permission.storage.request();
    }

    if (status.isPermanentlyDenied) {
      // 如果权限被永久拒绝，提示用户去设置手动开启
      openAppSettings();
    }

    print(status);

    if (status.isGranted) {
      try {
        // 捕获视频截图
        Uint8List pngBytes = await _player.takeSnapshot();

        // 保存到相册
        final result = await ImageGallerySaver.saveImage(pngBytes);
        print(result);
        GFToast.showToast("截图已保存到相册", context,
            toastPosition: GFToastPosition.CENTER);
      } catch (e) {
        print(e);
      }
    } else {
      GFToast.showToast("存储权限被拒绝", context,
          toastPosition: GFToastPosition.CENTER);
    }
  }

  void seek(Duration dest) {
    isLoading.value = true;
    setState(() {});
    _player.seekTo(dest);
  }

  void seekPlus(bool isPlus, Duration len) {
    int durationInMilliseconds = _duration.inMilliseconds;

    int positionInMilliseconds = _position.inMilliseconds;

    if (isPlus) {
      if ((positionInMilliseconds + len.inMilliseconds) <=
          durationInMilliseconds) {
        positionInMilliseconds += len.inMilliseconds;
      }
    } else {
      if (!(positionInMilliseconds - len.inMilliseconds).isNegative) {
        positionInMilliseconds -= len.inMilliseconds;
      }
    }

    seek(Duration(milliseconds: positionInMilliseconds));
    setState(() {});
  }

  void _switchPlayerPauseOrPlay() {
    if (_isPlaying) {
      _player.pause();
      playPauseController.reverse();
    } else {
      _player.play();
      playPauseController.forward();
    }
  }

  void _updateSpeed() {
    setState(() {
      int currentIndex = _speedOptions.indexOf(_playbackSpeed);
      currentIndex = (currentIndex + 1) % _speedOptions.length;
      _playbackSpeed = _speedOptions[currentIndex];
    });
    _player.setPlaybackSpeed(_playbackSpeed);
  }

  Future<void> _getAudioTracks() async {
    if (!_player.value.isPlaying) return;

    final audioTracks = await _player.getAudioTracks();
    final int? audioTrack = await _player.getAudioTrack();
    if (audioTracks.isNotEmpty) {
      if (!mounted) return;
      final int? selectedAudioTrackId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('选择音频轨道'),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: audioTracks.length,
                itemBuilder: (context, index) {
                  final entry = audioTracks.entries.elementAt(index);
                  return ListTile(
                    selected: audioTrack != null && audioTrack == entry.key,
                    title: Text(entry.value.toString()),
                    onTap: () {
                      Navigator.pop(
                        context,
                        entry.key,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      if (selectedAudioTrackId != null &&
          selectedAudioTrackId >= 0 &&
          selectedAudioTrackId != audioTrack) {
        await _player.setAudioTrack(selectedAudioTrackId);
        print("set audio track with id:$selectedAudioTrackId");
        GFToast.showToast("已切换到音频轨道: $selectedAudioTrackId", context,
            toastPosition: GFToastPosition.CENTER);
      } else {
        if (selectedAudioTrackId == audioTrack) {
          GFToast.showToast("操作取消，请不要选择已选中的音频。", context,
              toastPosition: GFToastPosition.CENTER);
        }
      }
    }
  }

  Future<void> _getSubtitleTracks() async {
    if (!_player.value.isPlaying) return;

    final subtitleTracks = await _player.getSpuTracks();
    final int? spuTrack = await _player.getSpuTrack();

    if (subtitleTracks.isNotEmpty) {
      if (!mounted) return;
      final int? selectedSubId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('选择字幕轨道'),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: subtitleTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  final MapEntry<int, String>? entry =
                      index < subtitleTracks.length
                          ? subtitleTracks.entries.elementAt(index)
                          : null;
                  return ListTile(
                    selected:
                        spuTrack != null && spuTrack == (entry?.key ?? -1),
                    title: Text(
                      index < subtitleTracks.keys.length
                          ? entry?.value.toString() ?? 'Disable'
                          : 'Disable',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < subtitleTracks.keys.length
                            ? (entry?.key ?? -1)
                            : -1,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      if (selectedSubId != null &&
          selectedSubId > -2 &&
          selectedSubId != spuTrack) {
        await _player.setSpuTrack(selectedSubId);
        print("set spu track with id:$selectedSubId");
        GFToast.showToast("已切换到字幕轨道: $selectedSubId ,生效需要等下一句字幕。", context,
            toastPosition: GFToastPosition.CENTER);
      } else {
        if (selectedSubId == spuTrack) {
          GFToast.showToast("操作取消，请不要选择已选中的字幕轨道。", context,
              toastPosition: GFToastPosition.CENTER);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleDisplayTap,
            onDoubleTap: _switchPlayerPauseOrPlay,
            child: VlcPlayer(
              controller: _player,
              aspectRatio: 16 / 9,
              placeholder: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (context, loading, child) {
            return loading
                ? const Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "正在缓冲中...",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            decoration: TextDecoration.none),
                      )
                    ],
                  )) // 在视频正中心显示加载指示器
                : const SizedBox.shrink();
          },
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _displayTapped ? 1.0 : 0.0,
          child: Stack(
            children: [
              // 上方中间的标题文本
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(_title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              decoration: TextDecoration.none)),
                      Text(_subTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              decoration: TextDecoration.none)),
                    ],
                  )
                ],
              ),

              // 右边的截图按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          color: Colors.white,
                          iconSize: 30,
                          icon: const Icon(Icons.photo_camera),
                          onPressed: (_takeSnapshot),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              /// 底部的控制UI
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.only(bottom: 60, right: 20, left: 20),
                  child: Theme(
                    data: ThemeData.dark(),
                    child: ProgressBar(
                      progress: _position,
                      total: _duration,
                      barHeight: 3,
                      thumbRadius: 10.0,
                      thumbGlowRadius: 30.0,
                      timeLabelLocation: TimeLabelLocation.sides,
                      timeLabelType: TimeLabelType.totalTime,
                      timeLabelTextStyle: const TextStyle(color: Colors.white),
                      onSeek: (duration) {
                        seek(duration);
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 20),
                      if (_isFullScreen)
                        IconButton(
                            color: Colors.white,
                            iconSize: 30,
                            icon: const Icon(Icons.replay_10),
                            onPressed: () {
                              seekPlus(false, const Duration(seconds: 10));
                            }),
                      const SizedBox(
                        width: 20,
                      ),

                      /// 播放暂停按钮
                      IconButton(
                        color: Colors.white,
                        iconSize: 30,
                        icon: AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: playPauseController),
                        onPressed: _switchPlayerPauseOrPlay,
                      ),
                      const SizedBox(width: 20),
                      if (_isFullScreen)
                        IconButton(
                            color: Colors.white,
                            iconSize: 30,
                            icon: const Icon(Icons.forward_10),
                            onPressed: () {
                              seekPlus(true, const Duration(seconds: 10));
                            }),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  )),

              Positioned(
                right: 15,
                bottom: 12.5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 倍速按钮
                    if (_isFullScreen)
                      IconButton(
                        iconSize: 24,
                        color: Colors.white,
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.speed),
                            const SizedBox(
                              width: 4,
                            ),
                            Text(
                              'x$_playbackSpeed',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        onPressed: _updateSpeed,
                        tooltip: "更改倍速",
                      ),

                    /// 音频轨道按钮
                    if (_player.value.audioTracksCount > 1)
                      IconButton(
                        tooltip: '音频轨道',
                        icon: const Icon(Icons.audiotrack),
                        color: Colors.white,
                        onPressed: _getAudioTracks,
                      ),

                    // 字幕轨道按钮
                    if (_player.value.spuTracksCount > 0)
                      IconButton(
                        tooltip: '字幕轨道',
                        icon: const Icon(Icons.subtitles),
                        color: Colors.white,
                        onPressed: _getSubtitleTracks,
                      ),

                    // 全屏控制按钮
                    IconButton(
                      iconSize: 24,
                      icon: Icon(
                          _isFullScreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          color: Colors.white),
                      onPressed: _updateFullScreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.start,
        //   children: [
        //     Column(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         ElevatedButton(
        //           onPressed: () {
        //           }, // 动态设置资源地址
        //           child: const Text("Load Video"),
        //         ),
        //         ElevatedButton(
        //           onPressed: _toggleDisplayTap,
        //           child: const Text("tap"),
        //         ),
        //       ],
        //     )
        //   ],
        // ),
      ],
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     home: MobileVideoPlayer(),
//   ));
// }
