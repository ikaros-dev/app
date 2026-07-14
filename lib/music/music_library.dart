import 'package:flutter/material.dart';
import 'package:ikaros/api/music/MusicApi.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/utils/screen_utils.dart';
import 'package:ikaros/subject/subject.dart';

/// 音乐库页面.
/// 展示专辑列表，点击进入专辑详情（歌曲列表 + 播放）.
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

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadAlbums();
    }
  }

  Future<void> _loadAlbums() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("音乐库")),
      body: _albums.isEmpty && !_isLoading
          ? const Center(child: Text("暂无专辑"))
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ScreenUtils.screenWidth(context) > 800 ? 4 : 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _albums.length + (_hasMore ? 1 : 0),
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
}

class _AlbumCard extends StatelessWidget {
  final Map<String, dynamic> album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = album["nameCn"] as String? ?? album["name"] as String? ?? "";
    final cover = album["cover"] as String? ?? "";
    final artist = album["name"] as String? ?? "";
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: cover.isNotEmpty
                  ? Image.network(cover, fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.music_note,
                            size: 48, color: Colors.white54),
                      ))
                  : Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(Icons.album,
                            size: 48, color: Colors.white54),
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
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12)),
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
          // 专辑头部
          _buildAlbumHeader(),
          // 歌曲列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                    ? const Center(child: Text("暂无歌曲"))
                    : ListView.builder(
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          return _SongTile(
                            song: song,
                            index: index,
                            onPlay: () => _playSong(index),
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
                  ? Image.network(widget.albumCover, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.album,
                            size: 40, color: Colors.white54))
                  )
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
                ElevatedButton.icon(
                  onPressed: _songs.isNotEmpty ? () => _playAll() : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("播放全部"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _playSong(int index) {
    final song = _songs[index];
    final songId = song["id"] as String? ?? "";
    final name = song["nameCn"] as String? ?? song["name"] as String? ?? "";

    // 跳转到条目详情页，使用已有播放器
    final subjectId = song["subjectId"] as String? ?? "";
    if (subjectId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubjectPage(id: subjectId),
        ),
      );
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
  final VoidCallback onPlay;

  const _SongTile({
    required this.song,
    required this.index,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final name = song["nameCn"] as String? ?? song["name"] as String? ?? "";
    final duration = song["duration"] as int? ?? 0;
    final sequence = song["sequence"] as int? ?? 0;

    String durationStr = "0:00";
    if (duration > 0) {
      final m = (duration ~/ 60).toString();
      final s = (duration % 60).toString().padLeft(2, '0');
      durationStr = "$m:$s";
    }

    return ListTile(
      leading: CircleAvatar(
        child: Text("${index + 1}", style: const TextStyle(fontSize: 14)),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: durationStr != "0:00" ? Text(durationStr) : null,
      trailing: IconButton(
        icon: const Icon(Icons.play_circle_outline),
        onPressed: onPlay,
      ),
      onTap: onPlay,
    );
  }
}
