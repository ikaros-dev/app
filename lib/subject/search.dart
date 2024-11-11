import 'package:flutter/material.dart';
import 'package:ikaros/api/search/IndicesApi.dart';
import 'package:ikaros/api/search/model/SubjectHint.dart';
import 'package:ikaros/api/search/model/SubjectSearchResult.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/consts/subject_const.dart';
import 'package:ikaros/subject/subject.dart';
import 'package:ikaros/utils/message_utils.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<SubjectHint> _results = [];
  bool _isSearching = false;

  void _search(String keyword) async {
    // 进行搜索操作，可以根据输入框的内容进行 API 请求或本地过滤
    setState(() {
      _isSearching = true;
    });
    SubjectSearchResult? result = await IndicesApi().searchSubject(keyword, 20);
    if (result == null) return;
    _results = result.hits;
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全局关键字搜索'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '输入搜索关键字，条目的ID，名称，介绍，Infobox内容均可',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                _search(value); // 回车时触发搜索
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        SubjectHint sub = _results[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              sub.nameCn ?? sub.name,
                              maxLines: 1, // 设置最大行数为2
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 24, // 设置字体大小
                                fontWeight: FontWeight.bold, // 设置字体粗细为加粗
                              ),
                            ),
                            subtitle: Text(
                              sub.summary ?? '',
                              maxLines: 3, // 设置最大行数为2
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: const Icon(Icons.event_note),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              if (sub.type == SubjectType.ANIME ||
                                  sub.type == SubjectType.MUSIC ||
                                  sub.type == SubjectType.REAL) {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => SubjectPage(
                                          id: sub.id.toString(),
                                        )));
                              } else {
                                Toast.show(context,
                                    "当前条目类型[${SubjectConst.typeCnMap[sub.type.name] ?? "未知"}]不支持视频播放");
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

}
