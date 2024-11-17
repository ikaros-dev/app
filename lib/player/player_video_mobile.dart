import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:ikaros/api/collection/EpisodeCollectionApi.dart';
import 'package:ikaros/api/dandanplay/DandanplayCommentApi.dart';
import 'package:ikaros/api/dandanplay/DandanplaySearchApi.dart';
import 'package:ikaros/api/dandanplay/model/CommentEpisode.dart';
import 'package:ikaros/api/dandanplay/model/CommentEpisodeIdResponse.dart';
import 'package:ikaros/api/dandanplay/model/SearchEpisodeDetails.dart';
import 'package:ikaros/api/dandanplay/model/SearchEpisodesAnime.dart';
import 'package:ikaros/api/dandanplay/model/SearchEpisodesResponse.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/SubjectSyncApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/api/subject/model/SubjectSync.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/shared_prefs_utils.dart';
import 'package:ikaros/utils/throttle_utils.dart';
import 'package:ikaros/utils/time_utils.dart';
import 'package:ns_danmaku/danmaku_controller.dart';
import 'package:ns_danmaku/danmaku_view.dart';
import 'package:ns_danmaku/models/danmaku_item.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// basic on flutter_vlc_player.
class MobileVideoPlayer extends StatefulWidget {
  Function? onFullScreenChange;
  Function(int count)? onDanmukuPoolInitialed;

