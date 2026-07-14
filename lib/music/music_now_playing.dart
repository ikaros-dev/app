import 'dart:async';
import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:dart_vlc/dart_vlc.dart' as vlc;
import 'package:flutter/material.dart';
import 'package:ikaros/api/music/SubsonicApi.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放模式
enum _PlaybackMode { normal, repeatOne, repeatAll, shuffle }

/// 单曲模型（播放队列用）
class _QueueSong {
  final String id;
  final String subjectId;
  final String name;
  final String? nameCn;
  final String? cover;
  final int duration;
  final int sequence;
  String? streamUrl;

  _QueueSong({
    required this.id,
    required this.subjectId,
    required this.name,
    this.nameCn,
    this.cover,
    this.duration = 0,
    this.sequence = 0,
    this.streamUrl,
  });

  factory _QueueSong.fromApi(Map<String, dynamic> map) {
    return _QueueSong(
      id: map["id"] as String? ?? "",
      subjectId: map["subjectId"] as String? ?? "",
      name: map["name"] as String? ?? "",
      nameCn: map["nameCn"] as String?,
      cover: map["cover"] as String?,
      duration: map["duration"] as int? ?? 0,
      sequence: map["sequence"] as int? ?? 0,
    );
  }

  String get displayName => nameCn ?? name;
}

/// 正在播放页面（全屏桌面播放器）
class NowPlayingPage extends StatefulWidget {
  /// 播放队列
  final List<_QueueSong> queue;

  /// 从第几首开始播放
  final int startIndex;

  /// 专辑名称
  final String? albumName;

  /// 专辑封面
  final String? albumCover;

  const NowPlayingPage({
    super.key,
    required this.queue,
    required this.startIndex,
    this.albumName,
    this.albumCover,
  });

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  late vlc.Player _player;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isInitialized = false;
  _PlaybackMode _mode = _PlaybackMode.normal;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _lastUrl; // 避免重复打开

  // 打乱的索引
  List<int> _shuffledIndices = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex.clamp(0, widget.queue.length - 1);
    WidgetsFlutterBinding.ensureInitialized();
    vlc.DartVLC.initialize();
    _player = vlc.Player(id: hashCode);
    _player.positionStream.listen(_onPositionChanged);
    _player.playbackStream.listen(_onPlaybackChanged);
    _player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _initShuffle();
    _openCurrent();
    _saveNowPlaying();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _initShuffle() {
    _shuffledIndices =
        List.generate(widget.queue.length, (i) => i)..shuffle();
  }

