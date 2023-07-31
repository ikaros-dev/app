import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:ikaros/LoginView.dart';
import 'package:ikaros/SubjectDetailsView.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/api/subject/model/Subject.dart';

const cover =
    "http://nas:9999/files/2023/7/6/b17a4329e4c148bca28602dbae9f9727.jpg";

class SubjectListView extends StatefulWidget {
  const SubjectListView({super.key});

  @override
  State<StatefulWidget> createState() {
    return SubjectListState();
  }
}

class SubjectListState extends State<SubjectListView> {
  List<Subject> subjectList = [];
  int _page = 1;
  int _size = 15;
  int _total = 0;

  bool _nsfw = false;
  String _keyword = "";
  String _baseUrl = '';

  bool _hasMore = true;
  late EasyRefreshController _controller;

  List<Subject> _convertItems(List<Map<String, dynamic>> items) {
    return items.map((e) => Subject.fromJson(e)).toList();
  }

  _loadSubjects() async {
    if (_baseUrl == '') {
      AuthParams authParams = await AuthApi().getAuthParams();
      if (authParams.baseUrl == '') {
        if(mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LoginView()));
        }
      } else {
        _baseUrl = authParams.baseUrl;
      }
    }
    // Fluttertoast.showToast(
    //     msg: "Load data action! keyword: $keyword , nsfw: $nsfw",
    //     toastLength: Toast.LENGTH_SHORT,
    //     gravity: ToastGravity.CENTER,
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: Colors.red,
    //     textColor: Colors.white,
    //     fontSize: 16.0);

    print(
        "load data for page=1 size=$_size nameCn=$_keyword, nsfw=$_nsfw");
    PagingWrap pagingWrap = await SubjectApi().listSubjectsByCondition(
        1, _size, '', _keyword, _nsfw, SubjectType.ANIME);
    _page = pagingWrap.page;
    _size = pagingWrap.size;
    _total = pagingWrap.total;
    if(mounted) {
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
        if(mounted) {
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
    print(
        "load more data for page=$_page size=$_size nameCn=$_keyword, nsfw=$_nsfw");
    PagingWrap pagingWrap = await SubjectApi().listSubjectsByCondition(
        _page, _size, '', _keyword, _nsfw, SubjectType.ANIME);
    _page = pagingWrap.page;
    _size = pagingWrap.size;
    _total = pagingWrap.total;
    if(mounted) {
      setState(() {
        subjectList.addAll(_convertItems(pagingWrap.items));
      });
    }
    _page++;
    // print("update page: $_page");
    print("length: ${subjectList.length} total: $_total");
    if (subjectList.length >= _total) {
      if(mounted) {
        setState(() {
          _hasMore = false;
        });
      }
    }
  }

  Widget _getMoreWidget() {
    // 如果还有数据
    if (_hasMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                '加载中',
                style: TextStyle(fontSize: 16.0),
              ),
              // 加载图标
              CircularProgressIndicator(
                strokeWidth: 1.0,
              )
            ],
          ),
        ),
      );
    } else {
      return const Center(
        child: Text("...没有更多了..."),
      );
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
          showInfo: false
        ),
        onLoad: () async {
          // await Future.delayed(const Duration(seconds: 4));
          await _loadMoreSubjects();
          if (!mounted) {
            return;
          }
          print("noMore: ${!_hasMore}");
          _controller.finishLoad(success: true, noMore: !_hasMore);
          _controller.resetLoadState();
        },
        child: buildSubjectsGridView(),
      ),
    );
  }

  Widget buildSubjectsGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
        childAspectRatio: 0.6, // 网格项的宽高比例
      ),
      itemCount: subjectList.length,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SubjectDetailsView(subject: subjectList[index])));
              },
              child: AspectRatio(
                aspectRatio: 7 / 10, // 设置图片宽高比例
                child: Image.network(
                  _baseUrl + subjectList[index].cover,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                ((subjectList[index].nameCn == null ||
                        subjectList[index].nameCn == '')
                    ? subjectList[index].name
                    : subjectList[index].nameCn)!,
                style: const TextStyle(
                    fontSize: 14.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
