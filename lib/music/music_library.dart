import 'package:flutter/material.dart';
import 'package:ikaros/api/music/MusicApi.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/subject/subject.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/screen_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 音乐库页面.
/// 展示专辑列表，支持搜索和上下滑动加载更多.
class MusicLibraryPage extends StatefulWidget {
  const MusicLibraryPage({super.key});

  @override
  State<MusicLibraryPage> createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage> {
  final MusicApi _musicApi = MusicApi();
  List<Map<String, dynamic>> _albums = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _page = 1;
  final int _size = 20;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // 当前播放信息（通过 SubjectPage 播放时保存）
  String? _currentSongId;
  String? _currentSongName;
  String? _currentAlbumName;
  String? _currentAlbumId;
  String? _currentAlbumCover;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _scrollController.addListener(_onScroll);
    _restoreNowPlaying();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _restoreNowPlaying() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentSongName = prefs.getString("now_playing_song");
      _currentAlbumName = prefs.getString("now_playing_album");
      _currentAlbumId = prefs.getString("now_playing_album_id");
      _currentAlbumCover = prefs.getString("now_playing_cover");
    });
  }

  Future<void> _saveNowPlaying(Map<String, dynamic> song) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("now_playing_song", song["nameCn"] ?? song["name"] ?? "");
    await prefs.setString("now_playing_album", "正在播放");
    await prefs.setString("now_playing_album_id", song["subjectId"] ?? "");
    await prefs.setString("now_playing_cover", song["cover"] ?? song["albumCover"] ?? "");
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadAlbums();
    }
  }

  Future<void> _loadAlbums({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (refresh) {
        _page = 1;
        _albums.clear();
      }
      var result = await _musicApi.listAlbums(page: _page, size: _size);
      List<dynamic> items = result["items"] ?? [];
      int total = result["total"] ?? 0;
      setState(() {
        _albums.addAll(items.cast<Map<String, dynamic>>());
        _hasMore = _albums.length < total;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) Toast.show(context, "加载专辑失败: $e");
    }
  }

  Future<void> _search(String keyword) async {
    if (keyword.isEmpty) {
      _loadAlbums(refresh: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      var result = await _musicApi.searchAlbums(keyword, 1, 50);
      List<dynamic> items = result["items"] ?? [];
      setState(() {
        _albums = items.cast<Map<String, dynamic>>();
        _hasMore = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "搜索专辑...",
                  border: InputBorder.none,
                ),
                onSubmitted: (v) => _search(v),
              )
            : const Text("音乐库"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadAlbums(refresh: true);
                }
              });
            },
          ),
          if (_albums.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadAlbums(refresh: true),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAlbums(refresh: true),
        child: _albums.isEmpty && !_isLoading
            ? const Center(child: Text("暂无专辑"))
            : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      ScreenUtils.isDesktop(context) ? 5 : 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _albums.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _albums.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final album = _albums[index];
                  return _AlbumCard(
                    album: album,
                    onTap: () => _openAlbum(album),
                  );
                },
              ),
      ),
      // 底部现在播放指示条
      bottomSheet: _currentSongName != null ? _buildNowPlayingBar() : null,
    );
  }

  void _openAlbum(Map<String, dynamic> album) {
    final albumId = album["id"] as String? ?? "";
    final name = album["nameCn"] as String? ?? album["name"] as String? ?? "";
    final cover = album["cover"] as String? ?? "";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MusicAlbumDetailPage(
          albumId: albumId,
          albumName: name,
          albumCover: cover,
        ),
      ),
    );
  }

  Widget _buildNowPlayingBar() {
    return Container(
      height: 56,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9),
      child: ListTile(
        leading: _currentAlbumCover != null && _currentAlbumCover!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(_currentAlbumCover!,
                    width: 40, height: 40, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.music_note)),
              )
            : const Icon(Icons.music_note, size: 40),
        title: Text(_currentSongName ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(_currentAlbumName ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                if (_currentAlbumId != null && _currentAlbumId!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectPage(id: _currentAlbumId!),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _currentSongName = null),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Map<String, dynamic> album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name =
        album["nameCn"] as String? ?? album["name"] as String? ?? "";
    final cover = album["cover"] as String? ?? "";
    final artist = album["name"] as String? ?? "";
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: cover.isNotEmpty
                  ? Image.network(cover,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.music_note,
                              size: 48, color: Colors.white54)))
                  : Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child:
                            Icon(Icons.album, size: 48, color: Colors.white54),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (artist.isNotEmpty)
                    Text(artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 专辑详情页（歌曲列表 + 播放）.
class MusicAlbumDetailPage extends StatefulWidget {
  final String albumId;
  final String albumName;
  final String albumCover;

  const MusicAlbumDetailPage({
    super.key,
    required this.albumId,
    required this.albumName,
    required this.albumCover,
  });

  @override
  State<MusicAlbumDetailPage> createState() => _MusicAlbumDetailPageState();
}

class _MusicAlbumDetailPageState extends State<MusicAlbumDetailPage> {
  final MusicApi _musicApi = MusicApi();
  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      var songs = await _musicApi.listSongs(widget.albumId);
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.albumName)),
      body: Column(
        children: [
          _buildAlbumHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                    ? const Center(child: Text("暂无歌曲"))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          return _SongTile(
                            song: song,
                            index: index,
                            albumName: widget.albumName,
                            albumCover: widget.albumCover,
                          );
                        }),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 100,
              height: 100,
              child: widget.albumCover.isNotEmpty
                  ? Image.network(widget.albumCover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[800],
                          child: const Icon(
                              Icons.album, size: 40, color: Colors.white54)))
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.album,
                          size: 40, color: Colors.white54),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.albumName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("${_songs.length} 首歌曲",
                    style: TextStyle(color: Colors.grey[500])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          _songs.isNotEmpty ? () => _playAll() : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("播放全部"),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed:
                          _songs.isNotEmpty ? () => _playAll() : null,
                      icon: const Icon(Icons.shuffle),
                      label: const Text("随机播放"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _playSong(int index) {
    if (index >= _songs.length) return;
    final song = _songs[index];
    final songId = song["id"] as String? ?? "";
    final name = song["nameCn"] as String? ?? song["name"] as String? ?? "";
    final subjectId = song["subjectId"] as String? ?? "";

    // 保存播放信息
    final prefsKey = "now_playing_song";
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(prefsKey, name);
      prefs.setString("now_playing_album", widget.albumName);
      prefs.setString("now_playing_album_id", subjectId);
      prefs.setString("now_playing_cover", widget.albumCover);
    });

    if (subjectId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubjectPage(id: subjectId),
        ),
      );
    } else {
      Toast.show(context, "播放: $name");
    }
  }

  void _playAll() {
    if (_songs.isEmpty) return;
    _playSong(0);
  }
}

class _SongTile extends StatelessWidget {
  final Map<String, dynamic> song;
  final int index;
  final String albumName;
  final String albumCover;

  const _SongTile({
    required this.song,
    required this.index,
    required this.albumName,
    required this.albumCover,
  });

  @override
  Widget build(BuildContext context) {
    final name = song["nameCn"] as String? ?? song["name"] as String? ?? "";
    final duration = song["duration"] as int? ?? 0;

    String durationStr = "0:00";
    if (duration > 0) {
      final m = (duration ~/ 60).toString();
      final s = (duration % 60).toString().padLeft(2, '0');
      durationStr = "$m:$s";
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text("${index + 1}",
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimaryContainer)),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: durationStr != "0:00" ? Text(durationStr) : null,
      trailing: IconButton(
        icon: const Icon(Icons.play_circle_outline),
        color: Theme.of(context).colorScheme.primary,
        onPressed: () {
          // 直接调用父级方法
          final parent = context.findAncestorStateOfType<_MusicAlbumDetailPageState>();
          parent?._playSong(index);
        },
      ),
      onTap: () {
        final parent = context.findAncestorStateOfType<_MusicAlbumDetailPageState>();
        parent?._playSong(index);
      },
    );
  }
}