  _QueueSong get _currentSong => widget.queue[_currentIndex];
  int get _queueSize => widget.queue.length;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inMinutes > 59 ? '${d.inHours}:${m}' : m}:$s";
  }

  void _onPositionChanged(vlc.PositionState state) {
    if (mounted) {
      setState(() {
        _position = state.position;
        _duration = state.duration;
      });
    }
  }

  void _onPlaybackChanged(vlc.PlaybackState state) {
    if (mounted) {
      setState(() => _isPlaying = state.isPlaying);

      // 播放完成自动切歌
      if (!state.isPlaying && state.isCompleted && _position >= _duration -
          const Duration(seconds: 2)) {
        _next();
      }
    }
  }

  Future<void> _openCurrent() async {
    final song = _currentSong;
    if (song.streamUrl == null || song.streamUrl!.isEmpty) {
      // 获取音频流地址
      try {
        final resources =
            await EpisodeApi().getEpisodeResourcesRefs(song.id);
        if (resources.isNotEmpty) {
          song.streamUrl = resources.first.url;
        }
      } catch (_) {}
      // 如果还是空，尝试 Subsonic API
      if ((song.streamUrl == null || song.streamUrl!.isEmpty)) {
        song.streamUrl = await SubsonicApi.getStreamUrl(song.id);
      }
    }

    final url = song.streamUrl;
    if (url == null || url.isEmpty) {
      if (mounted) Toast.show(context, "无法获取音频流: ${song.displayName}");
      return;
    }

    if (url == _lastUrl) return;
    _lastUrl = url;

    if (url.startsWith("http")) {
      _player.open(vlc.Media.network(url), autoStart: true);
    } else {
      _player.open(vlc.Media.file(File(url)), autoStart: true);
    }

    _saveNowPlaying();

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isPlaying = true;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }
  }

  Future<void> _saveNowPlaying() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("now_playing_song", _currentSong.displayName);
    await prefs.setString("now_playing_album",
        widget.albumName ?? _currentSong.subjectId);
    await prefs.setString(
        "now_playing_album_id", _currentSong.subjectId);
    await prefs.setString(
        "now_playing_cover", widget.albumCover ?? _currentSong.cover ?? "");
  }

  void _playPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _prev() {
    if (_position.inSeconds > 3) {
      // 超过3秒则重播当前
      _player.seek(Duration.zero);
      return;
    }
    _goToIndex(_getPrevIndex());
  }

  void _next() {
    _goToIndex(_getNextIndex());
  }

  int _getNextIndex() {
    switch (_mode) {
      case _PlaybackMode.repeatOne:
        return _currentIndex;
      case _PlaybackMode.shuffle:
        if (_shuffledIndices.isEmpty) _initShuffle();
        return _shuffledIndices.removeLast();
      case _PlaybackMode.repeatAll:
      case _PlaybackMode.normal:
        final next = _currentIndex + 1;
        if (next >= _queueSize) {
          return _mode == _PlaybackMode.repeatAll ? 0 : _currentIndex;
        }
        return next;
    }
  }

  int _getPrevIndex() {
    final prev = _currentIndex - 1;
    if (prev < 0) {
      return _mode == _PlaybackMode.repeatAll ? _queueSize - 1 : 0;
    }
    return prev;
  }

  void _goToIndex(int index) {
    if (index < 0 || index >= _queueSize) return;
    _lastUrl = null;
    _player.stop();
    setState(() => _currentIndex = index);
    _openCurrent();
  }

  void _toggleMode() {
    setState(() {
      _mode = _PlaybackMode.values[
          (_mode.index + 1) % _PlaybackMode.values.length];
      if (_mode == _PlaybackMode.shuffle) _initShuffle();
    });
  }

  IconData _modeIcon() {
    switch (_mode) {
      case _PlaybackMode.normal:
        return Icons.repeat;
      case _PlaybackMode.repeatOne:
        return Icons.repeat_one;
      case _PlaybackMode.repeatAll:
        return Icons.repeat_on;
      case _PlaybackMode.shuffle:
        return Icons.shuffle;
    }
  }

  String _modeTooltip() {
    switch (_mode) {
      case _PlaybackMode.normal:
        return "顺序播放";
      case _PlaybackMode.repeatOne:
        return "单曲循环";
      case _PlaybackMode.repeatAll:
        return "列表循环";
      case _PlaybackMode.shuffle:
        return "随机播放";
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = _currentSong;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName ?? "正在播放"),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: "播放队列",
            onPressed: _showQueue,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // 封面
              _buildCover(song),
              const SizedBox(height: 24),
              // 标题
              Text(
                song.displayName,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.albumName ?? "",
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // 进度条
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ProgressBar(
                  progress: _position,
                  total: _duration > Duration.zero ? _duration : null,
                  barHeight: 4,
                  thumbRadius: 8,
                  timeLabelLocation: TimeLabelLocation.sides,
                  timeLabelType: TimeLabelType.totalTime,
                  timeLabelTextStyle: const TextStyle(color: Colors.grey),
                  onSeek: (d) => _player.seek(d),
                ),
              ),
              const SizedBox(height: 24),
              // 控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 播放模式
                  IconButton(
                    icon: Icon(_modeIcon()),
                    tooltip: _modeTooltip(),
                    color: _mode == _PlaybackMode.normal ? null : Colors.blue,
                    iconSize: 24,
                    onPressed: _toggleMode,
                  ),
                  const SizedBox(width: 16),
                  // 上一首
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 36,
                    onPressed: _prev,
                  ),
                  const SizedBox(width: 8),
                  // 播放/暂停
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white),
                      iconSize: 40,
                      onPressed: _playPause,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 下一首
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 36,
                    onPressed: _next,
                  ),
                  const SizedBox(width: 16),
                  // 队列
                  IconButton(
                    icon: const Icon(Icons.queue_music_outlined),
                    iconSize: 24,
                    onPressed: _showQueue,
                  ),
                ],
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(_QueueSong song) {
    final cover = widget.albumCover ?? song.cover ?? "";
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 280,
        height: 280,
        child: cover.isNotEmpty
            ? Image.network(cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultCoverWidget())
            : _defaultCoverWidget(),
      ),
    );
  }

  Widget _defaultCoverWidget() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.music_note, size: 80, color: Colors.white54),
      ),
    );
  }

  void _showQueue() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 400,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text("播放队列",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Text("${_queueSize} 首",
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _queueSize,
                itemBuilder: (_, i) {
                  final q = widget.queue[i];
                  final isCurrent = i == _currentIndex;
                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor: Colors.blue.withOpacity(0.1),
                    leading: Text("${i + 1}",
                        style: TextStyle(
                            color: isCurrent ? Colors.blue : Colors.grey)),
                    title: Text(q.displayName,
                        style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.bold : null)),
                    subtitle: Text("${q.sequence}. ${q.subjectId}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: isCurrent
                        ? Icon(Icons.play_arrow,
                            color: Colors.blue, size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _goToIndex(i);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 便捷函数：创建 NowPlayingPage 并 push =====

/// 从专辑数据创建播放页面并导航
Future<void> pushNowPlaying(
    BuildContext context,
    List<Map<String, dynamic>> songs,
    {int startIndex = 0,
    String? albumName,
    String? albumCover}) async {
  if (songs.isEmpty) return;

  final queue = songs.map((s) => _QueueSong.fromApi(s)).toList();
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NowPlayingPage(
        queue: queue,
        startIndex: startIndex,
        albumName: albumName,
        albumCover: albumCover,
      ),
    ),
  );
}
