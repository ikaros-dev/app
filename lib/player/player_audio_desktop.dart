import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';

class DesktopAudioPlayer extends StatefulWidget {
  const DesktopAudioPlayer({super.key});

  @override
  State<StatefulWidget> createState() {
    return DesktopAudioPlayerState();
  }
}

class DesktopAudioPlayerState extends State<DesktopAudioPlayer> {
  late Player _player;
  late String _audioUrl = "";
  late String _coverUrl = "";
  late String _title = "";
  bool _isPlaying = false;

  void setCoverUrl(String url) {
    _coverUrl = url;
  }

  void setTitle(String title) {
    _title = title;
  }

  void open(String audioUrl, {autoStart = false}) {
    _audioUrl = audioUrl;
    _loadAlbumArt();
    _player.open(Media.network(audioUrl), autoStart: autoStart);
  }

  void reload(String audioUrl, {autoStart = false}) {
    _audioUrl = audioUrl;
    _loadAlbumArt();
    _player.stop();
    _player.open(Media.network(audioUrl), autoStart: autoStart);
  }

  Future<void> _loadAlbumArt() async {
    // TODO read cover and author form audio url.
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    WidgetsFlutterBinding.ensureInitialized();

    DartVLC.initialize();
    _player = Player(id: hashCode * 2);
    _player.playbackStream.listen((state) {
      setState(() {
        _isPlaying = state.isPlaying;
      });
    });
  }

  @override
  void dispose() {
    _player.stop();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCoverWidget(),
        Text(_title),
        // Text(_tag.artwork ?? "未知"),
        // 播放器的进度条
        StreamBuilder<PositionState>(
          stream: _player.positionStream,
          builder:
              (BuildContext context, AsyncSnapshot<PositionState> snapshot) {
            final durationState = snapshot.data;
            final progress = durationState?.position ?? Duration.zero;
            final total = durationState?.duration ?? Duration.zero;
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
                timeLabelTextStyle: const TextStyle(color: Colors.black),
                onSeek: (duration) {
                  _player.seek(duration);
                },
              ),
            );
          },
        ),

        // 播放/暂停按钮
        StreamBuilder<PlaybackState>(
          stream: _player.playbackStream,
          builder: (context, snapshot) {
            final PlaybackState state = snapshot.data ?? PlaybackState();
            return IconButton(
              icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
            );
          },
        ),
      ],
    );
  }
}
