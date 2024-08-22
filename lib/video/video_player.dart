import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/video/video_player_controller.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoPlayerController player;
  final Function? onFullScreen;
  final Function? onPlayerInitialized;

  const VideoPlayerScreen({super.key, this.onPlayerInitialized, this.onFullScreen, required this.player});

  @override
  State<StatefulWidget> createState() {
    return _VideoPlayerScreenState();
  }
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _player;
  bool _showControls = true;
  bool _isFullScreen = false;

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      widget.onFullScreen?.call();
    });
  }

  void _updateFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }


  @override
  void initState() {
    super.initState();
    _player = widget.player;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: _toggleControls, // 点击视频时显示或隐藏控制层
            child: Center(
              // child: _player.isInitialized
              //     ? AspectRatio(
              //         aspectRatio: _player.aspectRatio,
              //         child: _player.buildVideoPlayerWidget(),
              //       )
              //     : const CircularProgressIndicator(), // 视频未加载完成前显示加载指示器
              child: AspectRatio(
                aspectRatio: _player.aspectRatio,
                child: _player.buildVideoPlayerWidget(),
              ),
            ),
          ),
          _showControls ? _buildControls() : Container(), // 显示或隐藏控制层
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _player.isPlaying ? _player.pause() : _player.play();
          });
        },
        child: Icon(
          _player.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.black54, // 半透明背景
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ProgressBar(
              progress: _player.position,
              total: _player.duration,
            ), // 进度条
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    _player.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _player.isPlaying ? _player.pause() : _player.play();
                    });
                  },
                ),
                Text(
                  "${_player.position.inMinutes}:${(_player.position.inSeconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: () {
                    // 全屏按钮的逻辑
                    _updateFullScreen();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
