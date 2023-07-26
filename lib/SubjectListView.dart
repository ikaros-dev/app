import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// const cover = "http://nas:9999/files/2023/7/6/b17a4329e4c148bca28602dbae9f9727.jpg";
const cover = "https://lain.bgm.tv/r/400/pic/cover/l/5a/24/441233_nJ7Do.jpg";

class SubjectListView extends StatefulWidget {
  final String title;

  const SubjectListView({super.key, required this.title});

  @override
  State<StatefulWidget> createState() {
    return SubjectListState();
  }
}

class SubjectListState extends State<SubjectListView> {
  List<Map<String, String>> dataList = [
    {'name': 'Apple', 'image': cover},
    // {'name': 'Banana', 'image': cover},
    // {'name': 'Cherry', 'image': cover},
    // 添加更多的数据项...
  ];

  List<Map<String, String>> filteredList = [];

  bool nsfw = false;
  String keyword = "";

  @override
  void initState() {
    super.initState();
    filteredList = dataList; // 初始时显示全部数据
    for (int i = 0; i < 10; i++) {
      dataList.add({'name': 'Apple${(i + 1)}', 'image': cover});
    }
  }

  void _searchList() {
    setState(() {
      Fluttertoast.showToast(
          msg: "Search action! keyword: $keyword , nsfw: $nsfw",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      filteredList = dataList
          .where((item) =>
              item['name']?.toLowerCase()?.contains(keyword.toLowerCase()) ??
              false)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: TextField(
          onChanged: (v) => {
            setState(() {
              keyword = v;
              _searchList();
            })
        },
          decoration: const InputDecoration(
            hintText: '输入条目中文名称回车搜索',
            border: InputBorder.none,
          ),
        ),
        actions: [
          Row(
            children: [
              const Text("NSFW", style: TextStyle(color: Colors.black)),
              Switch(
                  value: nsfw,
                  onChanged: (v) => {
                        setState(() {
                          nsfw = v; // 更新开关状态的变量
                          _searchList();
                        })
                      }),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black), // 设置搜索图标
                onPressed: _searchList,
              ),
            ],
          )
        ],
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2.0,
          mainAxisSpacing: 2.0,
          childAspectRatio: 0.6, // 网格项的宽高比例
        ),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () {
                  // @see https://pub-web.flutter-io.cn/packages/fluttertoast
                  Fluttertoast.showToast(
                      msg: "This is Center Short Toast",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0);
                },
                child: AspectRatio(
                  aspectRatio: 7 / 10, // 设置图片宽高比例
                  child: Image.network(
                    filteredList[index]['image'] ?? cover,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  filteredList[index]['name']!,
                  style: const TextStyle(
                      fontSize: 14.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
