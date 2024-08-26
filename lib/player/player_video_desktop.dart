import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// basic on dart_vlc.
class DesktopVideoPlayer extends StatefulWidget {
  const DesktopVideoPlayer({super.key});

  @override
  State<StatefulWidget> createState() {
    return DesktopVideoPlayerState();
  }
}


class DesktopVideoPlayerState extends State<DesktopVideoPlayer> with SingleTickerProviderStateMixin{
  late Player player;
  late AnimationController playPauseController;
  late StreamSubscription<PlaybackState> playPauseStream;
  bool _displayTapped = false;
  bool _isFullScreen = false;
  Timer? _hideTimer;


  @override
  void initState() {
    super.initState();

    DartVLC.initialize();
    player = Player(id: hashCode);

    playPauseController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));

    playPauseStream = player.playbackStream
        .listen((event) => setPlaybackMode(event.isPlaying));
    if (player.playback.isPlaying) playPauseController.forward();


  }

  @override
  void dispose() {
    playPauseStream.cancel();
    playPauseController.dispose();
    player.dispose();
    super.dispose();
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
    player.open(
      Media.network(url),
      autoStart: autoStart,
    );
  }

  void _updateFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      // widget.onFullScreenChange?.call();
    });
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (player.playback.isPlaying) {
          if (_displayTapped) {
            setState(() {
              _displayTapped = false;
            });
          } else {
            _cancelAndRestartTimer();
          }
        }
      },
      child: MouseRegion(
        onHover: (_) => _cancelAndRestartTimer(),
        child: Stack(
          children: [
            Video(
              player: player,
              showControls: false,
            ),
            ///
            AnimatedOpacity(
              duration: Duration(milliseconds: 300),
              opacity: _displayTapped ? 1.0 : 0.0,
              child: Stack(
                children: [
                  StreamBuilder<CurrentState>(
                    stream: player.currentStream,
                    builder: (context, snapshot) {
                      return Positioned(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if ((snapshot.data?.medias.length ?? 0) > 1)
                                IconButton(
                                  color: Colors.white,
                                  iconSize: 30,
                                  icon: Icon(Icons.skip_previous),
                                  onPressed: () => player.previous(),
                                ),
                              const SizedBox(width: 50),
                              IconButton(
                                color: Colors.white,
                                iconSize: 30,
                                icon: AnimatedIcon(
                                    icon: AnimatedIcons.play_pause,
                                    progress: playPauseController),
                                onPressed: () {
                                  if (player.playback.isPlaying) {
                                    player.pause();
                                    playPauseController.reverse();
                                  } else {
                                    player.play();
                                    playPauseController.forward();
                                  }
                                },
                              ),
                              const SizedBox(width: 20),
                              if ((snapshot.data?.medias.length ?? 0) > 1)
                                IconButton(
                                  color: Colors.white,
                                  iconSize: 30,
                                  icon: Icon(Icons.skip_next),
                                  onPressed: () => player.next(),
                                ),
                              const SizedBox(width: 20),

                              StreamBuilder<PositionState>(
                                stream: player.positionStream,
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
                                      thumbGlowRadius:  30.0,
                                      timeLabelLocation: TimeLabelLocation.sides,
                                      timeLabelType: TimeLabelType.remainingTime,
                                      onSeek: (duration) {
                                        player.seek(duration);
                                      },
                                    ),
                                  );
                                },
                              ),
                              VolumeControl(
                                player: player,
                                thumbColor: Colors.lightGreen,
                                inactiveColor: Colors.grey,
                                activeColor: Colors.blue,
                                backgroundColor:  const Color(0xff424242),
                              ),
                              PopupMenuButton(
                                iconSize: 24,
                                tooltip: "音频轨道",
                                icon: const Icon(Icons.audiotrack, color: Colors.white),
                                onSelected: (String trackDesc) {
                                  int? id = _getTrackDescId(trackDesc);
                                  if (id == null) return;
                                  player.setAudioTrack(id);
                                },
                                itemBuilder: (context) {
                                  final audioTrack = player.audioTrack();
                                  return player.audioTrackDescription()
                                      .where((track)=>!track.startsWith("-1"))
                                      .map(
                                        (track) => PopupMenuItem(
                                      value: track,
                                      child: Text(track, style: TextStyle(
                                          fontSize: 14.0,
                                          color: audioTrack == _getTrackDescId(track) ? Colors.lightBlueAccent : Colors.black
                                      )),
                                    ),
                                  )
                                      .toList();
                                },
                              ),
                              PopupMenuButton(
                                iconSize: 24,
                                tooltip: "字幕轨道",
                                icon: Icon(Icons.subtitles, color: Colors.white),
                                onSelected: (String trackDesc) {
                                  if (trackDesc == "" || !trackDesc.contains(":")) return;
                                  var trackProps = trackDesc.split(":");
                                  var trackId = int.parse(trackProps[0]);
                                  player.setSpu(trackId);
                                },
                                itemBuilder: (context) {
                                  final spu = player.spu();
                                  return player.spuTrackDescription()
                                      .map(
                                        (track) => PopupMenuItem(
                                      child: Text(track,
                                          style: TextStyle(
                                              fontSize: 14.0,
                                              color: track.startsWith(spu.toString()) ? Colors.lightBlueAccent : Colors.black
                                          )),
                                      value: track,
                                    ),
                                  )
                                      .toList();
                                },
                              ),
                              // full screen
                              IconButton(
                                iconSize: 24,
                                icon: const Icon(Icons.fullscreen, color: Colors.white),
                                onPressed: _updateFullScreen,
                              ),
                            ],
                          )
                      );
                    },
                  ),

                ],
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: ElevatedButton(
                onPressed: () => open(r'https://ikaros.chivehao.ikaros.run/files/2024/8/26/87b163ca3842493bbded21389ef4c965.mkv', autoStart: true),  // 动态设置资源地址
                child: const Text("Load Video"),
              ),
            ),

          ],
        ),
      ),
    );
    return Scaffold(
      body: Stack(
        children: [
          Video(
            player: player,
            showControls: false,
          ),
          /// 下方UI
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => player.play(),
                ),
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () => player.pause(),
                ),
                IconButton(
                  color: Colors.white,
                  iconSize: 30,
                  icon: AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: playPauseController),
                  onPressed: () {
                    if (player.playback.isPlaying) {
                      player.pause();
                      playPauseController.reverse();
                    } else {
                      player.play();
                      playPauseController.forward();
                    }
                  },
                ),
                // 下方添加更多UI



              ],
            ),
          ),

          Positioned(
            top: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: () => open(r'https://ikaros.chivehao.ikaros.run/files/2024/8/26/87b163ca3842493bbded21389ef4c965.mkv', autoStart: true),  // 动态设置资源地址
              child: const Text("Load Video"),
            ),
          ),

        ],
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
          duration: Duration(milliseconds: 250),
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


void main() {
  runApp(const MaterialApp(
    home: DesktopVideoPlayer(),
  ));
}