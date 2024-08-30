import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/collection/enums/CollectionType.dart';
import 'package:ikaros/api/collection/model/SubjectCollection.dart';
import 'package:ikaros/api/collection/SubjectCollectionApi.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/model/Subject.dart';
import 'package:ikaros/consts/collection-const.dart';
import 'package:ikaros/subject/subject.dart';
import 'package:ikaros/user/login.dart';
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

  List<SubjectCollection> _convertItems(List<Map<String, dynamic>> items) {
    return items.map((e) => SubjectCollection.fromJson(e)).toList();
  }

  _loadSubjectCollections() async {
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
    _loadMoreSubjectCollections();
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
      body: EasyRefresh(
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
      ),
    );
  }

  Future<void> _onSubjectCardTap(int subjectId) async {
    if (subjectId <= 0) {
      return;
    }

    Subject subject = await SubjectApi().findById(subjectId);
    SubjectCollection? collection =
        await SubjectCollectionApi().findCollectionBySubjectId(subjectId);

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SubjectPage(
              id: subjectId.toString(),
            )));
  }

  Widget buildSubjectCollectionsGridView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ScreenUtils.screenWidthGt600(context) ? 6 : 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
        childAspectRatio: 0.6, // 网格项的宽高比例
      ),
      itemCount: subjectCollections.length,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // 设置圆角半径
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () {
                  _onSubjectCardTap(subjectCollections[index].subjectId);
                },
                child: AspectRatio(
                  aspectRatio: 7 / 10, // 设置图片宽高比例
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0), // 设置圆角半径
                    child: Image.network(
                      UrlUtils.getCoverUrl(
                          _baseUrl, subjectCollections[index].cover),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
              Expanded(child: Text(
                ((subjectCollections[index].nameCn == null ||
                    subjectCollections[index].nameCn == '')
                    ? subjectCollections[index].name
                    : subjectCollections[index].nameCn)!,
                maxLines: 2,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              )),
            ],
          ),
        );
      },
    );
  }
}
