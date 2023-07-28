import 'dart:ffi';

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ikaros/api/subject/model/Subject.dart';

import 'api/auth/AuthApi.dart';
import 'api/auth/AuthParams.dart';
import 'api/subject/model/Episode.dart';
import 'api/subject/model/EpisodeResource.dart';

class FijkPlayerScreen extends StatefulWidget {
  final Subject subject;

  const FijkPlayerScreen({super.key, required this.subject});

  @override
  State<StatefulWidget> createState() {
    return _FijkPlayerScreen();
  }
}

class _FijkPlayerScreen extends State<FijkPlayerScreen> {
  final FijkPlayer player = FijkPlayer();
  late String _baseUrl = '';

  Future<Episode> _getFirstEpisode() async {
    return Future(() => Stream.fromIterable(widget.subject.episodes!)
    .where((e) => 1.0 == e.sequence)
    .first);
  }

  Future<String> getBaseUrl() async {
    if (_baseUrl == '') {
      AuthParams authParams = await AuthApi().getAuthParams();
      _baseUrl = authParams.baseUrl;
    }
    return _baseUrl;
  }

  Future<EpisodeResource> _getFirstEpisodeResource() async {
    Episode episode = await _getFirstEpisode();
    String baseUrl = await getBaseUrl();
    if (episode.resources!.isNotEmpty) {
      EpisodeResource episodeResource = episode.resources![0];
      episodeResource = EpisodeResource(
          fileId: episodeResource.fileId,
          episodeId: episodeResource.episodeId,
          url: baseUrl + episodeResource.url,
          // name: "${episode.sequence}: ${((episode.nameCn != null && episode.nameCn != '') ? episode.nameCn : episode.name)}"
          name: episodeResource.name);
      return episodeResource;
    } else {
      return Future(
          () => EpisodeResource(fileId: 0, episodeId: 0, url: '', name: ''));
    }
  }

  @override
  void initState() {
    super.initState();
    _getFirstEpisodeResource().then((firstEpisodeResource) => {
          if (firstEpisodeResource.url != '')
            {player.setDataSource(firstEpisodeResource.url, autoPlay: true)}
          else
            {
              Fluttertoast.showToast(
                  msg:
                      "Current subject not found first episode resource, nameCn: ${widget.subject.nameCn}, name: ${widget.subject.name}",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0)
            }
        });
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.subject.nameCn!),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: FijkView(player: player),
      ),
    );
  }
}
