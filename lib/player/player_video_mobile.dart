import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:getwidget/components/toast/gf_toast.dart';
import 'package:getwidget/position/gf_toast_position.dart';
import 'package:ikaros/api/collection/EpisodeCollectionApi.dart';
import 'package:path_provider/path_provider.dart';
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
  List<String> _subtitleUrls = [];
  bool _progressIsLoaded = false;
  int _progress = 0;

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

    if (_player.value.isPlaying) {
      // print("isPlaying");
      // seek to  once
      if (!_progressIsLoaded && _progress > 0) {
        _player.seekTo(Duration(milliseconds: _progress));
        print("seek to $_progress");
        GFToast.showToast("已请求跳转到上次的进度: $_progress", context);
        setState(() {
          _progressIsLoaded = true;
        });
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

  void setSubtitleUrls(List<String> subtitles) {
    _subtitleUrls = subtitles;
  }

  void setProgress(int progress) {
    _progress = progress;
  }

  void open(String url, {autoPlay = false}) async {
    print("open for autPlay=$autoPlay and url=$url");
    print("player.isReadyToInitialize=${_player.isReadyToInitialize}");
    setState(() {
      isLoading.value = true;
    });
    await _player.setMediaFromNetwork(url, autoPlay: autoPlay); // 设置视频源
    _isPlaying = true;

    // load new subtitles
    if (_subtitleUrls != null && _subtitleUrls!.isNotEmpty) {
      for (int i = 0; i < _subtitleUrls!.length; i++) {
        print("add subtitle url to video, url: ${_subtitleUrls![i]}");
        await _player.addSubtitleFromNetwork(_subtitleUrls![i],
            isSelected: i == 0);
      }
    }

    setState(() {});
  }

  void addSlave(String url, bool select) {
    _player.addSubtitleFromNetwork(url, isSelected: select);
    print("add subtitle form network for url: $url");
    setState(() {});
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

        // 获取临时目录
        final directory = await getTemporaryDirectory();
        // 创建图片文件
        final imageFile = File('${directory.path}/temp_image.png');
        // 写入图片数据
        await imageFile.writeAsBytes(pngBytes);

        // 保存图片到相册
        // await GallerySaver.saveImage(imageFile.path).then((bool? success) {
        //   if (success == true) {
        //     GFToast.showToast("截图已保存到相册", context,
        //         toastPosition: GFToastPosition.CENTER);
        //   } else {
        //     GFToast.showToast("保存图片失败", context,
        //         toastPosition: GFToastPosition.CENTER);
        //   }
        // });
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleDisplayTap,
      onDoubleTap: _switchPlayerPauseOrPlay,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 上方中间的标题文本
          Visibility(
            visible: _displayTapped,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _displayTapped ? 1.0 : 0.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                          : Column(
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
                            );
                    },
                  )
                ],
              ),
            ),
          ),

          /// 中间的视频
          Expanded(
              child: VlcPlayer(
            controller: _player,
            aspectRatio: 16 / 9,
            placeholder: const Center(child: CircularProgressIndicator()),
          )),

          Visibility(
            visible: _displayTapped,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _displayTapped ? 1.0 : 0.0,
              child: Row(
                children: [
                  Expanded(
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
                  )),
                ],
              ),
            ),
          ),
          Visibility(
            visible: _displayTapped,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _displayTapped ? 1.0 : 0.0,
              child: Row(
                children: [
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

                  const SizedBox(width: 20),
                  // IconButton(
                  //   color: Colors.white,
                  //   iconSize: 24,
                  //   icon: const Icon(Icons.photo_camera),
                  //   onPressed: (_takeSnapshot),
                  // ),
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
          ),
        ],
      ),
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     home: MobileVideoPlayer(),
//   ));
// }
