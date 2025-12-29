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
import 'package:ikaros/api/dandanplay/DandanplayBangumiApi.dart';
import 'package:ikaros/api/dandanplay/DandanplayCommentApi.dart';
import 'package:ikaros/api/dandanplay/DandanplaySearchApi.dart';
import 'package:ikaros/api/dandanplay/model/BangumiEpisode.dart';
import 'package:ikaros/api/dandanplay/model/CommentEpisode.dart';
import 'package:ikaros/api/dandanplay/model/CommentEpisodeIdResponse.dart';
import 'package:ikaros/api/dandanplay/model/IkarosDanmukuBangumiResponse.dart';
import 'package:ikaros/api/dandanplay/model/IkarosDanmukuEpisodesResponse.dart';
import 'package:ikaros/api/dandanplay/model/SearchEpisodeDetails.dart';
import 'package:ikaros/api/dandanplay/model/SearchEpisodesAnime.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/SubjectSyncApi.dart';
import 'package:ikaros/api/subject/enums/SubjectSyncPlatform.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/api/subject/model/SubjectSync.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/shared_prefs_utils.dart';
import 'package:ns_danmaku/danmaku_controller.dart';
import 'package:ns_danmaku/danmaku_view.dart';
import 'package:ns_danmaku/models/danmaku_item.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:win32/win32.dart';

/// basic on dart_vlc.
class DesktopVideoPlayer extends StatefulWidget {
  Function? onFullScreenChange;
  Function? onPlayCompleted;
  Function(int count)? onDanmukuPoolInitialed;

  DesktopVideoPlayer(
      {super.key,
      this.onFullScreenChange,
      this.onPlayCompleted,
      this.onDanmukuPoolInitialed});

  @override
  State<StatefulWidget> createState() {
    return DesktopVideoPlayerState();
  }
}

int GET_X_LPARAM(int lParam) {
  return lParam & 0xFFFF; // 低 16 位是 x 坐标
}

int GET_Y_LPARAM(int lParam) {
  return (lParam >> 16) & 0xFFFF; // 高 16 位是 y 坐标
}

