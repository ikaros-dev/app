import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/api/subject/model/SubjectMeta.dart';
import 'package:ikaros/consts/subject_const.dart';
import 'package:ikaros/subject/subject.dart';
import 'package:ikaros/user/login.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/screen_utils.dart';
import 'package:ikaros/utils/url_utils.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return SubjectListState();
  }
}

class SubjectListState extends State<SubjectsPage> {
  List<SubjectMeta> subjectList = [];
  int _page = 1;
  int _size = 15;
  int _total = 0;

  bool _nsfw = false;
  SubjectType _type = SubjectType.ANIME;
  String _keyword = "";
  String _baseUrl = '';

  bool _hasMore = true;
  late EasyRefreshController _controller;

  List<SubjectMeta> _convertItems(List<Map<String, dynamic>> items) {
    return items.map((e) => SubjectMeta.fromJson(e)).toList();
  }

  _loadSubjects() async {
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

    if (kDebugMode) {
      print("load data for page=1 size=$_size nameCn=$_keyword, nsfw=$_nsfw");
    }
    PagingWrap pagingWrap = await SubjectApi()
        .listSubjectsByCondition(1, _size, '', _keyword, _nsfw, _type);
    _page = pagingWrap.page;
    _size = pagingWrap.size;
    _total = pagingWrap.total;
    if (mounted) {
      setState(() {
        subjectList = _convertItems(pagingWrap.items);
        _page = 2;
      });
    }
  }

  _loadMoreSubjects() async {
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
    if (kDebugMode) {
      print(
          "load more data for page=$_page size=$_size nameCn=$_keyword, nsfw=$_nsfw");
    }
    PagingWrap pagingWrap = await SubjectApi()
        .listSubjectsByCondition(_page, _size, '', _keyword, _nsfw, _type);
    _page = pagingWrap.page;
    _size = pagingWrap.size;
    _total = pagingWrap.total;
    if (mounted) {
      setState(() {
        subjectList.addAll(_convertItems(pagingWrap.items));
      });
    }
    _page++;
    // print("update page: $_page");
    if (kDebugMode) {
      print("length: ${subjectList.length} total: $_total");
    }
    if (subjectList.length >= _total) {
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
    _loadMoreSubjects();
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
        title: TextField(
          onSubmitted: (v) => {
            setState(() {
              _keyword = v;
              _loadSubjects();
            })
          },
          decoration: const InputDecoration(
            hintText: '输入条目中文名称搜索',
            border: InputBorder.none,
          ),
        ),
        actions: [
          Row(
            children: [
              const Text("类型", style: TextStyle(color: Colors.black)),
              const SizedBox(
                width: 5,
              ),
              DropdownButton(
                  value: _type,
                  items: SubjectType.values
                      .map((type) => DropdownMenuItem(
                          value: type,
                          child:
                              Text(SubjectConst.typeCnMap[type.name] ?? "未知")))
                      .toList(),
                  onChanged: (newType) {
                    if (newType == null) return;
                    setState(() {
                      _type = newType;
                    });
                    _loadSubjects();
                  }),
              // DropdownMenu(
              //   initialSelection: _type,
              //     dropdownMenuEntries: SubjectType.values
              // .map((type)=> DropdownMenuEntry(value: type, label: type.name)).toList(),
              //   onSelected: (newType){
              //     if (newType == null) return;
              //     setState(() {
              //       _type = newType;
              //     });
              //     _loadSubjects();
              //   },
              // ),

              const SizedBox(
                width: 10,
              ),
              const Text("NSFW", style: TextStyle(color: Colors.black)),
              Switch(
                  value: _nsfw,
                  onChanged: (v) => {
                        setState(() {
                          _nsfw = v; // 更新开关状态的变量
                          _loadSubjects();
                        })
                      }),
              // IconButton(
              //   icon: const Icon(Icons.search, color: Colors.black), // 设置搜索图标
              //   onPressed: () => setState(() {
              //     _loadSubjects();
              //   }),
              // ),
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
          await _loadMoreSubjects();
          if (!mounted) {
            return;
          }
          if (kDebugMode) {
            print("noMore: ${!_hasMore}");
          }
          _controller.finishLoad(success: true, noMore: !_hasMore);
          _controller.resetLoadState();
        },
        child: buildSubjectsGridView(),
      ),
    );
  }

  Future<void> _onSubjectCardTap(SubjectMeta subjectMeta) async {
    // SubjectApi().findById(subjectList[index].id).then(
    //         (value) => Navigator.of(context).push(MaterialPageRoute(
    //         builder: (context) => SubjectDetailsPage(
    //           subject: value,
    //         ))));
    int subjectId = subjectMeta.id;
    if (subjectId <= 0) {
      return;
    }

    // Subject subject = await SubjectApi().findById(subjectId);
    // SubjectCollection collection =
    //     await SubjectCollectionApi().findCollectionBySubjectId(subjectId);

    if (subjectMeta.type == SubjectType.ANIME ||
        subjectMeta.type == SubjectType.MUSIC ||
        subjectMeta.type == SubjectType.REAL) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => SubjectPage(
                id: subjectId.toString(),
              )));
    } else {
      Toast.show(context,
          "当前条目类型[${SubjectConst.typeCnMap[subjectMeta.type.name] ?? "未知"}]不支持视频播放");
    }
  }

  Widget buildSubjectsGridView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ScreenUtils.screenWidthGt600(context) ? 6 : 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
        childAspectRatio: 0.6, // 网格项的宽高比例
      ),
      itemCount: subjectList.length,
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
                  _onSubjectCardTap(subjectList[index]);
                },
                child: AspectRatio(
                  aspectRatio: 7 / 10, // 设置图片宽高比例
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0), // 设置圆角半径
                    child: Image.network(
                      UrlUtils.getCoverUrl(_baseUrl, subjectList[index].cover),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
              Expanded(
                  child: Text(
                ((subjectList[index].nameCn == null ||
                        subjectList[index].nameCn == '')
                    ? subjectList[index].name
                    : subjectList[index].nameCn)!,
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
