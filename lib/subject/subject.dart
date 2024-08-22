import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/enums/CollectionType.dart';
import 'package:ikaros/api/collection/model/SubjectCollection.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/consts/subject_const.dart';
import 'package:ikaros/utils/url-utils.dart';

import 'episode.dart';

class SubjectPage extends StatefulWidget {
  final String? id;

  const SubjectPage({super.key, required this.id});

  @override
  State<StatefulWidget> createState() {
    return _SubjectState();
  }
}

class _SubjectState extends State<SubjectPage> {
  late String _apiBaseUrl;
  late Subject _subject;
  late SubjectCollection _subjectCollection;
  late CollectionType _collectionType;

  var _loadSubjectWithIdFuture;
  var _loadApiBaseUrlFuture;

  Future<Subject> _loadSubjectWithId() async {
    return SubjectApi().findById(int.parse(widget.id.toString()));
  }

  Future<AuthParams> _loadBaseUrl() async {
    return AuthApi().getAuthParams();
  }

  @override
  void initState() {
    super.initState();
    _loadSubjectWithIdFuture = _loadSubjectWithId();
    _loadApiBaseUrlFuture = _loadBaseUrl();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: "Back",
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [_buildLinkIconButton()],
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<Subject>(
            future: _loadSubjectWithIdFuture,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Text("Load video error: ${snapshot.error}");
                } else {
                  _subject = snapshot.data;

                  return Column(
                    children: [
                      _buildSubjectDisplayRow(),
                      _buildEpisodeAndCollectionButtonsRow(),
                      _buildDetailsRow(),
                    ],
                  );
                }
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            }),
      ),
    );
  }

  Widget _buildLinkIconButton() {
    return IconButton(
        onPressed: () async {
          if (_apiBaseUrl == "") {
            _apiBaseUrl = (await _loadBaseUrl()).baseUrl;
          }
          var url =
              "$_apiBaseUrl/console/#/subjects/subject/details/${widget.id}";
          // if (await canLaunchUrl(Uri.parse(url))) {
          //   await launchUrl(Uri.parse(url));
          // } else {
          //   throw 'Could not launch $url';
          // }
        },
        icon: const Icon(
          Icons.ac_unit_sharp,
          color: Colors.black,
        ));
  }

  Text _buildSubjectTitle() {
    var name = (_subject.nameCn != null && _subject.nameCn != '')
        ? _subject.nameCn!
        : _subject.name;
    return Text(
      name,
      overflow: TextOverflow.ellipsis,
      style:
          const TextStyle(color: Colors.black, backgroundColor: Colors.white),
    );
  }

  Row _buildSubjectDisplayRow() {
    return Row(
      children: [
        // 左边封面图片
        Column(
          children: [_buildSubjectCover()],
        ),
        const SizedBox(width: 10),
        // 右边标题
        Expanded(
          child: _buildSubjectTitleInfo(),
        )
      ],
    );
  }

  Widget _buildSubjectCover() {
    return FutureBuilder<AuthParams>(
        future: _loadApiBaseUrlFuture,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text("Load api base url error: ${snapshot.error}");
            } else {
              _apiBaseUrl = (snapshot.data as AuthParams).baseUrl;
              return SizedBox(
                  width: 120,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: AspectRatio(
                      aspectRatio: 7 / 10, // 设置图片宽高比例
                      child: Image.network(
                        UrlUtils.getCoverUrl(_apiBaseUrl, _subject.cover),
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ));
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  Widget _buildSubjectTitleInfo() {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        // const Text("类型", style: TextStyle(fontWeight: FontWeight.bold),),
        // Text(_subject.type.toString(), overflow: TextOverflow.ellipsis,),
        const Text(
          "名称",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          _subject.name,
          overflow: TextOverflow.ellipsis,
        ),
        const Text(
          "中文名称",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(_subject.nameCn!, overflow: TextOverflow.ellipsis),
        const Text(
          "NSFW",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(_subject.nsfw == true ? "是" : "否",
            overflow: TextOverflow.ellipsis),
        const Text(
          "剧集总数",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("${_subject.totalEpisodes}", overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Future<bool?> showEpisodesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("选集播放"),
          content: _buildEpisodeSelectTabs(),
          actions: <Widget>[
            // TextButton(
            //   child: Text("确认"),
            //   onPressed: () {
            //     //关闭对话框并返回true
            //     Navigator.of(context).pop(true);
            //   },
            // ),
            // TextButton(
            //   child: const Text("取消"),
            //   onPressed: () => Navigator.of(context).pop(), // 关闭对话框
            // ),
          ],
        );
      },
    );
  }

  Row _buildEpisodeAndCollectionButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        MaterialButton(
          onPressed: () async {
            bool? cancel = await showEpisodesDialog();
            // ignore: unnecessary_null_comparison
            if (cancel == null) {
              print("返回");
            } else {
              print("确认");
            }
          },
          shape: const RoundedRectangleBorder(
            side: BorderSide(
              color: Colors.deepPurple,
              width: 1,
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(8),
            ),
          ),
          child: const Text("选集"),
        ),
        const SizedBox(width: 2),
        const MaterialButton(
          onPressed: null,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Colors.deepPurple,
              width: 1,
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(8),
            ),
          ),
          child: Text("收藏"),
        )
      ],
    );
  }

  Row _buildDetailsRow() {
    return Row(
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
              child: Text(_subject.summary!),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildEpisodeSelectTabs() {
    var groups = _getEpisodeGroups();
    var len = 0;
    if (groups != null) len = groups.length;
    if (len == 0) return Container();
    return DefaultTabController(
        length: len,
        child: Column(
          children: [
            Material(
              //这里设置tab的背景色
              child: _buildEpisodeSelectTabBar(),
            ),
            Expanded(flex: 1, child: _buildEpisodeSelectTabView()),
          ],
        ));
  }

  List<String?>? _getEpisodeGroups() {
    if (_subject.episodes == null) return <String>[];
    var groupSet = _subject.episodes?.map((e) => e.group).toSet();
    var groupList = groupSet?.toList();
    groupList?.sort((a, b) => a.hashCode.compareTo(b.hashCode));
    return groupList;
  }

  Widget _buildEpisodeSelectTabBar() {
    var groups = _getEpisodeGroups();
    var tabs = groups
        ?.map((g) =>
            Text(key: Key(g.toString()), SubjectConst.episodeGroupCnMap[g]!))
        .map((text) => Tab(
              key: text.key,
              child: text,
            ))
        .toList();
    if (tabs == null) return const TabBar(tabs: []);
    return TabBar(tabs: tabs);
  }

  List<Episode>? _getEpisodesByGroup(String group) {
    if (_subject.episodes == null) return [];
    var episodes = _subject.episodes?.where((ep) => ep.group == group).toList();
    episodes?.sort((me, ot) => me.sequence.compareTo(ot.sequence));
    return episodes;
  }

  Widget _getEpisodesTabViewByGroup(String group) {
    var buttons = _getEpisodesByGroup(group)
        ?.map((ep) => Container(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: SizedBox(
                height: 40,
                child: MaterialButton(
                  onPressed: () => {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SubjectEpisodePage(
                              id: ep.id.toString(),
                            )))
                  },
                  shape: const RoundedRectangleBorder(
                    side: BorderSide(
                      color: Colors.deepPurple,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    "${ep.sequence} : ${ep.name}",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ))
        .toList();

    if (buttons == null) return Container();

    return ListView(
      children: buttons,
    );
    return SingleChildScrollView(
      child: Wrap(
        children: buttons,
      ),
      // child: Column(
      //   key: Key(group),
      //   crossAxisAlignment: CrossAxisAlignment.center,
      //   children: [
      //     Wrap(
      //       children: buttons,
      //     )
      //   ],
      // ),
    );
  }

  TabBarView _buildEpisodeSelectTabView() {
    var groups = _getEpisodeGroups();
    var tabViews =
        groups?.map((g) => _getEpisodesTabViewByGroup(g.toString())).toList();
    if (tabViews == null) {
      return const TabBarView(
        children: [],
      );
    }
    return TabBarView(
      children: tabViews,
    );
  }
}
