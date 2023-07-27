import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ikaros/SubjectDetailsView.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/api/subject/model/Subject.dart';

const cover =
    "http://nas:9999/files/2023/7/6/b17a4329e4c148bca28602dbae9f9727.jpg";
// const cover = "https://lain.bgm.tv/r/400/pic/cover/l/5a/24/441233_nJ7Do.jpg";

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
  int _size = 12;
  int _total = 0;

  bool _nsfw = false;
  String _keyword = "";
  String _baseUrl = '';

  List<Subject> _convertItems(List<Map<String, dynamic>> items) {
    return items.map((e) => Subject.fromJson(e)).toList();
  }

  _loadSubjects() async {
    // Fluttertoast.showToast(
    //     msg: "Load data action! keyword: $keyword , nsfw: $nsfw",
    //     toastLength: Toast.LENGTH_SHORT,
    //     gravity: ToastGravity.CENTER,
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: Colors.red,
    //     textColor: Colors.white,
    //     fontSize: 16.0);

    print("load data for page=$_page size=$_size nameCn=$_keyword, nsfw=$_nsfw");
    PagingWrap pagingWrap = await SubjectApi().listSubjectsByCondition(
        _page, _size, '', _keyword, _nsfw, SubjectType.ANIME);
    _page = pagingWrap.page;
    _size = pagingWrap.size;
    _total = pagingWrap.total;
    subjectList = _convertItems(pagingWrap.items);
    AuthParams authParams = await AuthApi().getAuthParams();
    if(authParams.baseUrl == '') {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SubjectListView()));
    } else {
      _baseUrl = authParams.baseUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: TextField(
          onChanged: (v) => {
            setState(() {
              _keyword = v;
              // _loadSubjects();
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
                          // _loadSubjects();
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
      body: FutureBuilder(
        future: Future.delayed(Duration.zero, _loadSubjects),
        builder: (BuildContext context, AsyncSnapshot snapshot){
          if(snapshot.connectionState == ConnectionState.done) {
            if(snapshot.hasError) {
              return Text("Load subject list fail: ${snapshot.error}");
            } else {
              return buildSubjectsGridView();
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      )
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
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SubjectDetailsView(),
                  settings: RouteSettings(arguments: subjectList[index]))
                );
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
