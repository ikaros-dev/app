import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:getwidget/getwidget.dart';
import 'package:ikaros/api/attachment/AttachmentRelationApi.dart';
import 'package:ikaros/api/attachment/model/VideoSubtitle.dart';
import 'package:ikaros/api/collection/SubjectCollectionApi.dart';
import 'package:ikaros/api/collection/enums/CollectionType.dart';
import 'package:ikaros/api/collection/model/SubjectCollection.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/api/subject/model/Video.dart';
import 'package:ikaros/consts/collection-const.dart';
import 'package:ikaros/subject/subjects.dart';
import 'package:ikaros/utils/url_utils.dart';
import 'package:ikaros/video/vlc_player_with_controls.dart';

class SubjectDetailsPage extends StatefulWidget {
  final String apiBaseUrl;
  final Subject subject;
  final SubjectCollection collection;

  const SubjectDetailsPage(
      {super.key,
        required this.apiBaseUrl,
        required this.subject,
        required this.collection});

  @override
  State<StatefulWidget> createState() {
    return _SubjectDetailsView();
  }
}

class _SubjectDetailsView extends State<SubjectDetailsPage> {
  late SubjectCollection _subjectCollection;
  late CollectionType _collectionType;

  List<Video> videoList = <Video>[];
  late int _currentEpisodeId = 0;
  bool isFullScreen = false;

  // String _videoUrl = TmpConst.H265_URL;
  String _videoUrl = "http://";

  // List<String> _videoSubtitleUrls = [TmpConst.H265_CHS_ASS_URL];
  List<String> _videoSubtitleUrls = [];
  String _videoTitle = '';
  String _episodeTitle = '';

  late GlobalKey<VlcPlayerWithControlsState> _childKey;

  late Function _onPlayerInitialized;
  bool _isPlayerInitializedCallOnce = false;

  _updateIsFullScreen(bool val) {
    isFullScreen = val;
  }

  Future callChildMethod2ChangePlayerDatasource() async {
    final childState = _childKey.currentState;
    if (childState != null) {
      await childState.changeDatasource(_currentEpisodeId, _videoUrl,
          _videoSubtitleUrls, _videoTitle, _episodeTitle);
    } else {
      print("child state is null");
    }
  }

  // 播放传入的url
  Future setVideoUrl() async {
    try {
      print("update video url: $_videoUrl");
      await callChildMethod2ChangePlayerDatasource();
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
    }
  }

  Future _initVideoList() async {
    if (videoList.isNotEmpty) {
      return;
    }
    List<Episode>? episodes = widget.subject.episodes;
    if (episodes != null && episodes.isNotEmpty) {
      for (Episode episode in episodes) {
        String episodeTitle =
            "${episode.sequence}: ${(episode.nameCn != null && episode.nameCn != '') ? episode.nameCn! : episode.name}";
        if (episode.resources!.isNotEmpty) {
          EpisodeResource resource = episode.resources![0];
          String resourceName = resource.name;
          String url = widget.apiBaseUrl + resource.url;
          List<VideoSubtitle> videoSubtitles = await AttachmentRelationApi()
              .findByAttachmentId(resource.attachmentId);
          List<String> subtitleUrls = [];
          for (var element in videoSubtitles) {
            var subUrl = widget.apiBaseUrl + element.url;
            subtitleUrls.add(subUrl);
          }

          Video video = Video(
              episodeId: episode.id,
              subjectId: episode.subjectId,
              url: url,
              title: episodeTitle,
              subhead: resourceName,
              subtitleUrls: subtitleUrls);
          if (mounted) {
            setState(() {
              videoList.add(video);
            });
          }
        }
      }
    }
    return;
  }

  Future<Episode> _getFirstEpisode() async {
    return Stream.fromIterable(widget.subject.episodes!)
        .where((e) => 1 == e.sequence)
        .where((e) => "MAIN" == e.group)
        .first;
  }

  Future<Episode> _loadEpisode(Episode episode) async {
    setState(() {
      _currentEpisodeId = episode.id;
    });
    print(
        "[episode] sequence: ${episode.sequence}, nameCn: ${episode.nameCn}, name: ${episode.name}");
    _videoTitle =
    "${episode.sequence}: ${(episode.nameCn != null && episode.nameCn != '') ? episode.nameCn! : episode.name}";
    print("episode video title: $_videoTitle");
    EpisodeResource episodeResource = episode.resources![0];
    _episodeTitle = episodeResource.name;
    print("episode title: $_videoTitle");
    if (episodeResource.url.startsWith("http")) {
      _videoUrl = episodeResource.url;
    } else {
      _videoUrl = widget.apiBaseUrl + episodeResource.url;
    }
    print("episode resource video url: $_videoUrl");
    if (episode.resources != null && episode.resources!.isNotEmpty) {
      List<VideoSubtitle> videoSubtitles = await AttachmentRelationApi()
          .findByAttachmentId(episode.resources![0].attachmentId);
      List<String> subtitleUrls = [];
      for (var element in videoSubtitles) {
        var subUrl = '';
        if (element.url.startsWith("http")) {
          subUrl = element.url;
        } else {
          subUrl = widget.apiBaseUrl + episodeResource.url;
        }
        subtitleUrls.add(subUrl);
      }
      _videoSubtitleUrls = subtitleUrls;
      print("video subtitle urls: $_videoSubtitleUrls");
    }
    await setVideoUrl();
    return episode;
  }

