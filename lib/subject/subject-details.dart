import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:getwidget/getwidget.dart';
import 'package:fplayer/fplayer.dart';

import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/video/episode-video-item.dart';

class SubjectDetailsPage extends StatefulWidget {
  final Subject subject;

  const SubjectDetailsPage({super.key, required this.subject});

  @override
  State<StatefulWidget> createState() {
    return _SubjectDetailsView();
  }
}

class _SubjectDetailsView extends State<SubjectDetailsPage> {
  // final FijkPlayer player = FijkPlayer();
  final FPlayer player = FPlayer();
  List<EpisodeVideoItem> videoList = <EpisodeVideoItem>[];
  int videoIndex = 0;
  late String _baseUrl = '';
  late int _currentEpisodeId = 0;
  String _episodeTitle = '';
  String _videoTitle = '';

  // 播放传入的url
  Future<void> setVideoUrl(String url) async {
    try {
      await player.setDataSource(url, autoPlay: true, showCover: true);
    } catch (error) {
      Fluttertoast.showToast(
          msg: "Video play exception: $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      print("播放-异常: $error");
      return;
    }
  }

  Future _initVideoList() async {
    await _getBaseUrl();
    List<Episode>? episodes = widget.subject.episodes;
    if (episodes != null && episodes.isNotEmpty) {
      for (Episode episode in episodes) {
        String episodeTitle =
            "${episode.sequence}: ${(episode.nameCn != null && episode.nameCn != '') ? episode.nameCn! : episode.name}";
        if (episode.resources!.isNotEmpty) {
          EpisodeResource resource = episode.resources![0];
          String resourceName = resource.name;
          String url = _baseUrl + resource.url;
          EpisodeVideoItem videoItem =
              EpisodeVideoItem(episode.id, episode.subjectId, url: url, title: episodeTitle, subTitle: resourceName);
          setState(() {
            videoList.add(videoItem);
          });
        }
      }
    }
  }

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
      _episodeTitle =
          "${episode.sequence}: ${(episode.nameCn != null && episode.nameCn != '') ? episode.nameCn! : episode.name}";
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
    // _getFirstEpisodeResource().then((firstEpisodeResource) => {
    //       if (firstEpisodeResource.url != '')
    //         {
    //           player.setDataSource(firstEpisodeResource.url, autoPlay: true, showCover: true),
    //           _videoTitle = firstEpisodeResource.name
    //         }
    //       else
    //         {
    //           // Fluttertoast.showToast(
    //           //     msg:
    //           //         "Current subject not found first episode resource, nameCn: ${widget.subject.nameCn}, name: ${widget.subject.name}",
    //           //     toastLength: Toast.LENGTH_SHORT,
    //           //     gravity: ToastGravity.CENTER,
    //           //     timeInSecForIosWeb: 1,
    //           //     backgroundColor: Colors.red,
    //           //     textColor: Colors.white,
    //           //     fontSize: 16.0)
    //         }
    //     });
    _getFirstEpisodeResource().then((value) =>
        _initVideoList().then((value) => setVideoUrl(videoList[0].url)));
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
              child: FView(
                player: player,
                width: double.infinity,
                height: 200, // 需自行设置，此处宽度/高度=16/9
                color: Colors.black,
                fsFit: FFit.contain, // 全屏模式下的填充
                fit: FFit.fill, // 正常模式下的填充
                panelBuilder: fPanelBuilder(
                  title: _episodeTitle,
                  subTitle: _videoTitle,
                  // 视频列表开关
                  isVideos: true,
                  // 字幕按钮是否展示，fplayer字幕功能未实现，暂不显示
                  isCaption: false,
                  // 清晰度按钮是否展示
                  isResolution: false,
                  // 视频列表列表
                  videoList: videoList,
                  // 当前视频索引
                  videoIndex: videoIndex,
                  // 全屏模式下点击播放下一集视频回调
                  playNextVideoFun: () {
                    setState(() {
                      videoIndex += 1;
                      _currentEpisodeId = videoList[videoIndex].id;
                    });
                  },
                  // 视频播放完成回调
                  onVideoEnd: () async {
                    var index = videoIndex + 1;
                    if (index < videoList.length) {
                      await player.reset();
                      setState(() {
                        videoIndex = index;
                        _currentEpisodeId = videoList[videoIndex].id;
                      });
                      setVideoUrl(videoList[index].url);
                    }
                  },
                ),
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
                                ? Colors.lightBlueAccent
                                : Colors.blueAccent,
                            disabledColor: Colors.grey,
                            onPressed: episode.resources!.isEmpty
                                ? null
                                : () async {
                                    if (episode.resources!.isNotEmpty) {
                                      await player.reset();
                                      // await player.setDataSource(
                                      //     _baseUrl +
                                      //         episode.resources!.first.url,
                                      //     autoPlay: false);
                                      setState(() {
                                        _currentEpisodeId = episode.id;
                                        _videoTitle =
                                            "${episode.sequence}: ${(episode.nameCn != null ||
                                                    episode.nameCn != '')
                                                    ? episode.nameCn!
                                                    : episode.name}";
                                        _episodeTitle =
                                            episode.resources![0].name;
                                        print("video list: $videoList");
                                        videoIndex = videoList.indexOf(videoList
                                            .where((element) =>
                                                _episodeTitle ==
                                                element.subTitle)
                                            .first);
                                        print("videoIndex : $videoIndex");
                                        setVideoUrl(videoList[videoIndex].url);
                                      });
                                    }
                                  },
                            // text: episode == null ? "空" :
                            //     '${episode.sequence}: ${(episode.nameCn != null || episode.nameCn != '') ? episode.nameCn! : episode.name}',
                            text:
                                '${episode.sequence}: ${(episode.nameCn != null && episode.nameCn != '') ? episode.nameCn! : episode.name}',
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
