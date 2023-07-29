import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:getwidget/getwidget.dart';
import 'package:ikaros/api/subject/model/Subject.dart';

import 'api/auth/AuthApi.dart';
import 'api/auth/AuthParams.dart';
import 'api/subject/model/Episode.dart';
import 'api/subject/model/EpisodeResource.dart';

class SubjectDetailsView extends StatefulWidget {
  final Subject subject;

  const SubjectDetailsView({super.key, required this.subject});

  @override
  State<StatefulWidget> createState() {
    return _SubjectDetailsView();
  }
}

class _SubjectDetailsView extends State<SubjectDetailsView> {
  final FijkPlayer player = FijkPlayer();
  late String _baseUrl = '';
  late int _currentEpisodeId = 0;

  Future<Episode> _getFirstEpisode() async {
    return Future(() => Stream.fromIterable(widget.subject.episodes!)
        .where((e) => 1.0 == e.sequence)
        .first);
  }

  Future<String> _getBaseUrl() async {
    if (_baseUrl == '') {
      AuthParams authParams = await AuthApi().getAuthParams();
      _baseUrl = authParams.baseUrl;
    }
    return _baseUrl;
  }

  Future<EpisodeResource> _getFirstEpisodeResource() async {
    Episode episode = await _getFirstEpisode();
    setState(() {
      _currentEpisodeId = episode.id;
    });
    String baseUrl = await _getBaseUrl();
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
        iconTheme: const IconThemeData(
          color: Colors.black, //change your color here
        ),
        backgroundColor: Colors.white,

        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(
          (widget.subject.nameCn != null && widget.subject.nameCn != '')
              ? widget.subject.nameCn!
              : widget.subject.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.black, backgroundColor: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: FijkView(
                player: player,
                color: Colors.black87,
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "选集",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            GFItemsCarousel(
                rowCount: 3,
                itemHeight: 50,
                children: widget.subject.episodes!
                    .map(
                      (episode) => Container(
                          height: 50,
                          margin: const EdgeInsets.all(5.0),
                          child: GFButton(
                            color: episode.id == _currentEpisodeId
                                ? Colors.blueGrey
                                : Colors.grey,
                            onPressed: () async {
                              if (episode.resources!.isNotEmpty) {
                                await player.reset();
                                await player.setDataSource(
                                    _baseUrl + episode.resources!.first.url,
                                    autoPlay: true);
                                setState(() {
                                  _currentEpisodeId = episode.id;
                                });
                              }
                            },
                            // text: episode == null ? "空" :
                            //     '${episode.sequence}: ${(episode.nameCn != null || episode.nameCn != '') ? episode.nameCn! : episode.name}',
                            text: '${episode.sequence}: ${(episode.nameCn != null && episode.nameCn != '') ? episode.nameCn! : episode.name}',
                          )),
                    )
                    .toList()),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "简介",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: AspectRatio(
                        aspectRatio: 7 / 10, // 设置图片宽高比例
                        child: FutureBuilder(
                          future: Future.delayed(Duration.zero, _getBaseUrl),
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              if (snapshot.hasError) {
                                return Text(
                                    "Load subject cover: ${snapshot.error}");
                              } else {
                                return Image.network(
                                  _baseUrl + widget.subject.cover,
                                  fit: BoxFit.fitWidth,
                                );
                              }
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        direction: Axis.vertical,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: [
                          // const Text("类型", style: TextStyle(fontWeight: FontWeight.bold),),
                          // Text(widget.subject.type.toString(), overflow: TextOverflow.ellipsis,),
                          const Text(
                            "名称",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.subject.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            "中文名称",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(widget.subject.nameCn!,
                              overflow: TextOverflow.ellipsis),
                          const Text(
                            "NSFW",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(widget.subject.nsfw == true ? "是" : "否",
                              overflow: TextOverflow.ellipsis),
                          const Text(
                            "剧集总数",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("${widget.subject.totalEpisodes}",
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Wrap(
                      direction: Axis.vertical,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        const Text(
                          "简介",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          width: 400,
                          child: Text(
                            widget.subject.summary!,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