  @override
  void initState() {
    super.initState();

    _subjectCollection = widget.collection;
    _collectionType = _subjectCollection.type;
    _childKey = GlobalKey<VlcPlayerWithControlsState>();

    // _getBaseUrl();
    _initVideoList();

    _onPlayerInitialized = () async {
      if (!_isPlayerInitializedCallOnce) {
        // await _getBaseUrl();
        await _initVideoList();
        // Episode episode = await _getFirstEpisode();
        // await _loadEpisode(episode);
        _isPlayerInitializedCallOnce = true;
      }
    };
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
    //     _initVideoList().then((value) => setVideoUrl(videoList[0].url, [])));

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
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: isFullScreen ? MediaQuery.of(context).size.height : 200,
              child: VlcPlayerWithControls(
                key: _childKey,
                updateIsFullScreen: (val) => _updateIsFullScreen(val),
                onPlayerInitialized: _onPlayerInitialized, videoUrl: _videoUrl, videoTitle: _videoTitle, episodeId: _currentEpisodeId,
              ),
              // child: FutureBuilder(
              //     future: Future.delayed(Duration.zero, _loadFirstVideoEpisode),
              //     builder: (BuildContext context, AsyncSnapshot snapshot) {
              //       if (snapshot.connectionState ==
              //           ConnectionState.done) {
              //         if (snapshot.hasError) {
              //           return Text(
              //               "Load video error: ${snapshot.error}");
              //         } else {
              //           return VlcPlayerWithControls(
              //             videoUrl: _videoUrl,
              //             updateIsFullScreen: (val) =>
              //                 _updateIsFullScreen(val),
              //           );
              //         }
              //       } else {
              //         return const Center(
              //           child: CircularProgressIndicator(),
              //         );
              //       }
              //     })
            ),
            Visibility(
              visible: !isFullScreen,
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "正片",
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
                      .where((element) =>
                  element.group == null || element.group == 'MAIN')
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
                              setState(() {
                                _loadEpisode(episode);
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
                  "OP&ED&PV&其它",
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
                      .where((element) =>
                  element.group != null && element.group != 'MAIN')
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
                                _loadEpisode(episode);
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
                          child: Image.network(
                            UrlUtils.getCoverUrl(widget.apiBaseUrl, widget.subject.cover),
                            fit: BoxFit.fitWidth,
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
                            width: 350,
                            child: Text(
                                widget.subject.summary!
                            ),
                          )
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

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.07),
      child: Visibility(
        visible: !isFullScreen,
        child: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.black, //change your color here
          ),
          backgroundColor: Colors.white,
          title: Text(
            (widget.subject.nameCn != null && widget.subject.nameCn != '')
                ? widget.subject.nameCn!
                : widget.subject.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.black, backgroundColor: Colors.white),
          ),
          actions: [_buildAppBarCollection()],
        ),
      ),
    );
  }

  Row _buildAppBarCollection() {
    return Row(
      children: [
        GFButton(
          onPressed: (_subjectCollection.id != -1)
              ? () async {
            // 取消收藏
            await SubjectCollectionApi()
                .removeCollection(widget.subject.id);
            Fluttertoast.showToast(
                msg: "取消收藏成功",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0);
            if (mounted) {
              setState(() {
                _loadSubjectCollection();
              });
            }
          }
              : () async {
            await _updateSubjectCollection();
            Fluttertoast.showToast(
                msg: "收藏成功",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0);
            setState(() {
              _loadSubjectCollection();
            });
          },
          text: (_subjectCollection.id != -1) ? '取消收藏' : '收藏',
          textColor: Colors.black,
          // disabledColor: Colors.grey,
          color: Colors.white70,
          boxShadow: const BoxShadow(),
        ),
        Container(
          width: 10,
        ),
        DropdownButton(
          borderRadius: BorderRadius.circular(5),
          value: _collectionType,
          onChanged: (_subjectCollection.id != -1)
              ? (newValue) async {
            if (mounted) {
              setState(() {
                _collectionType = (newValue as CollectionType?)!;
              });
            }
            await _updateSubjectCollection();
          }
              : null,
          items: [
            CollectionType.WISH,
            CollectionType.DOING,
            CollectionType.DONE,
            CollectionType.SHELVE,
            CollectionType.DISCARD,
          ]
              .map((value) => DropdownMenuItem(
            value: value,
            child: Text(CollectionConst.typeCnMap[value.name]!),
          ))
              .toList(),
        ),
      ],
    );
  }

  Future<String> _loadSubjectCollection() async {
    _subjectCollection = await SubjectCollectionApi()
        .findCollectionBySubjectId(widget.subject.id);
    _collectionType = _subjectCollection.type;
    return "";
  }

  _updateSubjectCollection() async {
    await SubjectCollectionApi()
        .updateCollection(widget.subject.id, _collectionType, null);
  }
}