class DesktopVideoPlayerState extends State<DesktopVideoPlayer>
    with SingleTickerProviderStateMixin {
  late Player _player;
  late AnimationController playPauseController;
  late StreamSubscription<PlaybackState> playPauseStream;
  bool _displayTapped = false;
  bool _isFullScreen = false; // 全屏控制
  bool _isSmallScreen = false; // 小窗播放
  Timer? _hideTimer;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0, 3.0];
  late String _title = "主标题剧集信息";
  late String _subTitle = "副标题加载的附件名称";
  late int _episodeId = -1;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _lastPosition = Duration.zero;
  late Episode _episode;
  late Subject? _subject;
  late List<SubjectSync> _syncs = [];
  late DanmakuController _danmuku;
  final List<CommentEpisode> _commentEpisodes = [];
  final List<CommentEpisode> _commentRomovedEpisodes = [];
  late Lock lock = Lock();
  late DanmuConfig _danmuConfig = DanmuConfig();
  late bool _danmuConfigChange = false;

  // 视频小窗的宽和高
  static const defaultSmallWindowsDevicePixelWidth = 800;
  static const defaultSmallWindowsDevicePixelHeight = 400;
  var smallWindowDevicePixelWidth = defaultSmallWindowsDevicePixelWidth;
  var smallWindowDevicePixelHeight = defaultSmallWindowsDevicePixelHeight;
  late int _hwnd; // 存储窗口句柄
  double offsetX = 0.0;
  double offsetY = 0.0;
  double clickOffsetX = 0.0;
  double clickOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    WidgetsFlutterBinding.ensureInitialized();

    DartVLC.initialize();
    _player = Player(id: hashCode);

    playPauseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    playPauseStream = _player.playbackStream
        .listen((event) => setPlaybackMode(event.isPlaying));
    if (_player.playback.isPlaying) _play();
    _player.bufferingProgressStream.listen((buffer) {
      if (buffer > 0) {
        isLoading.value = false;
      }
    });

    _player.positionStream.listen((data) {
      _lastPosition = _position;
      _position = data.position ?? Duration.zero;
      _duration = data.duration ?? Duration.zero;
      setState(() {});
      _checkAndAddDanmuku(_lastPosition, _position);
    });

    _player.playbackStream.listen((data) {
      if (data.isCompleted) {
        EpisodeCollectionApi().updateCollectionFinish(_episodeId, true);
        if (widget.onPlayCompleted != null) {
          widget.onPlayCompleted?.call();
        }
      }
    });

    SharedPrefsUtils.getDanmuConfig().then((config) {
      _danmuConfig = config;
      if (mounted) _danmuku.updateOption(_danmuConfig.toOption());
    });

    _hwnd = GetForegroundWindow();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    if (_episodeId > 0) {
      EpisodeCollectionApi()
          .updateCollection(_episodeId, _position, _duration)
          .then((_) {
        debugPrint("保存剧集进度成功");
      });
    }
    _player.pause();
    playPauseStream.cancel();
    playPauseController.dispose();
    _player.dispose();

    if (mounted) {
      _danmuku.pause();
      _danmuku.clear();
    }

    super.dispose();
  }

  Future<void> _reloadDanmukuConfig() async {
    _danmuConfig = await SharedPrefsUtils.getDanmuConfig();
    _danmuku.updateOption(_danmuConfig.toOption());
    Toast.show(context, "更新弹幕样式成功");
    _danmuConfigChange = false;
    setState(() {});
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
    _initDanmukuPool();
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

  Future<void> _initDanmukuPool() async {
    _episode = await EpisodeApi().findById(_episodeId);
    if (_episode.id == -1 || _episode.group != "MAIN") {
      return; // 根据条目名和序号只支持查询正片弹幕
    }
    _subject = await SubjectApi().findById(_episode.subjectId);
    _syncs = await SubjectSyncApi().getSyncsBySubjectId(_episode.subjectId);
    if (_subject == null) {
      return; // 自己新建的无三方同步平台ID关联的条目是不会请求弹幕的
    }
    var targetEpisodeId = -1;
    if (_syncs.isNotEmpty &&
        _syncs.first.platform == SubjectSyncPlatform.BGM_TV) {
      var bgmtvSubjectId = _syncs.first.platformId;

      IkarosDanmukuBangumiResponse? bangumiRsp = await DandanplayBangumiApi()
          .getBangumiDetailsByBgmtvSubjectId(bgmtvSubjectId);
      if (bangumiRsp != null && bangumiRsp.data.episodes.isNotEmpty) {
        BangumiEpisode? targetEpisode = bangumiRsp.data.episodes
            .where((ep) => ep.episodeNumber == _episode.sequence.toInt().toString())
            .firstOrNull;
        targetEpisodeId = targetEpisode?.episodeId ?? -1;
      }
    }
    if (targetEpisodeId == -1) {
      IkarosDanmukuEpisodesResponse? searchEpsResp = await DandanplaySearchApi()
          .searchEpisodes(_subject!.name, _episode.sequence.toInt().toString());
      if (searchEpsResp == null || searchEpsResp.animes.isEmpty) return;
      SearchEpisodesAnime searchEpisodesAnime = searchEpsResp.animes.first;
      if (searchEpisodesAnime.episodes.isEmpty) return;
      SearchEpisodeDetails searchEpisodeDetails =
          searchEpisodesAnime.episodes.first;
      targetEpisodeId = searchEpisodeDetails.episodeId;
    }

    CommentEpisodeIdResponse? commentEpIdResp =
        await DandanplayCommentApi().commentEpisodeId(targetEpisodeId, 1);
    if (commentEpIdResp == null || commentEpIdResp.count == 0) return;
    _commentEpisodes.addAll(commentEpIdResp.comments);

    widget.onDanmukuPoolInitialed?.call(_commentEpisodes.length);
  }

  void _checkAndAddDanmuku(Duration lastPosition, Duration currentPosition) {
    for (CommentEpisode commentEp in List.from(_commentEpisodes)) {
      if (!commentEp.p.contains(',') || commentEp.p.split(',').length != 4) {
        continue;
      }
      String timeStr = commentEp.p.split(",")[0];
      double timeD = double.parse(timeStr);
      Duration time = Duration(seconds: timeD.toInt());
      if (lastPosition != Duration.zero &&
          lastPosition < currentPosition &&
          time < lastPosition) {
        lock.synchronized(() {
          _commentEpisodes.remove(commentEp);
          _commentRomovedEpisodes.add(commentEp);
        });
        continue;
      }
      if (time >= lastPosition - const Duration(milliseconds: 100) &&
          time <= currentPosition + const Duration(milliseconds: 100)) {
        lock.synchronized(() {
          _commentEpisodes.remove(commentEp);
          _commentRomovedEpisodes.add(commentEp);
        });
        _addDanmuku(commentEp);
      }
    }
  }

  void _addDanmuku(CommentEpisode commentEp) {
    if (!commentEp.p.contains(',') || commentEp.p.split(',').length != 4) {
      return;
    }
    String danmuMode = commentEp.p.split(',')[1];
    int danmuColor = int.parse(commentEp.p.split(',')[2]);
    int r = (danmuColor >> 16) & 0xFF; // 提取红色分量
    int g = (danmuColor >> 8) & 0xFF; // 提取绿色分量
    int b = danmuColor & 0xFF; // 提取蓝色分量
    Color color = Color.fromARGB(255, r, g, b);
    DanmakuItemType type = DanmakuItemType.scroll;
    if (danmuMode == "4") type = DanmakuItemType.bottom;
    if (danmuMode == "5") type = DanmakuItemType.top;
    DanmakuItem item = DanmakuItem(commentEp.m, type: type, color: color);
    List<DanmakuItem> items = [];
    items.add(item);
    _danmuku.addItems(items);
  }

  void open(String url, {autoStart = false}) {
    isLoading.value = true;
    _player.open(
      Media.network(url),
      autoStart: autoStart,
    );
  }

  void reload(String url, {autoStart = false}) {
    _player.stop();
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
    _lastPosition = Duration.zero;
    _player.seek(dest);
    _danmuku.pause();
    _danmuku.clear();
    lock.synchronized(() {
      _commentEpisodes.addAll(_commentRomovedEpisodes);
      _commentRomovedEpisodes.clear();
    });
    _danmuku.resume();
  }

  void _switchSmallScreen() async {
    if (!Platform.isWindows) return;

    setState(() {
      _isSmallScreen = !_isSmallScreen;
      _isFullScreen = !_isFullScreen;
    });
    widget.onFullScreenChange?.call();

    if (_isSmallScreen) {
      _danmuConfig.fontSize = 11;
      await SharedPrefsUtils.saveDanmuConfig(_danmuConfig);
      await _reloadDanmukuConfig();

      if (_player.playback.isPlaying) {
        smallWindowDevicePixelHeight =
            (smallWindowDevicePixelWidth * _player.videoDimensions.height) ~/
                _player.videoDimensions.width;
      } else {
        smallWindowDevicePixelWidth = defaultSmallWindowsDevicePixelWidth;
        smallWindowDevicePixelHeight = defaultSmallWindowsDevicePixelHeight;
      }

      _enterSmallScreen();
    } else {
      _exitImmersiveFullscreen();

      _danmuConfig.fontSize = 21;
      await SharedPrefsUtils.saveDanmuConfig(_danmuConfig);
      await _reloadDanmukuConfig();
    }
  }

  void _enterSmallScreen() async {
    if (!Platform.isWindows) return;

    final hWnd = GetForegroundWindow();
    final style = GetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE);
    final exStyle = GetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_EXSTYLE);

    // 隐藏标题栏和任务栏
    SetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE,
        style & ~WINDOW_STYLE.WS_OVERLAPPEDWINDOW);
    SetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_EXSTYLE,
        exStyle | WINDOW_EX_STYLE.WS_EX_TOPMOST);

    // 获取屏幕尺寸
    final screenWidth =
        GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CXSCREEN); // 屏幕宽度
    final screenHeight =
        GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CYSCREEN); // 屏幕高度

    // 计算窗口右下角的位置
    final x = screenWidth - smallWindowDevicePixelWidth;
    final y = screenHeight - smallWindowDevicePixelHeight - 120;

    // 使用 SetWindowPos 将窗口缩小到右下角并置顶
    SetWindowPos(
      hWnd,
      // 窗口句柄
      HWND_TOPMOST,
      // 窗口置顶
      x,
      // 计算的右下角 x 坐标
      y,
      // 计算的右下角 y 坐标
      smallWindowDevicePixelWidth,
      // 指定的窗口宽度
      smallWindowDevicePixelHeight,
      // 指定的窗口高度
      SET_WINDOW_POS_FLAGS.SWP_NOACTIVATE |
          SET_WINDOW_POS_FLAGS.SWP_SHOWWINDOW, // 不激活窗口，显示窗口
    );
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
    final style = GetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE);
    final exStyle = GetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_EXSTYLE);

    // 隐藏标题栏和任务栏
    SetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE,
        style & ~WINDOW_STYLE.WS_OVERLAPPEDWINDOW);
    SetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_EXSTYLE,
        exStyle | WINDOW_EX_STYLE.WS_EX_TOPMOST);

    // 设置窗口位置和大小，覆盖整个屏幕
    SetWindowPos(
      hWnd,
      NULL,
      0,
      0,
      GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CXSCREEN),
      GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CYSCREEN),
      SET_WINDOW_POS_FLAGS.SWP_NOZORDER | SET_WINDOW_POS_FLAGS.SWP_FRAMECHANGED,
    );
  }

  /// windows平台的退出全屏
  void _exitImmersiveFullscreen() {
    if (!Platform.isWindows) return;
    final hWnd = GetForegroundWindow();
    final style = GetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE);
    final exStyle = GetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_EXSTYLE);

    // 还原标题栏和任务栏
    SetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_STYLE,
        style | WINDOW_STYLE.WS_OVERLAPPEDWINDOW);
    SetWindowLongPtr(hWnd, WINDOW_LONG_PTR_INDEX.GWL_EXSTYLE,
        exStyle & ~WINDOW_EX_STYLE.WS_EX_TOPMOST);

    // 还原窗口位置和大小
    SetWindowPos(
      hWnd,
      HWND_NOTOPMOST,
      0,
      0,
      GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CXSCREEN) * 3 ~/ 4,
      GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CYSCREEN) * 3 ~/ 4,
      SET_WINDOW_POS_FLAGS.SWP_NOZORDER | SET_WINDOW_POS_FLAGS.SWP_FRAMECHANGED,
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

  void _play() {
    _player.play();
    playPauseController.forward();
    if (!_danmuku.running) _danmuku.resume();
  }

  void _pause() {
    _player.pause();
    playPauseController.reverse();
    if (_danmuku.running) _danmuku.pause();
  }

  void _switchPlayerPauseOrPlay() {
    if (_player.playback.isPlaying) {
      _pause();
    } else {
      _play();
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
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        // 切换播放或暂停
        _switchPlayerPauseOrPlay();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        // 如果处于全屏，则退出全屏，否则返回上一级路由
        if (_isFullScreen) {
          _updateFullScreen();
        } else {
          Navigator.of(context).pop();
        }
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

  void _takeSnapshotOnWindows() async {
    if (!Platform.isWindows) return;
    final ptr = calloc<Pointer<Utf16>>();
    final guid = calloc<GUID>()..ref.setGUID(FOLDERID_Pictures);
    final hr = SHGetKnownFolderPath(
        guid, KNOWN_FOLDER_FLAG.KF_FLAG_DEFAULT, NULL, ptr);

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
    String fileName =
        '${_subject?.id}_${_episodeId}_${_position.inMilliseconds}ms.png';
    File file = File('${directory.path}/$fileName');
    if (kDebugMode) {
      print("take snapshot to file: ${file.path}");
    }
    _player.takeSnapshot(
        file, _player.videoDimensions.width, _player.videoDimensions.height);
  }

  Future<void> _openSettingsPanel() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height:
              MediaQuery.of(context).size.height * (_isFullScreen ? 0.5 : 0.8),
          width: MediaQuery.of(context).size.width * 0.8,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Text('弹幕字体大小'),
                const SizedBox(
                  height: 10,
                ),
                SegmentedButton<double>(
                  selected: <double>{_danmuConfig.fontSize},
                  segments: const [
                    ButtonSegment(value: 11.0, label: Text("小")),
                    ButtonSegment(value: 16.0, label: Text("中")),
                    ButtonSegment(value: 21.0, label: Text("大")),
                    ButtonSegment(value: 26.0, label: Text("特大")),
                    ButtonSegment(value: 31.0, label: Text("超级大")),
                  ],
                  onSelectionChanged: (Set<double> newSelection) {
                    if (_danmuConfig.fontSize != newSelection.first) {
                      _danmuConfig.fontSize = newSelection.first;
                      _danmuConfigChange = true;
                    }
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text('弹幕显示区域'),
                const SizedBox(height: 10),
                SegmentedButton<double>(
                  selected: <double>{_danmuConfig.area},
                  segments: const [
                    ButtonSegment(value: 0.25, label: Text("小屏")),
                    ButtonSegment(value: 0.5, label: Text("半屏")),
                    ButtonSegment(value: 0.75, label: Text("大屏")),
                    ButtonSegment(value: 1.0, label: Text("全屏")),
                  ],
                  onSelectionChanged: (Set<double> newSelection) {
                    if (_danmuConfig.area != newSelection.first) {
                      _danmuConfig.area = newSelection.first;
                      _danmuConfigChange = true;
                    }
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text('弹幕透明度'),
                const SizedBox(height: 10),
                SegmentedButton<double>(
                  selected: <double>{_danmuConfig.opacity},
                  segments: const [
                    ButtonSegment(value: 0.25, label: Text("0.25")),
                    ButtonSegment(value: 0.5, label: Text("0.5")),
                    ButtonSegment(value: 0.75, label: Text("0.75")),
                    ButtonSegment(value: 1.0, label: Text("1.0")),
                  ],
                  onSelectionChanged: (Set<double> newSelection) {
                    if (_danmuConfig.opacity != newSelection.first) {
                      _danmuConfig.opacity = newSelection.first;
                      _danmuConfigChange = true;
                    }
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const Text('隐藏顶部弹幕'),
                        const SizedBox(height: 10),
                        Switch(
                            value: _danmuConfig.hideTop,
                            onChanged: ((bool value) {
                              if (_danmuConfig.hideTop != value) {
                                _danmuConfig.hideTop = value;
                                _danmuConfigChange = true;
                              }
                              Navigator.of(context).pop();
                            })),
                      ],
                    ),
                    const SizedBox(width: 5),
                    Column(
                      children: [
                        const Text('隐藏底部弹幕'),
                        const SizedBox(height: 10),
                        Switch(
                            value: _danmuConfig.hideBottom,
                            onChanged: ((bool value) {
                              if (_danmuConfig.hideBottom != value) {
                                _danmuConfig.hideBottom = value;
                                _danmuConfigChange = true;
                              }
                              Navigator.of(context).pop();
                            })),
                      ],
                    ),
                    const SizedBox(width: 5),
                    Column(
                      children: [
                        const Text('隐藏滚动弹幕'),
                        const SizedBox(height: 10),
                        Switch(
                            value: _danmuConfig.hideScroll,
                            onChanged: ((bool value) {
                              if (_danmuConfig.hideScroll != value) {
                                _danmuConfig.hideScroll = value;
                                _danmuConfigChange = true;
                              }
                              Navigator.of(context).pop();
                            })),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (_danmuConfigChange) {
      await SharedPrefsUtils.saveDanmuConfig(_danmuConfig);
      Toast.show(context, "保存新的弹幕样式配置成功");
      await _reloadDanmukuConfig();
    }
  }

  double adjustForDevicePixelRatio(double value) {
    final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    return value / devicePixelRatio; // 将Win32的物理像素转为Flutter的逻辑像素
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        // 记录鼠标点击的相对位置（窗口内的偏移）
        clickOffsetX = details.localPosition.dx;
        clickOffsetY = details.localPosition.dy;
      },
      onPanUpdate: (details) {
        if (!_isSmallScreen) return;
        // 计算窗口新位置，使点击位置与鼠标位置对齐
        double dx = details.localPosition.dx - clickOffsetX;
        double dy = details.localPosition.dy - clickOffsetY;

        setState(() {
          offsetX += dx;
          offsetY += dy;
        });
        // debugPrint("onPanUpdate: offsetX:${offsetX.toInt()} offsetY:${offsetY.toInt()}");

        // 调整窗口位置
        SetWindowPos(
            _hwnd,
            HWND_TOPMOST,
            offsetX.toInt() + smallWindowDevicePixelWidth,
            offsetY.toInt() + smallWindowDevicePixelHeight,
            smallWindowDevicePixelWidth,
            smallWindowDevicePixelHeight,
            SET_WINDOW_POS_FLAGS.SWP_NOZORDER |
                SET_WINDOW_POS_FLAGS.SWP_NOSIZE |
                SET_WINDOW_POS_FLAGS.SWP_NOREDRAW);
      },
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
          onHover: (event) {
            _cancelAndRestartTimer();
          },
          onExit: (event) {
            if (mounted) {
              setState(() {
                _displayTapped = false;
              });
            }
          },
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
                  child: MouseRegion(
                    cursor: _displayTapped
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.none,
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
                        // 上方左边的返回按钮
                        Positioned(
                          left: 15,
                          top: 12.5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                  onPressed: () {
                                    if (!_isSmallScreen && !_isFullScreen) {
                                      Navigator.of(context).pop();
                                      return;
                                    }

                                    if (_isSmallScreen) {
                                      _switchSmallScreen();
                                      return;
                                    }

                                    if (_isFullScreen) {
                                      _updateFullScreen();
                                      return;
                                    }
                                  },
                                  iconSize: 30,
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ))
                            ],
                          ),
                        ),

                        // 上方右边的设置按钮
                        if (!_isSmallScreen)
                          Positioned(
                            right: 15,
                            top: 12.5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                    onPressed: _openSettingsPanel,
                                    iconSize: 30,
                                    icon: const Icon(
                                      Icons.settings,
                                      color: Colors.white,
                                    ))
                              ],
                            ),
                          ),

                        // 右边的截图按钮
                        if (Platform.isWindows && !_isSmallScreen)
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
                                      onPressed: _takeSnapshotOnWindows,
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
                                    if (!_isSmallScreen)
                                      IconButton(
                                          color: Colors.white,
                                          iconSize: 30,
                                          icon: const Icon(Icons.replay_10),
                                          onPressed: () {
                                            seekPlus(false,
                                                const Duration(seconds: 10));
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
                                    if (!_isSmallScreen)
                                      IconButton(
                                          color: Colors.white,
                                          iconSize: 30,
                                          icon: const Icon(Icons.forward_10),
                                          onPressed: () {
                                            seekPlus(true,
                                                const Duration(seconds: 10));
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
                              if (!_isSmallScreen)
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
                              if (!_isSmallScreen)
                                VolumeControl(
                                  player: _player,
                                  thumbColor: Colors.lightGreen,
                                  inactiveColor: Colors.grey,
                                  activeColor: Colors.blue,
                                  backgroundColor: const Color(0xff424242),
                                ),

                              /// 音频轨道按钮
                              if (_player.audioTrackCount > 1 &&
                                  !_isSmallScreen)
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
                                        .where(
                                            (track) => !track.startsWith("-1"))
                                        .map(
                                          (track) => PopupMenuItem(
                                            value: track,
                                            child: Text(track,
                                                style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: audioTrack ==
                                                            _getTrackDescId(
                                                                track)
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
                                  icon: const Icon(Icons.subtitles,
                                      color: Colors.white),
                                  onSelected: (String trackDesc) {
                                    if (trackDesc == "" ||
                                        !trackDesc.contains(":")) return;
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

                              // 右下角小窗置顶
                              IconButton(
                                onPressed:
                                    isLoading.value ? null : _switchSmallScreen,
                                icon: Icon(
                                  Icons.picture_in_picture_alt_outlined,
                                  color: isLoading.value
                                      ? Colors.grey
                                      : Colors.white,
                                ),
                              ),

                              // 全屏控制按钮
                              if (!_isSmallScreen)
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
                  )
                  // child: Stack(
                  //   children: [
                  //     // 上方中间的标题文本
                  //     Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Column(
                  //           mainAxisAlignment: MainAxisAlignment.start,
                  //           children: [
                  //             Text(_title,
                  //                 style: const TextStyle(
                  //                     color: Colors.white,
                  //                     fontSize: 20,
                  //                     decoration: TextDecoration.none)),
                  //             Text(_subTitle,
                  //                 style: const TextStyle(
                  //                     color: Colors.white,
                  //                     fontSize: 10,
                  //                     decoration: TextDecoration.none)),
                  //           ],
                  //         )
                  //       ],
                  //     ),
                  //     // 上方左边的返回按钮
                  //     Positioned(
                  //       left: 15,
                  //       top: 12.5,
                  //       child: Row(
                  //         mainAxisAlignment: MainAxisAlignment.start,
                  //         children: [
                  //           IconButton(
                  //               onPressed: () {
                  //                 if (!_isSmallScreen && !_isFullScreen) {
                  //                   Navigator.of(context).pop();
                  //                   return;
                  //                 }
                  //
                  //                 if (_isSmallScreen) {
                  //                   _switchSmallScreen();
                  //                   return;
                  //                 }
                  //
                  //                 if (_isFullScreen) {
                  //                   _updateFullScreen();
                  //                   return;
                  //                 }
                  //               },
                  //               iconSize: 30,
                  //               icon: const Icon(
                  //                 Icons.arrow_back,
                  //                 color: Colors.white,
                  //               ))
                  //         ],
                  //       ),
                  //     ),
                  //
                  //     // 上方右边的设置按钮
                  //     if (!_isSmallScreen)
                  //       Positioned(
                  //         right: 15,
                  //         top: 12.5,
                  //         child: Row(
                  //           mainAxisAlignment: MainAxisAlignment.end,
                  //           children: [
                  //             IconButton(
                  //                 onPressed: _openSettingsPanel,
                  //                 iconSize: 30,
                  //                 icon: const Icon(
                  //                   Icons.settings,
                  //                   color: Colors.white,
                  //                 ))
                  //           ],
                  //         ),
                  //       ),
                  //
                  //     // 右边的截图按钮
                  //     if (Platform.isWindows && !_isSmallScreen)
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.end,
                  //         children: [
                  //           Padding(
                  //             padding: const EdgeInsets.only(right: 15),
                  //             child: Column(
                  //               mainAxisAlignment: MainAxisAlignment.center,
                  //               children: [
                  //                 IconButton(
                  //                   color: Colors.white,
                  //                   iconSize: 30,
                  //                   icon: const Icon(Icons.photo_camera),
                  //                   onPressed: _takeSnapshotOnWindows,
                  //                 ),
                  //               ],
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //
                  //     /// 底部的控制UI
                  //     Positioned(
                  //       left: 0,
                  //       right: 0,
                  //       bottom: 0,
                  //       child: Padding(
                  //         padding: const EdgeInsets.only(
                  //             bottom: 60, right: 20, left: 20),
                  //         child: StreamBuilder<PositionState>(
                  //           stream: _player.positionStream,
                  //           builder: (BuildContext context,
                  //               AsyncSnapshot<PositionState> snapshot) {
                  //             final durationState = snapshot.data;
                  //             final progress =
                  //                 durationState?.position ?? Duration.zero;
                  //             final total =
                  //                 durationState?.duration ?? Duration.zero;
                  //             return Theme(
                  //               data: ThemeData.dark(),
                  //               child: ProgressBar(
                  //                 progress: progress,
                  //                 total: total,
                  //                 barHeight: 3,
                  //                 thumbRadius: 10.0,
                  //                 thumbGlowRadius: 30.0,
                  //                 timeLabelLocation: TimeLabelLocation.sides,
                  //                 timeLabelType: TimeLabelType.totalTime,
                  //                 timeLabelTextStyle:
                  //                 const TextStyle(color: Colors.white),
                  //                 onSeek: (duration) {
                  //                   seek(duration);
                  //                 },
                  //               ),
                  //             );
                  //           },
                  //         ),
                  //       ),
                  //     ),
                  //     StreamBuilder<CurrentState>(
                  //       stream: _player.currentStream,
                  //       builder: (context, snapshot) {
                  //         return Positioned(
                  //             left: 0,
                  //             right: 0,
                  //             bottom: 10,
                  //             child: Row(
                  //               mainAxisSize: MainAxisSize.min,
                  //               mainAxisAlignment: MainAxisAlignment.start,
                  //               crossAxisAlignment: CrossAxisAlignment.end,
                  //               children: [
                  //                 if ((snapshot.data?.medias.length ?? 0) > 1)
                  //                   IconButton(
                  //                     color: Colors.white,
                  //                     iconSize: 30,
                  //                     icon: const Icon(Icons.skip_previous),
                  //                     onPressed: () => _player.previous(),
                  //                   ),
                  //                 const SizedBox(width: 50),
                  //                 if (!_isSmallScreen)
                  //                   IconButton(
                  //                       color: Colors.white,
                  //                       iconSize: 30,
                  //                       icon: const Icon(Icons.replay_10),
                  //                       onPressed: () {
                  //                         seekPlus(
                  //                             false, const Duration(seconds: 10));
                  //                       }),
                  //                 const SizedBox(
                  //                   width: 20,
                  //                 ),
                  //
                  //                 /// 播放暂停按钮
                  //                 IconButton(
                  //                   color: Colors.white,
                  //                   iconSize: 30,
                  //                   icon: AnimatedIcon(
                  //                       icon: AnimatedIcons.play_pause,
                  //                       progress: playPauseController),
                  //                   onPressed: _switchPlayerPauseOrPlay,
                  //                 ),
                  //                 const SizedBox(width: 20),
                  //                 if (!_isSmallScreen)
                  //                   IconButton(
                  //                       color: Colors.white,
                  //                       iconSize: 30,
                  //                       icon: const Icon(Icons.forward_10),
                  //                       onPressed: () {
                  //                         seekPlus(
                  //                             true, const Duration(seconds: 10));
                  //                       }),
                  //                 const SizedBox(
                  //                   width: 20,
                  //                 ),
                  //                 if ((snapshot.data?.medias.length ?? 0) > 1)
                  //                   IconButton(
                  //                     color: Colors.white,
                  //                     iconSize: 30,
                  //                     icon: const Icon(Icons.skip_next),
                  //                     onPressed: () => _player.next(),
                  //                   ),
                  //               ],
                  //             ));
                  //       },
                  //     ),
                  //
                  //     Positioned(
                  //       right: 15,
                  //       bottom: 12.5,
                  //       child: Row(
                  //         crossAxisAlignment: CrossAxisAlignment.end,
                  //         children: [
                  //           // 倍速按钮
                  //           if (!_isSmallScreen)
                  //             IconButton(
                  //               iconSize: 24,
                  //               color: Colors.white,
                  //               icon: Row(
                  //                 mainAxisSize: MainAxisSize.min,
                  //                 children: [
                  //                   const Icon(Icons.speed),
                  //                   const SizedBox(
                  //                     width: 4,
                  //                   ),
                  //                   Text(
                  //                     'x$_playbackSpeed',
                  //                     style: const TextStyle(
                  //                         color: Colors.white,
                  //                         fontSize: 16,
                  //                         fontWeight: FontWeight.bold),
                  //                   )
                  //                 ],
                  //               ),
                  //               onPressed: _updateSpeed,
                  //               tooltip: "更改倍速",
                  //             ),
                  //
                  //           /// 音量控制
                  //           if (!_isSmallScreen)
                  //             VolumeControl(
                  //               player: _player,
                  //               thumbColor: Colors.lightGreen,
                  //               inactiveColor: Colors.grey,
                  //               activeColor: Colors.blue,
                  //               backgroundColor: const Color(0xff424242),
                  //             ),
                  //
                  //           /// 音频轨道按钮
                  //           if (_player.audioTrackCount > 1 && !_isSmallScreen)
                  //             PopupMenuButton(
                  //               iconSize: 24,
                  //               tooltip: "音频轨道",
                  //               icon: const Icon(Icons.audiotrack,
                  //                   color: Colors.white),
                  //               onSelected: (String trackDesc) {
                  //                 int? id = _getTrackDescId(trackDesc);
                  //                 if (id == null) return;
                  //                 _player.setAudioTrack(id);
                  //               },
                  //               itemBuilder: (context) {
                  //                 final audioTrack = _player.audioTrack();
                  //                 return _player
                  //                     .audioTrackDescription()
                  //                     .where((track) => !track.startsWith("-1"))
                  //                     .map(
                  //                       (track) =>
                  //                       PopupMenuItem(
                  //                         value: track,
                  //                         child: Text(track,
                  //                             style: TextStyle(
                  //                                 fontSize: 14.0,
                  //                                 color: audioTrack ==
                  //                                     _getTrackDescId(track)
                  //                                     ? Colors.lightBlueAccent
                  //                                     : Colors.black)),
                  //                       ),
                  //                 )
                  //                     .toList();
                  //               },
                  //             ),
                  //
                  //           // 字幕轨道按钮
                  //           if (_player.spuCount() > 0)
                  //             PopupMenuButton(
                  //               iconSize: 24,
                  //               tooltip: "字幕轨道",
                  //               icon: const Icon(Icons.subtitles,
                  //                   color: Colors.white),
                  //               onSelected: (String trackDesc) {
                  //                 if (trackDesc == "" || !trackDesc.contains(":"))
                  //                   return;
                  //                 var trackProps = trackDesc.split(":");
                  //                 var trackId = int.parse(trackProps[0]);
                  //                 _player.setSpu(trackId);
                  //               },
                  //               itemBuilder: (context) {
                  //                 final spu = _player.spu();
                  //                 return _player
                  //                     .spuTrackDescription()
                  //                     .map(
                  //                       (track) =>
                  //                       PopupMenuItem(
                  //                         value: track,
                  //                         child: Text(track,
                  //                             style: TextStyle(
                  //                                 fontSize: 14.0,
                  //                                 color: track.startsWith(
                  //                                     spu.toString())
                  //                                     ? Colors.lightBlueAccent
                  //                                     : Colors.black)),
                  //                       ),
                  //                 )
                  //                     .toList();
                  //               },
                  //             ),
                  //
                  //           // 右下角小窗置顶
                  //           IconButton(
                  //             onPressed:
                  //             isLoading.value ? null : _switchSmallScreen,
                  //             icon: Icon(
                  //               Icons.picture_in_picture_alt_outlined,
                  //               color:
                  //               isLoading.value ? Colors.grey : Colors.white,
                  //             ),
                  //           ),
                  //
                  //           // 全屏控制按钮
                  //           if (!_isSmallScreen)
                  //             IconButton(
                  //               iconSize: 24,
                  //               icon: Icon(
                  //                   _isFullScreen
                  //                       ? Icons.fullscreen_exit
                  //                       : Icons.fullscreen,
                  //                   color: Colors.white),
                  //               onPressed: _updateFullScreen,
                  //             ),
                  //         ],
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  ),

              DanmakuView(
                createdController: (e) {
                  _danmuku = e;
                },
                option: _danmuConfig.toOption(),
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
              child: SizedBox(
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
