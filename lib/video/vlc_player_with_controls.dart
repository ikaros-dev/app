import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:ikaros/api/collection/EpisodeCollectionApi.dart';
import 'package:ikaros/api/collection/model/EpisodeCollection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock/wakelock.dart';

typedef OnStopRecordingCallback = void Function(String);

class VlcPlayerWithControls extends StatefulWidget {
  final updateIsFullScreen;
  final int episodeId;
  final String videoUrl;
  final List<String>? subtitleUrls;
  final Function? onPlayerInitialized;

  const VlcPlayerWithControls(
      {super.key,
      this.updateIsFullScreen,
      required this.episodeId,
      required this.videoUrl,
      this.subtitleUrls,
      this.onPlayerInitialized});

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

  late VlcPlayerController _mobileController;

  late OverlayEntry _overlayEntry;

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

  late String _videoUrl;
  List<String>? _subtitleUrls;
  String _videoTitle = "";
  String _videoSubhead = "";
  late int _episodeId;

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
    _mobileController = VlcPlayerController.network(
      _videoUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
    _mobileController.addListener(listener);
  }

  @override
  void dispose() async {
    _mobileController.removeListener(listener);
    super.dispose();
    if (_episodeId > 0) {
      await EpisodeCollectionApi().updateCollection(
          _episodeId, _mobileController.value.position, _mobileController.value.duration);
    }
    await _mobileController.stopRendererScanning();
    await _mobileController.dispose();
    if (_showControlFutureInit) {
      _showControlFuture.ignore();
    }
  }

