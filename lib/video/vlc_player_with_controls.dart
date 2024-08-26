import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:getwidget/components/toast/gf_toast.dart';
import 'package:getwidget/getwidget.dart';
import 'package:ikaros/api/collection/EpisodeCollectionApi.dart';
import 'package:path_provider/path_provider.dart';

typedef OnStopRecordingCallback = void Function(String);

class VlcPlayerWithControls extends StatefulWidget {
  final updateIsFullScreen;
  final Function? onPlayerInitialized;
  final String videoUrl;
  final String videoTitle;
  final int episodeId;
  final List<String>? subtitleUrls;

  const VlcPlayerWithControls(
      {super.key,
      this.updateIsFullScreen,
      this.onPlayerInitialized,
      required this.videoUrl,
      this.subtitleUrls,
      required this.videoTitle,
      required this.episodeId});

  @override
  VlcPlayerWithControlsState createState() => VlcPlayerWithControlsState();
}

class VlcPlayerWithControlsState extends State<VlcPlayerWithControls>
    with AutomaticKeepAliveClientMixin {
  static const _playerControlsBgColor = Colors.black87;
  static const _numberPositionOffset = 8.0;
  static const _recordingPositionOffset = 10.0;
  static const _positionedBottomSpace = 7.0;
  static const _positionedRightSpace = 3.0;
  static const _overlayWidth = 100.0;
  static const _elevation = 4.0;
  static const _aspectRatio = 16 / 9;

  final double initSnapshotRightPosition = 10;
  final double initSnapshotBottomPosition = 10;

  late VlcPlayerController _controller;

  double sliderValue = 0.0;
  double volumeValue = 50;
  String position = '';
  String duration = '';
  int numberOfCaptions = 0;
  int numberOfAudioTracks = 0;
  bool validPosition = false;

  double recordingTextOpacity = 0;
  DateTime lastRecordingShowTime = DateTime.now();
  bool isRecording = false;

  List<double> playbackSpeeds = [0.5, 1.0, 2.0];
  int playbackSpeedIndex = 1;

  late AnimationController _scaleVideoAnimationController;
  Animation<double> _scaleVideoAnimation =
      const AlwaysStoppedAnimation<double>(1.0);
  double? _targetVideoScale;

  bool _isFullScreen = false;
  bool _subtitleIsLoaded = false;
  bool _showControl = false;

  late String _videoUrl = "http";
  List<String>? _subtitleUrls = [];
  String _videoTitle = "";
  String _videoSubhead = "";
  late int _episodeId = 0;

  bool _progressIsLoaded = false;
  int _progress = 0;

  late Future _showControlFuture;
  bool _showControlFutureInit = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _episodeId = widget.episodeId;
    _videoUrl = widget.videoUrl;
    _subtitleUrls = widget.subtitleUrls;
    _videoTitle = widget.videoTitle;
    _controller = VlcPlayerController.network(
      _videoUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
    _controller.addListener(listener);
  }

  @override
  void dispose() async {
    _controller.removeListener(listener);
    super.dispose();
    if (_episodeId > 0) {
      await EpisodeCollectionApi().updateCollection(
          _episodeId, _controller.value.position, _controller.value.duration);
    }
    await _controller.stopRendererScanning();
    await _controller.dispose();
    if (_showControlFutureInit) {
      _showControlFuture.ignore();
    }
  }

  void listener() {
    if (!mounted) return;
    //
    if (_controller.value.isInitialized) {
      final oPosition = _controller.value.position;
      final oDuration = _controller.value.duration;
      if (oDuration.inHours == 0) {
        final strPosition = oPosition.toString().split('.').first;
        final strDuration = oDuration.toString().split('.').first;
        setState(() {
          position =
              "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
          duration =
              "${strDuration.split(':')[1]}:${strDuration.split(':')[2]}";
        });
      } else {
        setState(() {
          position = oPosition.toString().split('.').first;
          duration = oDuration.toString().split('.').first;
        });
      }
      setState(() {
        validPosition = oDuration.compareTo(oPosition) >= 0;
        sliderValue = validPosition ? oPosition.inSeconds.toDouble() : 0;
      });
      setState(() {
        numberOfCaptions = _controller.value.spuTracksCount;
        numberOfAudioTracks = _controller.value.audioTracksCount;
      });
      // update recording blink widget
      if (_controller.value.isRecording && _controller.value.isPlaying) {
        if (DateTime.now().difference(lastRecordingShowTime).inSeconds >= 1) {
          setState(() {
            lastRecordingShowTime = DateTime.now();
            recordingTextOpacity = 1 - recordingTextOpacity;
          });
        }
      } else {
        setState(() => recordingTextOpacity = 0);
      }

      // load subtitle urls once
      if (!_subtitleIsLoaded && _subtitleUrls != null) {
        for (int i = 0; i < _subtitleUrls!.length; i++) {
          _controller.addSubtitleFromNetwork(_subtitleUrls![i],
              isSelected: i == 0);
        }
        setState(() {
          _subtitleIsLoaded = true;
        });
      }

      // // seek to  once
      // if (!_progressIsLoaded && _progress > 0) {
      //   _controller.seekTo(Duration(milliseconds: _progress));
      //   print("seek to $_progress");
      //   setState(() {
      //     _progressIsLoaded = true;
      //   });
      // }

      _updateWakeLock();

      widget.onPlayerInitialized?.call();
    }

    if (_controller.value.isPlaying) {
      // print("isPlaying");
      // seek to  once
      if (!_progressIsLoaded && _progress > 0) {
        _controller.seekTo(Duration(milliseconds: _progress));
        print("seek to $_progress");
        setState(() {
          _progressIsLoaded = true;
        });
      }
    }
  }

  // 播放状态下开启屏幕常亮
  void _updateWakeLock() async {
    bool? isPlaying = await _controller.isPlaying();
    if (isPlaying != null && isPlaying) {
      // Wakelock.enable();
    } else {
      // Wakelock.disable();
    }
  }

  _updateShowControl() {
    setState(() {
      _showControl = !_showControl;
    });
    if (_showControl) {
      _showControlFuture =
          Future.delayed(const Duration(milliseconds: 5000), () {
        if (mounted) {
          setState(() {
            _showControl = false;
            _showControlFutureInit = true;
          });
        }
      });
    }
    // Fluttertoast.showToast(
    //     msg: "click screen",
    //     toastLength: Toast.LENGTH_SHORT,
    //     gravity: ToastGravity.CENTER,
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: Colors.green,
    //     textColor: Colors.white,
    //     fontSize: 16.0);
  }

  void setTargetNativeScale(double newValue) {
    if (!newValue.isFinite) {
      return;
    }
    _scaleVideoAnimation =
        Tween<double>(begin: 1.0, end: newValue).animate(CurvedAnimation(
      parent: _scaleVideoAnimationController,
      curve: Curves.easeInOut,
    ));

    if (_targetVideoScale == null) {
      _scaleVideoAnimationController.forward();
    }
    _targetVideoScale = newValue;
  }

  Future<void> changeDatasource(
      int episodeId,
      String videoUrl,
      List<String>? subtitleUrls,
      String? videoTitle,
      String? videoSubhead,
      int? progress) async {
    if (videoUrl == _videoUrl) {
      return;
    }

    print("change datasource for videoUrl: $videoUrl");
    if (_controller.value.isInitialized) {
      // update old episode progress
      if (_episodeId > 0) {
        await EpisodeCollectionApi().updateCollection(
            _episodeId, _controller.value.position, _controller.value.duration);
      }

      // stop old player
      _controller.pause();
      _controller.stopRendererScanning();
      _controller.stop();
      setState(() {
        _episodeId = episodeId;
        _videoUrl = videoUrl;
        _subtitleUrls = subtitleUrls;
        _progress = progress ?? 0;
        if (videoTitle != null) {
          _videoTitle = videoTitle;
        }
        if (videoSubhead != null) {
          _videoSubhead = videoSubhead;
        }
      });

      // set new player
      await _controller.setMediaFromNetwork(_videoUrl,
          autoPlay: true, hwAcc: HwAcc.full);

      // load new subtitles
      if (_subtitleUrls != null && _subtitleUrls!.isNotEmpty) {
        for (int i = 0; i < _subtitleUrls!.length; i++) {
          print("add subtitle url to video, url: ${_subtitleUrls![i]}");
          await _controller.addSubtitleFromNetwork(_subtitleUrls![i],
              isSelected: i == 0);
        }
      }

      // seek to
      // EpisodeCollection episodeCollection =
      //     await EpisodeCollectionApi().findCollection(episodeId);
      // if (episodeCollection.progress != null &&
      //     episodeCollection.progress! > 0) {
      //   print(
      //       "seek to episode collection progress:${episodeCollection.progress}");
      //   // await _controller.seekTo(Duration(milliseconds: episodeCollection.progress!));
      //   //convert to Milliseconds since VLC requires MS to set time
      //   await _controller.setTime(episodeCollection.progress!);
      // }

      print("set datasource for video "
          "title: [$videoTitle] "
          "and subhead: [$videoSubhead]"
          "and url: [$videoUrl] "
          "and progress: [$progress]");
    }

    // if(_controller.value.isInitialized) {
    //   await _controller.stopRendererScanning();
    //   await _controller.stop();
    //   _controller.removeListener(listener);
    // }
    // _videoUrl = videoUrl;
    // _subtitleUrls = subtitleUrls;
    // _controller = VlcPlayerController.network(
    //   _videoUrl,
    //   hwAcc: HwAcc.full,
    //   autoPlay: true,
    //   options: VlcPlayerOptions(),
    // );
    // _controller.addListener(listener);
  }

  // Workaround the following bugs:
  // https://github.com/solid-software/flutter_vlc_player/issues/335
  // https://github.com/solid-software/flutter_vlc_player/issues/336
  Future<void> _stopAutoplay() async {
    await _controller.pause();
    await _controller.play();

    await _controller.setVolume(0);

    await Future.delayed(const Duration(milliseconds: 150), () async {
      await _controller.pause();
      await _controller.setTime(0);
      await _controller.setVolume(100);
    });
  }

  Future<void> _forceLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _forcePortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values); // to re-show bars
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Visibility(
          visible: _showControl,
          child: Container(
            width: double.infinity,
            color: _playerControlsBgColor,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                Wrap(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          tooltip: 'Get Subtitle Tracks',
                          icon: const Icon(Icons.closed_caption),
                          color: Colors.white,
                          onPressed: _getSubtitleTracks,
                        ),
                        Positioned(
                          top: _numberPositionOffset,
                          right: _numberPositionOffset,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 1,
                                horizontal: 2,
                              ),
                              child: Text(
                                '$numberOfCaptions',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          tooltip: '音频轨道',
                          icon: const Icon(Icons.audiotrack),
                          color: Colors.white,
                          onPressed: _getAudioTracks,
                        ),
                        Positioned(
                          top: _numberPositionOffset,
                          right: _numberPositionOffset,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 1,
                                horizontal: 2,
                              ),
                              child: Text(
                                // 去掉音频的Disable轨道
                                '${numberOfAudioTracks - 1}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.timer),
                          color: Colors.white,
                          onPressed: _cyclePlaybackSpeed,
                        ),
                        Positioned(
                          bottom: _positionedBottomSpace,
                          right: _positionedRightSpace,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 1,
                                horizontal: 2,
                              ),
                              child: Text(
                                '${playbackSpeeds.elementAt(playbackSpeedIndex)}x',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // IconButton(
                    //   tooltip: 'Get Snapshot',
                    //   icon: const Icon(Icons.camera),
                    //   color: Colors.white,
                    //   onPressed: _createCameraImage,
                    // ),
                    // IconButton(
                    //   color: Colors.white,
                    //   icon: _controller.value.isRecording
                    //       ? const Icon(Icons.videocam_off_outlined)
                    //       : const Icon(Icons.videocam_outlined),
                    //   onPressed: _toggleRecording,
                    // ),
                    // IconButton(
                    //   icon: const Icon(Icons.cast),
                    //   color: Colors.white,
                    //   onPressed: _getRendererDevices,
                    // ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _videoTitle,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      const SizedBox(height: 5),
                      Visibility(
                        visible: _isFullScreen,
                        child: Text(
                          _videoSubhead,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Size: ${_controller.value.size?.width?.toInt() ?? 0}'
                        'x${_controller.value.size?.height?.toInt() ?? 0}',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Status: ${_controller.value.playingState.toString().split('.')[1]}',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
              onTap: () {
                _updateShowControl();
              },
              onDoubleTap: _togglePlaying,
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    Center(
                      child: VlcPlayer(
                        controller: _controller,
                        aspectRatio: _aspectRatio,
                        placeholder:
                            const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    Positioned(
                      top: _recordingPositionOffset,
                      left: _recordingPositionOffset,
                      child: AnimatedOpacity(
                        opacity: recordingTextOpacity,
                        duration: const Duration(seconds: 1),
                        child: const Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(Icons.circle, color: Colors.red),
                            SizedBox(width: 5),
                            Text(
                              'REC',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ControlsOverlay(_controller),
                  ],
                ),
              )),
        ),
        Visibility(
          visible: _showControl,
          child: ColoredBox(
            color: _playerControlsBgColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  color: Colors.white,
                  icon: _controller.value.isPlaying
                      ? const Icon(Icons.pause_circle_outline)
                      : const Icon(Icons.play_circle_outline),
                  onPressed: _togglePlaying,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        position,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: Slider(
                          activeColor: Colors.redAccent,
                          inactiveColor: Colors.white70,
                          value: sliderValue,
                          min: 0.0,
                          max: (!validPosition &&
                                  _controller.value.duration == null)
                              ? 1.0
                              : _controller.value.duration.inSeconds.toDouble(),
                          onChanged:
                              validPosition ? _onSliderPositionChanged : null,
                        ),
                      ),
                      Text(
                        duration,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                      _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                  color: Colors.white,
                  // ignore: no-empty-block
                  onPressed: () async {
                    setState(() {
                      _isFullScreen = !_isFullScreen;
                      if (_isFullScreen) {
                        _forceLandscape();
                      } else {
                        _forcePortrait();
                      }
                      widget.updateIsFullScreen(_isFullScreen);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _cyclePlaybackSpeed() async {
    playbackSpeedIndex++;
    if (playbackSpeedIndex >= playbackSpeeds.length) {
      playbackSpeedIndex = 0;
    }

    return _controller
        .setPlaybackSpeed(playbackSpeeds.elementAt(playbackSpeedIndex));
  }

  void _setSoundVolume(double value) {
    setState(() {
      volumeValue = value;
    });
    _controller.setVolume(volumeValue.toInt());
  }

  Future<void> _togglePlaying() async {
    _controller.value.isPlaying
        ? await _controller.pause()
        : await _controller.play();
  }

  Future<void> _toggleRecording() async {
    if (!_controller.value.isRecording) {
      final saveDirectory = await getTemporaryDirectory();
      await _controller.startRecording(saveDirectory.path);
    } else {
      await _controller.stopRecording();
    }
  }

  void _onSliderPositionChanged(double progress) {
    setState(() {
      sliderValue = progress.floor().toDouble();
    });
    //convert to Milliseconds since VLC requires MS to set time
    _controller.setTime(sliderValue.toInt() * Duration.millisecondsPerSecond);
  }

  Future<void> _getSubtitleTracks() async {
    if (!_controller.value.isPlaying) return;

    final subtitleTracks = await _controller.getSpuTracks();
    final int? spuTrack = await _controller.getSpuTrack();

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
                  final MapEntry<int, String>? entry = index < subtitleTracks.length ? subtitleTracks.entries.elementAt(index) : null;
                  return ListTile(
                    selected: spuTrack != null && spuTrack == (entry?.key ?? -1),
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
        await _controller.setSpuTrack(selectedSubId);
        print("set spu track with id:$selectedSubId");
        GFToast.showToast("已切换到字幕轨道: $selectedSubId ,生效需要等下一句字幕。", context, toastPosition: GFToastPosition.CENTER);
      }else {
        if (selectedSubId == spuTrack) {
          GFToast.showToast("操作取消，请不要选择已选中的字幕轨道。", context, toastPosition: GFToastPosition.CENTER);
        }
      }
    }
  }

  Future<void> _getAudioTracks() async {
    if (!_controller.value.isPlaying) return;

    final audioTracks = await _controller.getAudioTracks();
    final int? audioTrack = await _controller.getAudioTrack();
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
        await _controller.setAudioTrack(selectedAudioTrackId);
        print("set audio track with id:$selectedAudioTrackId");
        GFToast.showToast("已切换到音频轨道: $selectedAudioTrackId", context, toastPosition: GFToastPosition.CENTER);
      } else {
        if (selectedAudioTrackId == audioTrack) {
          GFToast.showToast("操作取消，请不要选择已选中的音频。", context, toastPosition: GFToastPosition.CENTER);
        }
      }
    }
  }

  Future<void> _getRendererDevices() async {
    final castDevices = await _controller.getRendererDevices();
    //
    if (castDevices != null && castDevices.isNotEmpty) {
      if (!mounted) return;
      final String selectedCastDeviceName = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Display Devices'),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: castDevices.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < castDevices.keys.length
                          ? castDevices.values.elementAt(index).toString()
                          : 'Disconnect',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < castDevices.keys.length
                            ? castDevices.keys.elementAt(index)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      await _controller.castToRenderer(selectedCastDeviceName);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Display Device Found!')),
      );
    }
  }
}
