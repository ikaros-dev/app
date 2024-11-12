import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/common/PagingWrap.dart';
import 'package:ikaros/api/subject/SubjectApi.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:ikaros/api/subject/model/SubjectMeta.dart';
import 'package:ikaros/component/full_screen_Image.dart';
import 'package:ikaros/consts/subject_const.dart';
import 'package:ikaros/subject/search.dart';
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

  bool? _nsfw;
  String? _type;
  String _keyword = "";
  String _baseUrl = '';

  bool _isSubjectLoading = false;
  bool _hasMore = true;
  late EasyRefreshController _controller;

  String _selectedType = '全部类型';
  final List<String> _selectedTypes = ['全部类型'];
  String _selectedYear = '全部年份';
  final List<String> _selectedYears = const [
    '全部年份',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
    '2017',
    '2016',
    '2015',
    '2014-2010',
    '2009-2005',
    '2004-2000',
    '90年代',
    '80年代',
    '更早',
  ];
  String _selectedNsfw = '全部条目';
  final List<String> _selectedNsfws = const ['全部条目', '正常', 'NSFW'];
  String _selectedSeason = '全部季度';
  final List<String> _selectedSeasons = const ['全部季度', '一月', '四月', '七月', '十月'];
  String _selectedStatus = '完结状态';
  final List<String> _allStatus = const ['完结状态', '完结', '连载'];
  String _selectedSort = '综合排序';
  final List<String> _selectedSorts = const ['综合排序', '最近放送', '最近更新'];

  List<SubjectMeta> _convertItems(List<Map<String, dynamic>> items) {
    return items.map((e) => SubjectMeta.fromJson(e)).toList();
  }

  _loadSubjects() async {
    setState(() {
      _isSubjectLoading = true;
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

    if (kDebugMode) {
      print(
          "load data for page=1 size=$_size type=$_type nameCn=$_keyword, nsfw=$_nsfw");
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
    setState(() {
      _isSubjectLoading = false;
    });
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
    _selectedTypes.addAll(SubjectType.values.map((type) {
      return SubjectConst.typeCnMap[type.name] ?? "Null";
    }).toSet());
    _loadSubjects();
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
        title: const Text("条目"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpansionTile(
              title: TextField(
                obscureText: false,
                decoration: const InputDecoration(
                  labelText: '输入条目中文名称回车搜索',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _keyword = value;
                },
                onSubmitted: (value) {
                  setState(() {
                    _keyword = value;
                  });
                  _loadSubjects();
                },
                onEditingComplete: () {
                  _loadSubjects();
                },
              ),
              showTrailingIcon: true,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 类型
                _buildFilterRow(_selectedType, _selectedTypes, (value) {
                  setState(() {
                    _selectedType = value!;
                    _type = SubjectConst.cnTypeMap[_selectedType];
                  });
                  _loadSubjects();
                }),

                // NSFW
                _buildFilterRow(_selectedNsfw, _selectedNsfws, (value) {
                  setState(() {
                    _selectedNsfw = value!;
                    if (_selectedNsfw == '正常') {
                      _nsfw = false;
                    } else if (_selectedNsfw == 'NSFW') {
                      _nsfw = true;
                    } else {
                      _nsfw = null;
                    }
                  });
                  _loadSubjects();
                }),

                // 季度
                _buildFilterRow(_selectedSeason, _selectedSeasons, (value) {
                  setState(() {
                    _selectedSeason = value!;
                  });
                }, enable: false),

                // 完结状态
                _buildFilterRow(_selectedStatus, _allStatus, (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                }, enable: false),

                // 综合排序
                _buildFilterRow(_selectedSort, _selectedSorts,
                        (value) {
                      setState(() {
                        _selectedSort = value!;
                      });
                    }, enable: false),

                // 年份
                _buildFilterRow(_selectedYear, _selectedYears, (value) {
                  setState(() {
                    _selectedYear = value!;
                  });
                }, enable: false),

              ]),


          // 上方条目索引条件



          const SizedBox(
            height: 10,
          ),

          // 下方条目结果展示
          _buildSubjectsEasyRefresh(),
        ],
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
        childAspectRatio: 0.55, // 网格项的宽高比例
      ),
      itemCount: subjectList.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _onSubjectCardTap(subjectList[index]);
          },
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImagePage(
                  imageUrl: UrlUtils.getCoverUrl(
                      _baseUrl, subjectList[index].cover), // 替换为你的图片URL
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 7 / 10, // 设置图片宽高比例
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.0), // 设置圆角半径
                  child: Hero(
                    tag: UrlUtils.getCoverUrl(
                        _baseUrl, subjectList[index].cover),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/loading_placeholder.jpg',
                      // 占位图片
                      image: UrlUtils.getCoverUrl(
                          _baseUrl, subjectList[index].cover),
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
              ),
              Flexible(
                  child: Text(
                ((subjectList[index].nameCn == null ||
                        subjectList[index].nameCn == '')
                    ? subjectList[index].name
                    : subjectList[index].nameCn)!,
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

  // 构建筛选行组件
  Widget _buildFilterRow(
    String currentValue,
    List<String?> options,
    ValueChanged<String?> onChanged,
    {bool enable = true}
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 4,
        children: options.map((option) {
          return ChoiceChip(
            label: Text(option ?? "Null"),
            showCheckmark: false,
            side: BorderSide.none,
            selected: currentValue == option,
            onSelected: enable ? (bool selected) {
              onChanged(selected ? option : null);
            } : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectsEasyRefresh() {
    if (_isSubjectLoading) {
      return const LinearProgressIndicator();
    }
    return Expanded(
      child: EasyRefresh(
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
}