  void listener() {
    if (!mounted) return;
    //
    if (_mobileController.value.isInitialized) {
      final oPosition = _mobileController.value.position;
      final oDuration = _mobileController.value.duration;
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
        numberOfCaptions = _mobileController.value.spuTracksCount;
        numberOfAudioTracks = _mobileController.value.audioTracksCount;
      });
      // update recording blink widget
      if (_mobileController.value.isRecording && _mobileController.value.isPlaying) {
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
          _mobileController.addSubtitleFromNetwork(_subtitleUrls![i],
              isSelected: i == 0);
        }
        setState(() {
          _subtitleIsLoaded = true;
        });
      }

      _updateWakeLock();

      widget.onPlayerInitialized?.call();
    }
  }

  // 播放状态下开启屏幕常亮
  void _updateWakeLock() async {
    bool? isPlaying = await _mobileController.isPlaying();
    if (isPlaying != null && isPlaying) {
      Wakelock.enable();
    } else {
      Wakelock.disable();
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
      String? videoSubhead) async {
    if (videoUrl == _videoUrl) {
      return;
    }

    print("change datasource for videoUrl: $videoUrl");
    if (_mobileController.value.isInitialized) {
      // update old episode progress
      if (_episodeId > 0) {
        await EpisodeCollectionApi().updateCollection(
            _episodeId, _mobileController.value.position, _mobileController.value.duration);
      }

      // stop old player
      _mobileController.pause();
      _mobileController.stopRendererScanning();
      _mobileController.stop();
      setState(() {
        _episodeId = episodeId;
        _videoUrl = videoUrl;
        _subtitleUrls = subtitleUrls;
        if (videoTitle != null) {
          _videoTitle = videoTitle;
        }
        if (videoSubhead != null) {
          _videoSubhead = videoSubhead;
        }
      });

      // set new player
      await _mobileController.setMediaFromNetwork(_videoUrl,
          autoPlay: true, hwAcc: HwAcc.full);

      // load new subtitles
      if (_subtitleUrls != null && _subtitleUrls!.isNotEmpty) {
        for (int i = 0; i < _subtitleUrls!.length; i++) {
          print("add subtitle url to video, url: ${_subtitleUrls![i]}");
          await _mobileController.addSubtitleFromNetwork(_subtitleUrls![i],
              isSelected: i == 0);
        }
      }

      // seek to
      EpisodeCollection episodeCollection =
          await EpisodeCollectionApi().findCollection(episodeId);
      if (episodeCollection.progress != null &&
          episodeCollection.progress! > 0) {
        print(
            "seek to episode collection progress:${episodeCollection.progress}");
        // await _controller.seekTo(Duration(milliseconds: episodeCollection.progress!));
        //convert to Milliseconds since VLC requires MS to set time
        await _mobileController.setTime(episodeCollection.progress!);
      }

      print("set datasource for video "
          "title: [$videoTitle] "
          "and subhead: [$videoSubhead]"
          "and url: [$videoUrl] ");
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
    await _mobileController.pause();
    await _mobileController.play();

    await _mobileController.setVolume(0);

    await Future.delayed(const Duration(milliseconds: 150), () async {
      await _mobileController.pause();
      await _mobileController.setTime(0);
      await _mobileController.setVolume(100);
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
                          tooltip: 'Get Audio Tracks',
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
                                '$numberOfAudioTracks',
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
                        'Size: ${_mobileController.value.size.width.toInt() ?? 0}'
                        'x${_mobileController.value.size.height.toInt() ?? 0}',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Status: ${_mobileController.value.playingState.toString().split('.')[1]}',
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
                        controller: _mobileController,
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
                  icon: _mobileController.value.isPlaying
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
                                  _mobileController.value.duration == null)
                              ? 1.0
                              : _mobileController.value.duration.inSeconds.toDouble(),
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

    return _mobileController
        .setPlaybackSpeed(playbackSpeeds.elementAt(playbackSpeedIndex));
  }

  void _setSoundVolume(double value) {
    setState(() {
      volumeValue = value;
    });
    _mobileController.setVolume(volumeValue.toInt());
  }

  Future<void> _togglePlaying() async {
    _mobileController.value.isPlaying
        ? await _mobileController.pause()
        : await _mobileController.play();
  }

  Future<void> _toggleRecording() async {
    if (!_mobileController.value.isRecording) {
      final saveDirectory = await getTemporaryDirectory();
      await _mobileController.startRecording(saveDirectory.path);
    } else {
      await _mobileController.stopRecording();
    }
  }

  void _onSliderPositionChanged(double progress) {
    setState(() {
      sliderValue = progress.floor().toDouble();
    });
    //convert to Milliseconds since VLC requires MS to set time
    _mobileController.setTime(sliderValue.toInt() * Duration.millisecondsPerSecond);
  }

  Future<void> _getSubtitleTracks() async {
    if (!_mobileController.value.isPlaying) return;

    final subtitleTracks = await _mobileController.getSpuTracks();

    if (subtitleTracks != null && subtitleTracks.isNotEmpty) {
      if (!mounted) return;
      final int selectedSubId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Subtitle'),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: subtitleTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < subtitleTracks.keys.length
                          ? subtitleTracks.values.elementAt(index).toString()
                          : 'Disable',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < subtitleTracks.keys.length
                            ? subtitleTracks.keys.elementAt(index)
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
      if (selectedSubId != null) await _mobileController.setSpuTrack(selectedSubId);
    }
  }

  Future<void> _getAudioTracks() async {
    if (!_mobileController.value.isPlaying) return;

    final audioTracks = await _mobileController.getAudioTracks();
    //
    if (audioTracks.isNotEmpty) {
      if (!mounted) return;
      final int selectedAudioTrackId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Audio'),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: audioTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < audioTracks.keys.length
                          ? audioTracks.values.elementAt(index).toString()
                          : 'Disable',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < audioTracks.keys.length
                            ? audioTracks.keys.elementAt(index)
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
      if (selectedAudioTrackId != null) {
        await _mobileController.setAudioTrack(selectedAudioTrackId);
      }
    }
  }

  Future<void> _getRendererDevices() async {
    final castDevices = await _mobileController.getRendererDevices();
    //
    if (castDevices.isNotEmpty) {
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
      await _mobileController.castToRenderer(selectedCastDeviceName);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Display Device Found!')),
      );
    }
  }

  Future<void> _createCameraImage() async {
    final snapshot = await _mobileController.takeSnapshot();
    _overlayEntry?.remove();
    _overlayEntry = _createSnapshotThumbnail(snapshot);
    if (!mounted) return;
    Overlay.of(context).insert(_overlayEntry);
  }

  OverlayEntry _createSnapshotThumbnail(Uint8List snapshot) {
    double right = initSnapshotRightPosition;
    double bottom = initSnapshotBottomPosition;

    return OverlayEntry(
      builder: (context) => Positioned(
        right: right,
        bottom: bottom,
        width: _overlayWidth,
        child: Material(
          elevation: _elevation,
          child: GestureDetector(
            onTap: () async {
              _overlayEntry?.remove();
              // _overlayEntry = null;
              await showDialog<void>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    contentPadding: EdgeInsets.zero,
                    content: Image.memory(snapshot),
                  );
                },
              );
            },
            onVerticalDragUpdate: (dragUpdateDetails) {
              bottom -= dragUpdateDetails.delta.dy;
              _overlayEntry.markNeedsBuild();
            },
            onHorizontalDragUpdate: (dragUpdateDetails) {
              right -= dragUpdateDetails.delta.dx;
              _overlayEntry.markNeedsBuild();
            },
            onHorizontalDragEnd: (dragEndDetails) {
              if ((initSnapshotRightPosition - right).abs() >= _overlayWidth) {
                _overlayEntry?.remove();
                // _overlayEntry = null;
              } else {
                right = initSnapshotRightPosition;
                _overlayEntry.markNeedsBuild();
              }
            },
            onVerticalDragEnd: (dragEndDetails) {
              if ((initSnapshotBottomPosition - bottom).abs() >=
                  _overlayWidth) {
                _overlayEntry?.remove();
                // _overlayEntry = null;
              } else {
                bottom = initSnapshotBottomPosition;
                _overlayEntry.markNeedsBuild();
              }
            },
            child: Image.memory(snapshot),
          ),
        ),
      ),
    );
  }
}
