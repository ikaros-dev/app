import 'package:flutter/material.dart';
import 'package:ikaros/FijkPlayerScreen.dart';
import 'package:ikaros/VideoPlayerScreen.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/video/widget/video_player_page.dart';

class SubjectDetailsView extends StatefulWidget {
  const SubjectDetailsView({super.key});

  @override
  State<StatefulWidget> createState() {
    return SubjectDetailsState();
  }
}

class SubjectDetailsState extends State<SubjectDetailsView> {
  late Subject _subject;
  late String _baseUrl = '';
  late EpisodeResource _episodeResource;

  Future<String> getBaseUrl() async {
    if (_baseUrl == '') {
      AuthParams authParams = await AuthApi().getAuthParams();
      _baseUrl = authParams.baseUrl;
    }
    return _baseUrl;
  }

  Future<EpisodeResource> _getFirstEpisodeResource() async {
    if (_subject.episodes!.isNotEmpty &&
        _subject.episodes![0].resources!.isNotEmpty) {
      Episode episode = _subject.episodes![0];
      EpisodeResource episodeResource = episode.resources![0];
      String baseUrl = await getBaseUrl();
      episodeResource = EpisodeResource(
          fileId: episodeResource.fileId,
          episodeId: episodeResource.episodeId,
          url: baseUrl + episodeResource.url,
          name: (_subject.nameCn != null && _subject.nameCn != '')
              ? _subject.nameCn!
              : _subject.name);
      return episodeResource;
    }
    return EpisodeResource(fileId: 0, episodeId: 0, url: '', name: '');
  }

  void loadFirstEpisodeResource() async {
    _episodeResource = await _getFirstEpisodeResource();
  }

  @override
  Widget build(BuildContext context) {
    _subject = ModalRoute.of(context)?.settings.arguments as Subject;
    return Scaffold(
        body: FutureBuilder(
      future: Future.delayed(Duration.zero, loadFirstEpisodeResource),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text(
                "get first episode resource list fail: ${snapshot.error}");
          } else {
            // return VideoPlayerScreen(episodeResource: _episodeResource);
            // return VideoPlayerPage(subject: _subject);
            return FijkPlayerScreen(subject: _subject);
          }
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    ));
  }
}
