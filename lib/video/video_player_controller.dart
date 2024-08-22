import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

abstract class VideoPlayerController {
  bool isInitialized = false;
  double aspectRatio = 16 / 9;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  late Function? onPlayerInitialized;


  static VideoPlayerController createInstanceByPlatform() {
    if (Platform.isAndroid || Platform.isIOS) {
      return MobileVideoPlayerController();
    }
    return DesktopVideoPlayerController();
  }

  void setOnPlayerInitialized(Function fun) {
    onPlayerInitialized = fun;
  }

  void init(String url, {bool autoPlay = false});

  void play();

  void pause();

  void seek(Duration dest);

  void dispose();

  Widget buildVideoPlayerWidget();
}

/// Run in Android and IOS, core is flutter_vlc_player.
class MobileVideoPlayerController extends VideoPlayerController {
  late VlcPlayerController _corePlayer;

  void corePlayerListener() {
    if (_corePlayer.value.isInitialized) {
      position = _corePlayer.value.position;
      duration = _corePlayer.value.duration;
      isInitialized = true;
      onPlayerInitialized?.call();
    }
  }

  @override
  void init(String url, {bool autoPlay = false}) {
    _corePlayer = VlcPlayerController.network(
      url,
      hwAcc: HwAcc.full,
      autoPlay: autoPlay,
      options: VlcPlayerOptions(),
    );
    _corePlayer.addListener(corePlayerListener);
  }

  @override
  void play() {
    _corePlayer.play();
  }

  @override
  void dispose() {
    _corePlayer.dispose();
  }

  @override
  void pause() {
    _corePlayer.pause();
  }

  @override
  void seek(Duration dest) {
    _corePlayer.seekTo(dest);
  }

  @override
  Widget buildVideoPlayerWidget() {
    return VlcPlayer(
      controller: _corePlayer,
      aspectRatio: aspectRatio,
      placeholder:
      const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Run in Windows and Linux. core is dart_vlc
class DesktopVideoPlayerController extends VideoPlayerController {

  @override
  void play() {
    // TODO: implement player
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  void pause() {
    // TODO: implement pause
  }

  @override
  void seek(Duration dest) {
    // TODO: implement seek
  }

  @override
  void init(String url, {bool autoPlay = false}) {
    // TODO: implement setUrl
  }

  @override
  Widget buildVideoPlayerWidget() {
    // TODO: implement buildVideoPlayerWidget
    throw UnimplementedError();
  }
}
