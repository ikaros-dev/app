import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:path_provider/path_provider.dart';

import 'controls_overlay.dart';

typedef OnStopRecordingCallback = void Function(String);

class VlcPlayerWithControls extends StatefulWidget {
  final VlcPlayerController controller;
  final double aspectRatio;
  final updateIsFullScreen;

  const VlcPlayerWithControls(this.controller,
      {super.key, required this.aspectRatio, this.updateIsFullScreen});
  // const VlcPlayerWithControls({
  //   required Key key,
  //   required this.controller,
  //   this.showControls = true,
  //   required this.onStopRecording,
  // })  : assert(controller != null, 'You must provide a vlc controller'),
  //       super(key: key);

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

  //
  late OverlayEntry _overlayEntry;

  //
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

  //
  List<double> playbackSpeeds = [0.5, 1.0, 2.0];
  int playbackSpeedIndex = 1;

  late AnimationController _scaleVideoAnimationController;
  Animation<double> _scaleVideoAnimation =
      const AlwaysStoppedAnimation<double>(1.0);
  double? _targetVideoScale;

  bool _isFullScreen = false;

  bool _showControls = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(listener);
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    super.dispose();
  }

  void listener() {
    if (!mounted) return;
    //
    if (_controller.value.isInitialized) {
      final oPosition = _controller.value.position;
      final oDuration = _controller.value.duration;
      if (oPosition != null && oDuration != null) {
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
      }
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
    }
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
          visible: true,
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
                    IconButton(
                      tooltip: 'Get Snapshot',
                      icon: const Icon(Icons.camera),
                      color: Colors.white,
                      onPressed: _createCameraImage,
                    ),
                    IconButton(
                      color: Colors.white,
                      icon: _controller.value.isRecording
                          ? const Icon(Icons.videocam_off_outlined)
                          : const Icon(Icons.videocam_outlined),
                      onPressed: _toggleRecording,
                    ),
                    IconButton(
                      icon: const Icon(Icons.cast),
                      color: Colors.white,
                      onPressed: _getRendererDevices,
                    ),
                  ],
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
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Status: ${_controller.value.playingState.toString().split('.')[1]}',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
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
                ControlsOverlay(_controller),
              ],
            ),
          ),
        ),

        Visibility(
          visible: true,
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
                              : _controller.value.duration.inSeconds
                              .toDouble(),
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
                  icon: Icon(_isFullScreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen),
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
    //
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
      if (selectedSubId != null) await _controller.setSpuTrack(selectedSubId);
    }
  }

  Future<void> _getAudioTracks() async {
    if (!_controller.value.isPlaying) return;

    final audioTracks = await _controller.getAudioTracks();
    //
    if (audioTracks != null && audioTracks.isNotEmpty) {
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
        await _controller.setAudioTrack(selectedAudioTrackId);
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

  Future<void> _createCameraImage() async {
    final snapshot = await _controller.takeSnapshot();
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
