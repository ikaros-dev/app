import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fplayer/fplayer.dart';
import 'package:getwidget/getwidget.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/consts/tmp-const.dart';
import 'package:ikaros/video/IkarosFplayerPanel.dart';
import 'package:ikaros/video/vlc_player_with_controls.dart';

class SubjectDetailsPage extends StatefulWidget {
  final Subject subject;

  const SubjectDetailsPage({super.key, required this.subject});

  @override
  State<StatefulWidget> createState() {
    return _SubjectDetailsView();
  }
}

class _SubjectDetailsView extends State<SubjectDetailsPage> {
  late VlcPlayerWithControls _vlcPlayerWithControls;
  List<IkarosVideoItem> videoList = <IkarosVideoItem>[];
  int videoIndex = 0;
  late String _baseUrl = '';
  late int _currentEpisodeId = 0;
  String _resourceSubtitleUrl = '';
  String _episodeTitle = '';
  String _videoTitle = '';
  bool isFullScreen = false;

  _updateIsFullScreen(bool val) {
    setState(() {
      isFullScreen = val;
    });
  }

  // 播放传入的url
  Future<void> setVideoUrl(String url) async {
    try {
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
          IkarosVideoItem videoItem = IkarosVideoItem(
              id: episode.id,
              subjectId: episode.subjectId,
              url: url,
              title: episodeTitle,
              subTitle: resourceName);
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
      _videoTitle =
          "${episode.sequence}: ${(episode.nameCn != null || episode.nameCn != '') ? episode.nameCn! : episode.name}";
    });
    String baseUrl = await _getBaseUrl();
    if (episode.resources!.isNotEmpty) {
      EpisodeResource episodeResource = episode.resources![0];
      if (episodeResource.subtitleUrl != null &&
          episodeResource.subtitleUrl != '') {
        _resourceSubtitleUrl = episodeResource.subtitleUrl!;
      }
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
  void initState()  {
    super.initState();

    _getBaseUrl();

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
    // _getFirstEpisodeResource().then((value) =>
    //     _initVideoList().then((value) => setVideoUrl(videoList[0].url)));
    _vlcPlayerWithControls = VlcPlayerWithControls(
      videoUrl: TmpConst.H265_URL,
      updateIsFullScreen: (val) => _updateIsFullScreen(val),
    );
    _vlcPlayerWithControls.addSubtitle(TmpConst.H265_CHS_ASS_URL);

    // _getFirstEpisodeResource()
    //     .then((value) => _initVideoList().then((value) => {
    //           _videoPlayerController.stop(),
    //           _videoPlayerController.setMediaFromNetwork(
    //             videoList[0].url,
    //             hwAcc: HwAcc.full,
    //             autoPlay: true
    //           )
    //         }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(MediaQuery.of(context).size.height * 0.07),
        child: Visibility(
          visible: !isFullScreen,
          child: AppBar(
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
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: isFullScreen ? MediaQuery.of(context).size.height : 200,
              child: _vlcPlayerWithControls,
            ),
            Visibility(
              visible: !isFullScreen,
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "选集",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ),
            Visibility(
              visible: !isFullScreen,
              child: GFItemsCarousel(
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
                                        // await player.setDataSource(
                                        //     _baseUrl +
                                        //         episode.resources!.first.url,
                                        //     autoPlay: false);
                                        setState(() {
                                          _currentEpisodeId = episode.id;
                                          _videoTitle =
                                              "${episode.sequence}: ${(episode.nameCn != null || episode.nameCn != '') ? episode.nameCn! : episode.name}";
                                          _episodeTitle =
                                              episode.resources![0].name;
                                          if (episode.resources != null &&
                                              episode.resources!.isEmpty) {
                                            _resourceSubtitleUrl = episode
                                                .resources![0].subtitleUrl!;
                                          }
                                          print("video list: $videoList");
                                          videoIndex = videoList.indexOf(
                                              videoList
                                                  .where((element) =>
                                                      _episodeTitle ==
                                                      element.subTitle)
                                                  .first);
                                          print("videoIndex : $videoIndex");
                                          setVideoUrl(
                                              videoList[videoIndex].url);
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
            ),
            Visibility(
              visible: !isFullScreen,
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "简介",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ),
            Visibility(
              visible: !isFullScreen,
              child: Column(
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
            ),
          ],
        ),
      ),
    );
  }
}