  MobileVideoPlayer({super.key, this.onFullScreenChange, this.onDanmukuPoolInitialed});

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
  Duration _lastPosition = Duration.zero;
  late String _title = "主标题剧集信息";
  late String _subTitle = "副标题加载的附件名称";
  late int _episodeId = -1;
  late AnimationController playPauseController;
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0, 3.0];
  List<String> _subtitleUrls = [];
  bool _progressIsLoaded = false;
  int _progress = 0;
  late Episode _episode;
  late Subject _subject;
  late List<SubjectSync> _syncs = [];
  late DanmakuController _danmuku;
  List<CommentEpisode> _commentEpisodes = [];
  List<CommentEpisode> _commentRomovedEpisodes = [];
  late Lock lock = Lock();
  final ThrottleController _throttleController = ThrottleController();
  late DanmuConfig _danmuConfig = DanmuConfig();
  late bool _danmuConfigChange = false;
  late bool _isFullScreenPortraitUp = false;

  void listener() {
    if (!mounted) return;

    if (_player.value.isInitialized) {
      _position = _player.value.position;
      _duration = _player.value.duration;
      _throttleController.run(() {
        _lastPosition = _position;
        _checkAndAddDanmuku(_lastPosition, _position);
        if (kDebugMode) {
          print("check and add danumu for last$_lastPosition curr:$_position");
        }
      }, const Duration(milliseconds: 300));
    }

    if (_player.value.isPlaying) {
      _play();
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
      if (!_progressIsLoaded &&
          _progress > 0 &&
          _duration > const Duration(minutes: 5)) {
        _player.seekTo(Duration(milliseconds: _progress)).then((v) {
          if (kDebugMode) {
            print("seek to $_progress");
          }
          Toast.show(
              context, "已跳转到上次的进度: ${TimeUtils.convertMinSec(_progress)}");
        });
        setState(() {
          _progressIsLoaded = true;
        });
      }
    }

    if (_player.value.isEnded) {
      EpisodeCollectionApi().updateCollectionFinish(_episodeId, true);
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _player = VlcPlayerController.network(
      '', // 初始时不设置视频源
      autoPlay: false,
      hwAcc: HwAcc.full,
    );
    _player.addListener(listener);
    playPauseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    SharedPrefsUtils.getDanmuConfig().then((config) {
      _danmuConfig = config;
      if (mounted) _danmuku.updateOption(_danmuConfig.toOption());
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    if (_episodeId > 0) {
      EpisodeCollectionApi().updateCollection(
          _episodeId, _player.value.position, _player.value.duration);
      if (kDebugMode) {
        print("保存剧集进度成功");
      }
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
    _initDanmukuPool();
    setState(() {});
  }

  void setSubtitleUrls(List<String> subtitles) {
    _subtitleUrls = subtitles;
  }

  void setProgress(int progress) {
    _progress = progress;
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
          lastPosition <= currentPosition &&
          time < lastPosition) {
        _commentEpisodes.remove(commentEp);
        _commentRomovedEpisodes.add(commentEp);
        continue;
      }
      if (time >= lastPosition - const Duration(milliseconds: 100) &&
          time <= currentPosition + const Duration(milliseconds: 100)) {
        _commentEpisodes.remove(commentEp);
        _commentRomovedEpisodes.add(commentEp);
        _addDanmuku(commentEp);
        if (kDebugMode) {
          print(
              "add danmuku item for last:$lastPosition current:$currentPosition test:${commentEp.m}");
        }
      }
    }
  }

  void _addDanmuku(CommentEpisode commentEp) {
    if (!commentEp.p.contains(',') || commentEp.p.split(',').length != 4)
      return;
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

  void reload(String url, {autoPlay = false}) async {
    print("open for autPlay=$autoPlay and url=$url");
    print("player.isReadyToInitialize=${_player.isReadyToInitialize}");
    setState(() {
      isLoading.value = true;
    });
    await _player.stop();
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

  void _initDanmukuPool() async {
    _episode = await EpisodeApi().findById(_episodeId);
    if (_episode.id == -1 || _episode.group != "MAIN")
      return; // 根据条目名和序号只支持查询正片弹幕
    _subject = await SubjectApi().findById(_episode.subjectId);
    _syncs = await SubjectSyncApi().getSyncsBySubjectId(_episode.subjectId);
    if (_subject.id == -1 || _syncs.isEmpty) {
      return; // 自己新建的无三方同步平台ID关联的条目是不会请求弹幕的
    }
    SearchEpisodesResponse? searchEpsResp = await DandanplaySearchApi()
        .searchEpisodes(_subject.name, _episode.sequence.toInt().toString());
    if (searchEpsResp == null ||
        !searchEpsResp.success ||
        searchEpsResp.animes.isEmpty) return;
    SearchEpisodesAnime searchEpisodesAnime = searchEpsResp.animes.first;
    if (searchEpisodesAnime.episodes.isEmpty) return;
    SearchEpisodeDetails searchEpisodeDetails =
        searchEpisodesAnime.episodes.first;
    CommentEpisodeIdResponse? commentEpIdResp = await DandanplayCommentApi()
        .commentEpisodeId(searchEpisodeDetails.episodeId, 1);
    if (commentEpIdResp == null || commentEpIdResp.count == 0) return;
    _commentEpisodes.addAll(commentEpIdResp.comments);
    widget.onDanmukuPoolInitialed?.call(_commentEpisodes.length);
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

  Future<bool> _requestPermission() async {
    // 适用于 Android 11 及以上
    if (await Permission.photos.isGranted ||
        await Permission.storage.isGranted) {
      return true;
    }

    if (await Permission.photos.request().isGranted ||
        await Permission.storage.request().isGranted) {
      return true;
    }

    // 如果是 Android 11 及以上版本，需要请求管理外部存储的权限
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    return false;
  }

  void _takeSnapshot() async {
    _player.pause();
    bool result = await _requestPermission();
    if (!result) {
      Toast.show(context, "无相册权限");
      openAppSettings();
      return;
    }

    PhotoManager.setIgnorePermissionCheck(true);
    // 捕获视频截图
    Uint8List pngBytes = await _player.takeSnapshot();
    // 已获取到权限
    String fileName =
        '${_subject.id}_${_episodeId}_${_position.inMilliseconds}ms.png';
    await PhotoManager.editor.saveImage(pngBytes, filename: fileName);
    Toast.show(context, "截图已保存到相册");

    // bool result = await _requestPermission();
    //
    // if (!result) {
    //   // 无权限则跳转到配置权限的设置页
    //   openAppSettings();
    // }
    //
    // if (result) {
    //   try {
    //     // 捕获视频截图
    //     Uint8List pngBytes = await _player.takeSnapshot();
    //
    //     // 保存图片
    //     if (await PhotoManager.requestPermissionExtend()) {
    //       await PhotoManager.editor.saveImage(pngBytes, filename: '');
    //       Toast.show(context, "截图已保存到相册");
    //     }
    //
    //   } catch (e) {
    //     print(e);
    //   }
    // } else {
    //   Toast.show(context, "相册权限被拒绝");
    // }
  }

  void seek(Duration dest) {
    isLoading.value = true;
    setState(() {});
    _lastPosition = Duration.zero;
    _player.seekTo(dest);
    _danmuku.pause();
    _danmuku.clear();
    lock.synchronized(() {
      _commentEpisodes.addAll(_commentRomovedEpisodes);
      _commentRomovedEpisodes.clear();
    });
    _danmuku.resume();
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

  void _play() {
    if (!_player.value.isPlaying) _player.play();
    _isPlaying = true;
    playPauseController.forward();
    if (!_danmuku.running) _danmuku.resume();
  }

  void _pause() {
    if (_player.value.isPlaying) _player.pause();
    _isPlaying = false;
    playPauseController.reverse();
    if (_danmuku.running) _danmuku.pause();
  }

  void _switchPlayerPauseOrPlay() {
    if (_isPlaying) {
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
        Toast.show(context, "已切换到音频轨道: $selectedAudioTrackId");
      } else {
        if (selectedAudioTrackId == audioTrack) {
          Toast.show(context, "操作取消，请不要选择已选中的音频。");
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
        Toast.show(context, "已切换到字幕轨道: $selectedSubId ,生效需要等下一句字幕。");
      } else {
        if (selectedSubId == spuTrack) {
          Toast.show(context, "操作取消，请不要选择已选中的字幕轨道。");
        }
      }
    }
  }

  Future<void> _reloadDanmukuConfig() async {
    _danmuConfig = await SharedPrefsUtils.getDanmuConfig();
    _danmuku.updateOption(_danmuConfig.toOption());
    Toast.show(context, "更新弹幕样式成功");
    _danmuConfigChange = false;
    setState(() {});
  }

  Future<void> _openSettingsPanel() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
            height: MediaQuery.of(context).size.height *
                (_isFullScreen ? 0.95 : 0.6),
            width: MediaQuery.of(context).size.width * 0.95,
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
            ));
      },
    );
    if (_danmuConfigChange) {
      await SharedPrefsUtils.saveDanmuConfig(_danmuConfig);
      Toast.show(context, "保存新的弹幕样式配置成功");
      await _reloadDanmukuConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleDisplayTap,
      onDoubleTap: _switchPlayerPauseOrPlay,
      child: Stack(
        children: [
          /// 视频
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: VlcPlayer(
              controller: _player,
              aspectRatio: 16 / 9,
              virtualDisplay: true,
              placeholder: const Center(child: CircularProgressIndicator()),
            ),
          ),

          /// 缓冲
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

          /// UI
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _displayTapped ? 1.0 : 0.0,
            child: Stack(
              children: [
                // 上方中间的标题文本
                if (_isFullScreen || _isFullScreenPortraitUp)
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
                            if (_isFullScreen) {
                              _updateFullScreen();
                            } else {
                              Navigator.of(context).pop();
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
                /// 进度条
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
                        timeLabelTextStyle:
                            const TextStyle(color: Colors.white),
                        onSeek: (duration) {
                          seek(duration);
                        },
                      ),
                    ),
                  ),
                ),

                /// 底部按钮
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_isFullScreen && !_isFullScreenPortraitUp)
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
                      if (_isFullScreen && !_isFullScreenPortraitUp)
                        IconButton(
                            color: Colors.white,
                            iconSize: 30,
                            icon: const Icon(Icons.forward_10),
                            onPressed: () {
                              seekPlus(true, const Duration(seconds: 10));
                            }),
                    ],
                  ),
                ),

                Positioned(
                  right: 15,
                  bottom: 12.5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 倍速按钮
                      if (_isFullScreen && !_isFullScreenPortraitUp)
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

                      if (_isFullScreen)
                        IconButton(
                            onPressed: () async {
                              if (_isFullScreenPortraitUp) {
                                await SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.landscapeRight,
                                  DeviceOrientation.landscapeLeft,
                                ]);
                                _isFullScreenPortraitUp = false;
                              } else {
                                await SystemChrome.setPreferredOrientations(
                                    [DeviceOrientation.portraitUp]);
                                _isFullScreenPortraitUp = true;
                              }
                            },
                            icon: const Icon(
                              Icons.screen_rotation_alt,
                              color: Colors.white,
                            )),

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

          /// 弹幕层
          DanmakuView(
            createdController: (e) {
              _danmuku = e;
            },
            option: _danmuConfig.toOption(),
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
