import 'dart:async';
import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:dart_vlc/dart_vlc.dart' as vlc;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/api/dio_client.dart';
import 'package:ikaros/api/music/SubsonicApi.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/component/lyrics_widget.dart';
import 'package:ikaros/utils/lyrics_parser.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放模式
enum _PlaybackMode { normal, repeatOne, repeatAll, shuffle }

/// 单曲模型
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

/// 正在播放页面
class NowPlayingPage extends StatefulWidget {
  final List<_QueueSong> queue;
  final int startIndex;
  final String? albumName;
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
  String? _lastUrl;

  // 歌词
  ParsedLyrics? _lyrics;
  bool _loadLyricsDone = false;
  bool _showLyrics = false;
  LyricsOrientation _lyricsOrientation = LyricsOrientation.vertical;

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

  double get _positionMs =>
      _position.inMilliseconds.toDouble();

  void _onPositionChanged(vlc.PositionState state) {
    if (mounted) {
      setState(() {
        _position = state.position ?? Duration.zero;
        _duration = state.duration ?? Duration.zero;
      });
    }
  }

  void _onPlaybackChanged(vlc.PlaybackState state) {
    if (mounted) {
      setState(() => _isPlaying = state.isPlaying);
      if (!state.isPlaying &&
          state.isCompleted &&
          _position >= _duration - const Duration(seconds: 2)) {
        _next();
      }
    }
  }

