import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MobileAudioPlayer extends StatefulWidget {
  const MobileAudioPlayer({super.key});

  @override
  State<StatefulWidget> createState() {
    return MobileAudioPlayerState();
  }
}

class MobileAudioPlayerState extends State<MobileAudioPlayer> {
  late AudioPlayer _player;
  late String _audioUrl = "";
  late String _coverUrl = "";
  late String _title = "";
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isBuffering = true;

  void setCoverUrl(String url) {
    setState(() {
      _coverUrl = url;
    });
  }

  void setTitle(String title) {
    setState(() {
      _title = title;
    });
  }

  Future<void> open(String audioUrl, {bool autoStart: false}) async {
    setState(() {
      _audioUrl = audioUrl;
    });
    await _loadAlbumArt();

    _player.setUrl(audioUrl);
    _player.play();
  }

  Future<void> _loadAlbumArt() async {
    // TODO read cover and author form audio url.
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    WidgetsFlutterBinding.ensureInitialized();

    _player = AudioPlayer();
    _player.positionStream.listen((position) {
      setState(() {
        _position = position ?? Duration.zero;
      });
    });
    _player.durationStream.listen((duration) {
      setState(() {
        _duration = duration ?? Duration.zero;
      });
    });
    _player.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        _isBuffering = state.processingState != ProcessingState.ready;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Widget _buildCoverWidget() {
    if (_coverUrl == "") {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Image.network(_coverUrl);
  }

  Widget _buildPlayOrPauseBtn() {
    if (_isBuffering) {
      return const SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return IconButton(
      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 30,),
      onPressed: _togglePlayPause,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCoverWidget(),
        Text(_title),
        // Text(_tag.artwork ?? "未知"),
        // 播放器的进度条
        ProgressBar(
          progress: _position,
          total: _duration,
          barHeight: 3,
          thumbRadius: 10.0,
          thumbGlowRadius: 30.0,
          timeLabelLocation: TimeLabelLocation.sides,
          timeLabelType: TimeLabelType.totalTime,
          timeLabelTextStyle: const TextStyle(color: Colors.black),
          onSeek: (duration) {
            _player.seek(duration);
          },
        ),

          // 播放/暂停按钮
        _buildPlayOrPauseBtn(),

      ],
    );
  }
}
