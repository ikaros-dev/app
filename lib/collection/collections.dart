import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/enums/CollectionType.dart';
import 'package:ikaros/api/collection/model/SubjectCollection.dart';
import 'package:ikaros/api/collection/SubjectCollectionApi.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/component/full_screen_Image.dart';
import 'package:ikaros/component/subject/subject.dart';
import 'package:ikaros/consts/collection-const.dart';
import 'package:ikaros/consts/subject_const.dart';
import 'package:ikaros/subject/subject.dart';
import 'package:ikaros/user/login.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/screen_utils.dart';
import 'package:ikaros/utils/url_utils.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return CollectionsState();
  }
}

class CollectionsState extends State<CollectionPage> {
  List<SubjectCollection> subjectCollections = [];
  int _page = 1;
  int _size = 15;
  int _total = 0;
  String _baseUrl = '';
  CollectionType? _type = CollectionType.DOING;

  bool _hasMore = true;
  late EasyRefreshController _controller;
  bool _isCollectionsLoading = false;

  List<SubjectCollection> _convertItems(List<Map<String, dynamic>> items) {
    return items.map((e) => SubjectCollection.fromJson(e)).toList();
  }

  _loadSubjectCollections() async {
    setState(() {
      _isCollectionsLoading = true;
    });
    if (_baseUrl == '') {
      AuthParams authParams = await AuthApi().getAuthParams();
      if (authParams.baseUrl == '') {
        if (mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LoginView()));
        }
      } else {
        _baseUrl = authParams.baseUrl;
      }
    }

    print("load data for page=1 size=$_size type=$_type");
    PagingWrap? pagingWrap =
        await SubjectCollectionApi().fetchSubjectCollections(1, _size, _type);
    _page = pagingWrap?.page ?? 0;
    _size = pagingWrap?.size ?? 0;
    _total = pagingWrap?.total ?? 0;
    if (mounted) {
      setState(() {
        subjectCollections = _convertItems(pagingWrap?.items ?? List.empty());
        _page = 2;
      });
    }
    setState(() {
      _isCollectionsLoading = false;
    });
  }

  _loadMoreSubjectCollections() async {
    if (_baseUrl == '') {
      AuthParams authParams = await AuthApi().getAuthParams();
      if (authParams.baseUrl == '') {
        if (mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LoginView()));
        }
        return;
      } else {
        _baseUrl = authParams.baseUrl;
      }
    }
    if (!_hasMore) {
      return;
    }
    print("load data for page=1 size=$_size type=$_type");
    PagingWrap? pagingWrap = await SubjectCollectionApi()
        .fetchSubjectCollections(_page, _size, _type);
    _page = pagingWrap?.page ?? 0;
    _size = pagingWrap?.size ?? 0;
    _total = pagingWrap?.total ?? 0;
    if (mounted) {
      setState(() {
        subjectCollections
            .addAll(_convertItems(pagingWrap?.items ?? List.empty()));
      });
    }
    _page++;
    // print("update page: $_page");
    print("length: ${subjectCollections.length} total: $_total");
    if (subjectCollections.length >= _total) {
      if (mounted) {
        setState(() {
          _hasMore = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSubjectCollections();
    _controller = EasyRefreshController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text(
          "收藏",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          Row(
            children: [
              DropdownButton(
                // padding: const EdgeInsets.all(15),
                borderRadius: BorderRadius.circular(5),
                value: _type,
                onChanged: (newValue) {
                  setState(() {
                    _type = newValue;
                    _hasMore = true;
                    _loadSubjectCollections();
                  });
                },
                items: [
                  null,
                  CollectionType.WISH,
                  CollectionType.DOING,
                  CollectionType.DONE,
                  CollectionType.SHELVE,
                  CollectionType.DISCARD,
                ]
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(CollectionConst
                              .typeCnMap[value == null ? 'ALL' : value.name]!),
                          // child: Text(value == null ? 'ALL' : value.name),
                        ))
                    .toList(),
              ),
            ],
          )
        ],
      ),
      body: _buildEasyRefresh(),
    );
  }

  Widget _buildEasyRefresh() {
    if (_isCollectionsLoading) return const LinearProgressIndicator();
    return EasyRefresh(
      controller: _controller,
      footer: ClassicalFooter(
          loadingText: "加载中...",
          loadFailedText: "加载失败",
          loadReadyText: "加载就绪",
          loadedText: "已全部加载",
          noMoreText: "没有更多了",
          showInfo: false),
      onLoad: () async {
        // await Future.delayed(const Duration(seconds: 4));
        await _loadMoreSubjectCollections();
        if (!mounted) {
          return;
        }
        print("noMore: ${!_hasMore}");
        _controller.finishLoad(success: true, noMore: !_hasMore);
        _controller.resetLoadState();
      },
      child: buildSubjectCollectionsGridView(),
    );
  }

  Future<void> _onSubjectCardTap(int subjectId) async {
    if (subjectId <= 0) {
      return;
    }

    Subject subject = await SubjectApi().findById(subjectId);
    // SubjectCollection? collection =
    //     await SubjectCollectionApi().findCollectionBySubjectId(subjectId);

    if (subject.type == SubjectType.ANIME ||
        subject.type == SubjectType.MUSIC ||
        subject.type == SubjectType.REAL) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => SubjectPage(
                id: subjectId.toString(),
              )));
    } else {
      Toast.show(context,
          "当前条目类型[${SubjectConst.typeCnMap[subject.type.name] ?? "未知"}]不支持视频播放");
    }
  }

  Widget buildSubjectCollectionsGridView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ScreenUtils.screenWidthGt600(context) ? 6 : 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
        childAspectRatio: 0.55, // 网格项的宽高比例
      ),
      itemCount: subjectCollections.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            SubjectCover(
              url: UrlUtils.getCoverUrl(_baseUrl, subjectCollections[index].cover),
              nsfw: subjectCollections[index].nsfw,
              onTap: (){
                _onSubjectCardTap(subjectCollections[index].subjectId);
              },
            ),
            Flexible(
                child: Text(
                  ((subjectCollections[index].nameCn == null ||
                      subjectCollections[index].nameCn == '')
                      ? subjectCollections[index].name
                      : subjectCollections[index].nameCn)!,
                  maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                )),
          ],
        );


        return GestureDetector(
          onTap: () {
            _onSubjectCardTap(subjectCollections[index].subjectId);
          },
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImagePage(
                  imageUrl: UrlUtils.getCoverUrl(
                      _baseUrl, subjectCollections[index].cover), // 替换为你的图片URL
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 7 / 10,
                child: Stack(
                  children: [
                    Hero(
                      tag: UrlUtils.getCoverUrl(
                          _baseUrl, subjectCollections[index].cover),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5.0), // 设置圆角半径
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/loading_placeholder.jpg',
                          // 占位图片
                          image: UrlUtils.getCoverUrl(
                              _baseUrl, subjectCollections[index].cover),
                          imageErrorBuilder: (context, error, stackTrace) {
                            // 如果图片加载失败，显示错误占位图
                            return const Text("图片加载失败");
                            // return Image.asset('assets/error_placeholder.png', fit: BoxFit.fitWidth);
                          },
                          fadeInDuration: const Duration(milliseconds: 500),
                          fit: BoxFit.cover,
                          // height: 200,
                          width: double.infinity,
                          // UrlUtils.getCoverUrl(_baseUrl, subjectList[index].cover),
                          // fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    if (subjectCollections[index].nsfw)
                      Positioned(
                        top: 8,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 2, right: 2, top: 2, bottom: 1),
                          decoration: const BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                              topRight: Radius.circular(0),
                              bottomRight: Radius.circular(0),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'NSFW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Flexible(
                  child: Text(
                ((subjectCollections[index].nameCn == null ||
                        subjectCollections[index].nameCn == '')
                    ? subjectCollections[index].name
                    : subjectCollections[index].nameCn)!,
                maxLines: 2,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              )),
            ],
          ),
        );
      },
    );
  }
}