  Future<void> _openCurrent() async {
    final song = _currentSong;
    if (song.streamUrl == null || song.streamUrl!.isEmpty) {
      try {
        final resources =
            await EpisodeApi().getEpisodeResourcesRefs(song.id);
        if (resources.isNotEmpty) song.streamUrl = resources.first.url;
      } catch (_) {}
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

    // 加载歌词
    _loadLyrics();

    _saveNowPlaying();

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isPlaying = true;
        _position = Duration.zero;
        _duration = Duration.zero;
        _loadLyricsDone = false;
      });
    }
  }

  /// 加载歌词（从附件资源或固定的 lrc 文件名匹配）
  Future<void> _loadLyrics() async {
    _lyrics = null;
    _loadLyricsDone = false;
    try {
      final resources =
          await EpisodeApi().getEpisodeResourcesRefs(_currentSong.id);
      final lrcResource = resources.where((r) =>
          r.name.endsWith('.lrc') ||
          r.name.endsWith('.txt') ||
          (r.tags != null && r.tags!.contains('lyrics'))).toList();

      if (lrcResource.isNotEmpty) {
        final url = lrcResource.first.url;
        if (url.isNotEmpty) {
          final dio = await DioClient.getDio();
          final response = await dio.get(url,
              options: Options(
                responseType: ResponseType.plain,
              ));
          if (response.statusCode == 200 && response.data is String) {
            final parsed = LyricsParser.parse(response.data as String);
            if (mounted && parsed.lines.isNotEmpty) {
              setState(() {
                _lyrics = parsed;
                _loadLyricsDone = true;
              });
            }
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadLyricsDone = true);
  }

  Future<void> _saveNowPlaying() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("now_playing_song", _currentSong.displayName);
    await prefs.setString(
        "now_playing_album", widget.albumName ?? _currentSong.subjectId);
    await prefs.setString("now_playing_album_id", _currentSong.subjectId);
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
      _player.seek(Duration.zero);
      return;
    }
    _goToIndex(_getPrevIndex());
  }

  void _next() => _goToIndex(_getNextIndex());

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
    return prev < 0
        ? (_mode == _PlaybackMode.repeatAll ? _queueSize - 1 : 0)
        : prev;
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

  @override
  Widget build(BuildContext context) {
    final song = _currentSong;
    final hasLyrics = _lyrics != null && _lyrics!.lines.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName ?? "正在播放"),
        actions: [
          // 歌词切换
          if (hasLyrics)
            IconButton(
              icon: Icon(
                _showLyrics ? Icons.lyrics : Icons.lyrics_outlined,
                color: _showLyrics ? Colors.blue : null,
              ),
              tooltip: _showLyrics ? "隐藏歌词" : "显示歌词",
              onPressed: () {
                setState(() => _showLyrics = !_showLyrics);
                if (_showLyrics) _loadLyrics();
              },
            ),
          if (_showLyrics)
            IconButton(
              icon: Icon(
                _lyricsOrientation == LyricsOrientation.vertical
                    ? Icons.view_column
                    : Icons.view_carousel,
              ),
              tooltip: _lyricsOrientation == LyricsOrientation.vertical
                  ? "横排歌词" : "竖排歌词",
              onPressed: () {
                setState(() {
                  _lyricsOrientation =
                      _lyricsOrientation == LyricsOrientation.vertical
                          ? LyricsOrientation.horizontal
                          : LyricsOrientation.vertical;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: "播放队列",
            onPressed: _showQueue,
          ),
        ],
      ),
      body: _showLyrics && hasLyrics
          ? _buildWithLyrics()
          : _buildPlayerContent(),
    );
  }

  /// 带歌词的播放界面
  Widget _buildWithLyrics() {
    return Column(
      children: [
        // 上方：小封面 + 歌曲信息
        if (_lyricsOrientation == LyricsOrientation.vertical)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _buildCover(_currentSong),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentSong.displayName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(widget.albumName ?? "",
                          style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // 歌词区域
        Expanded(
          child: _lyrics == null
              ? const Center(child: CircularProgressIndicator())
              : LyricsWidget(
                  lyrics: _lyrics!,
                  positionMs: _positionMs,
                  orientation: _lyricsOrientation,
                  textColor: Colors.white38,
                  highlightColor: Colors.blue,
                  sungColor: Colors.white,
                  fontSize: 16,
                ),
        ),
        // 控制栏
        _buildPlayerControls(),
        _buildChapterProgress(),
      ],
    );
  }

  /// 无歌词的播放界面
  Widget _buildPlayerContent() {
    final song = _currentSong;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            _buildCover(song),
            const SizedBox(height: 24),
            Text(song.displayName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(widget.albumName ?? "",
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center),
            const Spacer(flex: 1),
            _buildPlayerControls(),
            _buildChapterProgress(),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Column(
      children: [
        // 进度条
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ProgressBar(
            progress: _position,
            total: _duration,
            barHeight: 4,
            thumbRadius: 8,
            timeLabelLocation: TimeLabelLocation.sides,
            timeLabelType: TimeLabelType.totalTime,
            timeLabelTextStyle: const TextStyle(color: Colors.grey),
            onSeek: (d) => _player.seek(d),
          ),
        ),
        const SizedBox(height: 16),
        // 控制按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_modeIcon()),
              tooltip: _modeName(),
              color: _mode == _PlaybackMode.normal ? null : Colors.blue,
              iconSize: 24,
              onPressed: _toggleMode,
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 36,
              onPressed: _prev,
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white),
                iconSize: 40,
                onPressed: _playPause,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 36,
              onPressed: _next,
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.queue_music_outlined),
              iconSize: 24,
              onPressed: _showQueue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChapterProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentIndex > 0)
            TextButton.icon(
              onPressed: _prev,
              icon: const Icon(Icons.skip_previous, size: 18),
              label: Text("上一首",
                  style: const TextStyle(fontSize: 13)),
            )
          else
            const SizedBox(width: 80),
          Text("${_currentIndex + 1} / ${_queueSize}",
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (_currentIndex < _queueSize - 1)
            TextButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.skip_next, size: 18),
              label: Text("下一首",
                  style: const TextStyle(fontSize: 13)),
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  String _modeName() {
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
                  Text("$_queueSize 首",
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
                            fontWeight: isCurrent ? FontWeight.bold : null)),
                    subtitle: Text("第 ${q.sequence} 首",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: isCurrent
                        ? const Icon(Icons.play_arrow,
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

// ===== 便捷函数 =====

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
