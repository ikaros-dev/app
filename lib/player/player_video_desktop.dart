import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ikaros/api/collection/EpisodeCollectionApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:win32/win32.dart';

/// basic on dart_vlc.
class DesktopVideoPlayer extends StatefulWidget {
  Function? onFullScreenChange;

  DesktopVideoPlayer({super.key, this.onFullScreenChange});

  @override
  State<StatefulWidget> createState() {
    return DesktopVideoPlayerState();
  }
}

class DesktopVideoPlayerState extends State<DesktopVideoPlayer>
    with SingleTickerProviderStateMixin {
  late Player _player;
  late AnimationController playPauseController;
  late StreamSubscription<PlaybackState> playPauseStream;
  bool _displayTapped = false;
  bool _isFullScreen = false; // 全屏控制
  Timer? _hideTimer;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0, 3.0];
  late String _title = "主标题剧集信息";
  late String _subTitle = "副标题加载的附件名称";
  late int _episodeId = -1;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late Episode _episode;
  late Subject _subject;

  @override
  void initState() {
    super.initState();

    WidgetsFlutterBinding.ensureInitialized();

    DartVLC.initialize();
    _player = Player(id: hashCode);

    playPauseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    playPauseStream = _player.playbackStream
        .listen((event) => setPlaybackMode(event.isPlaying));
    if (_player.playback.isPlaying) playPauseController.forward();
    _player.bufferingProgressStream.listen((buffer) {
      if (buffer > 0) {
        isLoading.value = false;
      }
    });

    _player.positionStream.listen((data) {
      _position = data.position ?? Duration.zero;
      _duration = data.duration ?? Duration.zero;
      setState(() {});
    });

    _player.playbackStream.listen((data) {
      if (data.isCompleted) {
        EpisodeCollectionApi().updateCollectionFinish(_episodeId, true);
      }
    });
  }

  @override
  void dispose() {
    if (_episodeId > 0) {
      EpisodeCollectionApi().updateCollection(_episodeId, _position, _duration);
      print("保存剧集进度成功");
    }
    playPauseStream.cancel();
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

  void setPlaybackMode(bool isPlaying) {
    if (isPlaying) {
      playPauseController.forward();
    } else {
      playPauseController.reverse();
    }
    setState(() {});
  }

  void open(String url, {autoStart: false}) {
    isLoading.value = true;
    _player.open(
      Media.network(url),
      autoStart: autoStart,
    );
  }

  void addSlave(MediaSlaveType type, String url, bool select) {
    _player.addSlave(type, url, select);
  }

  void seek(Duration dest) {
    isLoading.value = true;
    _player.seek(dest);
  }

  void _updateFullScreen() async {
    setState(() {
      _isFullScreen = !_isFullScreen;
      widget.onFullScreenChange?.call();
    });
    if (Platform.isWindows) {
      if (_isFullScreen) {
        _enterImmersiveFullscreen();
      } else {
        _exitImmersiveFullscreen();
      }
    } else {
      DesktopWindow.setFullScreen(_isFullScreen);
    }
  }

  /// windows平台的全屏
  void _enterImmersiveFullscreen() {
    if (!Platform.isWindows) return;
    final hWnd = GetForegroundWindow();
    final style = GetWindowLongPtr(hWnd, GWL_STYLE);
    final exStyle = GetWindowLongPtr(hWnd, GWL_EXSTYLE);

    // 隐藏标题栏和任务栏
    SetWindowLongPtr(hWnd, GWL_STYLE, style & ~WS_OVERLAPPEDWINDOW);
    SetWindowLongPtr(hWnd, GWL_EXSTYLE, exStyle | WS_EX_TOPMOST);

    // 设置窗口位置和大小，覆盖整个屏幕
    SetWindowPos(
      hWnd,
      NULL,
      0,
      0,
      GetSystemMetrics(SM_CXSCREEN),
      GetSystemMetrics(SM_CYSCREEN),
      SWP_NOZORDER | SWP_FRAMECHANGED,
    );
  }

  /// windows平台的退出全屏
  void _exitImmersiveFullscreen() {
    if (!Platform.isWindows) return;
    final hWnd = GetForegroundWindow();
    final style = GetWindowLongPtr(hWnd, GWL_STYLE);
    final exStyle = GetWindowLongPtr(hWnd, GWL_EXSTYLE);

    // 还原标题栏和任务栏
    SetWindowLongPtr(hWnd, GWL_STYLE, style | WS_OVERLAPPEDWINDOW);
    SetWindowLongPtr(hWnd, GWL_EXSTYLE, exStyle & ~WS_EX_TOPMOST);

    // 还原窗口位置和大小
    SetWindowPos(
      hWnd,
      NULL,
      0,
      0,
      GetSystemMetrics(SM_CXSCREEN) * 3 ~/ 4,
      GetSystemMetrics(SM_CYSCREEN) * 3 ~/ 4,
      SWP_NOZORDER | SWP_FRAMECHANGED,
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();

    if (mounted) {
      _startHideTimer();

      setState(() {
        _displayTapped = true;
      });
    }
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _displayTapped = false;
        });
      }
    });
  }

  List<String> _getTrackDesc(String trackDesc) {
    if (trackDesc == "" || !trackDesc.contains(":")) List.empty();
    return trackDesc.split(":");
  }

  int? _getTrackDescId(String trackDesc) {
    List<String> trackProps = _getTrackDesc(trackDesc);
    if (trackProps.isEmpty) return null;
    return int.parse(trackProps[0]);
  }

  void _switchPlayerPauseOrPlay() {
    if (_player.playback.isPlaying) {
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
    _player.setRate(_playbackSpeed);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // 往后退10s
        seekPlus(false, const Duration(seconds: 10));
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // 往前进10s
        seekPlus(true, const Duration(seconds: 10));
      }
    }
  }

  void seekPlus(bool isPlus, Duration len) {
    int durationInMilliseconds = _player.position.duration?.inMilliseconds ?? 0;

    int positionInMilliseconds = _player.position.position?.inMilliseconds ?? 0;

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

  void _takeSnapshot() async {
    final ptr = calloc<Pointer<Utf16>>();
    final guid = calloc<GUID>()..ref.setGUID(FOLDERID_Pictures);
    final hr = SHGetKnownFolderPath(guid, KF_FLAG_DEFAULT, NULL, ptr);

    String path;
    if (hr == S_OK) {
      path = ptr.value.toDartString();
      calloc.free(ptr);
      calloc.free(guid);
    } else {
      calloc.free(ptr);
      calloc.free(guid);
      return;
    }

    Directory directory = Directory('$path/Ikaros');
    if (!directory.existsSync()) {
      directory.createSync();
      if (kDebugMode) {
        print("create ikaros snapshot dir: ${directory.path}");
      }
    }
    String fileName = '${_episodeId}_${_position.inMilliseconds}ms.png';
    File file = File('${directory.path}/$fileName');
    if (kDebugMode) {
      print("take snapshot to file: ${file.path}");
    }
    _player.takeSnapshot(
        file, _player.videoDimensions.width, _player.videoDimensions.height);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_player.playback.isPlaying) {
          if (_displayTapped) {
            setState(() {
              _displayTapped = false;
            });
          } else {
            _cancelAndRestartTimer();
          }
        }
      },
      child: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: _handleKeyEvent,
        autofocus: true,
        child: MouseRegion(
          onHover: (_) => _cancelAndRestartTimer(),
          child: Stack(
            children: [
              GestureDetector(
                onTap: _switchPlayerPauseOrPlay,
                onDoubleTap: _updateFullScreen,
                child: Video(
                  player: _player,
                  showControls: false,
                ),
              ),

              // 缓冲
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
                                onPressed: _takeSnapshot,
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
                        padding: const EdgeInsets.only(
                            bottom: 60, right: 20, left: 20),
                        child: StreamBuilder<PositionState>(
                          stream: _player.positionStream,
                          builder: (BuildContext context,
                              AsyncSnapshot<PositionState> snapshot) {
                            final durationState = snapshot.data;
                            final progress =
                                durationState?.position ?? Duration.zero;
                            final total =
                                durationState?.duration ?? Duration.zero;
                            return Theme(
                              data: ThemeData.dark(),
                              child: ProgressBar(
                                progress: progress,
                                total: total,
                                barHeight: 3,
                                thumbRadius: 10.0,
                                thumbGlowRadius: 30.0,
                                timeLabelLocation: TimeLabelLocation.sides,
                                timeLabelType: TimeLabelType.totalTime,
                                timeLabelTextStyle:
                                    const TextStyle(color: Colors.white),
                                onSeek: (duration) {
                                  seek(duration);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    StreamBuilder<CurrentState>(
                      stream: _player.currentStream,
                      builder: (context, snapshot) {
                        return Positioned(
                            left: 0,
                            right: 0,
                            bottom: 10,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if ((snapshot.data?.medias.length ?? 0) > 1)
                                  IconButton(
                                    color: Colors.white,
                                    iconSize: 30,
                                    icon: const Icon(Icons.skip_previous),
                                    onPressed: () => _player.previous(),
                                  ),
                                const SizedBox(width: 50),
                                IconButton(
                                    color: Colors.white,
                                    iconSize: 30,
                                    icon: const Icon(Icons.replay_10),
                                    onPressed: () {
                                      seekPlus(
                                          false, const Duration(seconds: 10));
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
                                IconButton(
                                    color: Colors.white,
                                    iconSize: 30,
                                    icon: const Icon(Icons.forward_10),
                                    onPressed: () {
                                      seekPlus(
                                          true, const Duration(seconds: 10));
                                    }),
                                const SizedBox(
                                  width: 20,
                                ),
                                if ((snapshot.data?.medias.length ?? 0) > 1)
                                  IconButton(
                                    color: Colors.white,
                                    iconSize: 30,
                                    icon: const Icon(Icons.skip_next),
                                    onPressed: () => _player.next(),
                                  ),
                              ],
                            ));
                      },
                    ),

                    Positioned(
                      right: 15,
                      bottom: 12.5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 倍速按钮
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

                          /// 音量控制
                          VolumeControl(
                            player: _player,
                            thumbColor: Colors.lightGreen,
                            inactiveColor: Colors.grey,
                            activeColor: Colors.blue,
                            backgroundColor: const Color(0xff424242),
                          ),

                          /// 音频轨道按钮
                          if (_player.audioTrackCount > 1)
                            PopupMenuButton(
                              iconSize: 24,
                              tooltip: "音频轨道",
                              icon: const Icon(Icons.audiotrack,
                                  color: Colors.white),
                              onSelected: (String trackDesc) {
                                int? id = _getTrackDescId(trackDesc);
                                if (id == null) return;
                                _player.setAudioTrack(id);
                              },
                              itemBuilder: (context) {
                                final audioTrack = _player.audioTrack();
                                return _player
                                    .audioTrackDescription()
                                    .where((track) => !track.startsWith("-1"))
                                    .map(
                                      (track) => PopupMenuItem(
                                        value: track,
                                        child: Text(track,
                                            style: TextStyle(
                                                fontSize: 14.0,
                                                color: audioTrack ==
                                                        _getTrackDescId(track)
                                                    ? Colors.lightBlueAccent
                                                    : Colors.black)),
                                      ),
                                    )
                                    .toList();
                              },
                            ),

                          // 字幕轨道按钮
                          if (_player.spuCount() > 0)
                            PopupMenuButton(
                              iconSize: 24,
                              tooltip: "字幕轨道",
                              icon: Icon(Icons.subtitles, color: Colors.white),
                              onSelected: (String trackDesc) {
                                if (trackDesc == "" || !trackDesc.contains(":"))
                                  return;
                                var trackProps = trackDesc.split(":");
                                var trackId = int.parse(trackProps[0]);
                                _player.setSpu(trackId);
                              },
                              itemBuilder: (context) {
                                final spu = _player.spu();
                                return _player
                                    .spuTrackDescription()
                                    .map(
                                      (track) => PopupMenuItem(
                                        value: track,
                                        child: Text(track,
                                            style: TextStyle(
                                                fontSize: 14.0,
                                                color: track.startsWith(
                                                        spu.toString())
                                                    ? Colors.lightBlueAccent
                                                    : Colors.black)),
                                      ),
                                    )
                                    .toList();
                              },
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
              //           onPressed: () {}, // 动态设置资源地址
              //           child: const Text("Load Video"),
              //         )
              //       ],
              //     )
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class VolumeControl extends StatefulWidget {
  final Player player;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final Color? thumbColor;

  const VolumeControl({
    required this.player,
    required this.activeColor,
    required this.inactiveColor,
    required this.backgroundColor,
    required this.thumbColor,
    Key? key,
  }) : super(key: key);

  @override
  VolumeControlState createState() => VolumeControlState();
}

class VolumeControlState extends State<VolumeControl> {
  double volume = 0.5;
  bool _showVolume = false;
  double unmutedVolume = 0.5;

  Player get player => widget.player;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _showVolume ? 1 : 0,
          child: AbsorbPointer(
            absorbing: !_showVolume,
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _showVolume = true);
              },
              onExit: (_) {
                setState(() => _showVolume = false);
              },
              child: Container(
                width: 60,
                height: 250,
                child: Card(
                  color: widget.backgroundColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: widget.activeColor,
                        inactiveTrackColor: widget.inactiveColor,
                        thumbColor: widget.thumbColor,
                      ),
                      child: Slider(
                        min: 0.0,
                        max: 1.0,
                        value: player.general.volume,
                        onChanged: (volume) {
                          player.setVolume(volume);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        MouseRegion(
          onEnter: (_) {
            setState(() => _showVolume = true);
          },
          onExit: (_) {
            setState(() => _showVolume = false);
          },
          child: IconButton(
            color: Colors.white,
            onPressed: () => muteUnmute(),
            icon: Icon(getIcon()),
          ),
        ),
      ],
    );
  }

  IconData getIcon() {
    if (player.general.volume > .5) {
      return Icons.volume_up_sharp;
    } else if (player.general.volume > 0) {
      return Icons.volume_down_sharp;
    } else {
      return Icons.volume_off_sharp;
    }
  }

  void muteUnmute() {
    if (player.general.volume > 0) {
      unmutedVolume = player.general.volume;
      player.setVolume(0);
    } else {
      player.setVolume(unmutedVolume);
    }
    setState(() {});
  }
}

// void main() {
//   runApp(const MaterialApp(
//     home: DesktopVideoPlayer(),
//   ));
// }
