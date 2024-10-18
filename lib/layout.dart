import 'package:flutter/material.dart';
import 'package:ikaros/collection/collections.dart';
import 'package:ikaros/subject/subject.dart';
import 'package:ikaros/subject/subjects.dart';
import 'package:ikaros/user/user.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:uni_links/uni_links.dart';

/// 主页面 移动端
class MobileLayout extends StatefulWidget {
  const MobileLayout({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MobileLayoutState();
  }
}

class _MobileLayoutState extends State<MobileLayout> {
  // Page Controller.
  late PageController _pageController;

  // Current page.
  int _pageIndex = 0;

  String? _latestLink;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initUniLinks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initUniLinks() async {
    // 获取初始链接
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        setState(() {
          _latestLink = initialLink;
        });
        _handleIncomingLink(initialLink.toString());
      }
    } catch (e) {
      print('Failed to get initial link: $e');
    }

    // 监听链接变化
    linkStream.listen((String? link) {
      setState(() {
        _latestLink = link;
      });
      if (link != null) {
        _handleIncomingLink(link.toString());
      }
    });
  }

  void _handleIncomingLink(String link) {
    // 处理链接逻辑，例如导航到特定页面
    setState(() {
      _latestLink = link;
    });
    // 解析链接并进行导航
    // 格式：ikaros://app/subject/111
    if (link.contains("subject/")) {
      var id = link.substring(link.lastIndexOf("/") + 1);
      Toast.show(context,
          "正在跳转到条目:$id");
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => SubjectPage(
                id: id,
              )));
    }
  }

  // Change page.
  void _onBottomNavigationBarTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  // TODO Widget _buildMobileWid

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: const <Widget>[CollectionPage(), SubjectsPage(), UserPage()],
        onPageChanged: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _pageIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onBottomNavigationBarTap,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_sharp),
            label: '收藏',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tv),
            label: '条目',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

// 主页面 PC端
class DesktopLayout extends StatefulWidget {
  const DesktopLayout({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DesktopLayoutState();
  }
}

class _DesktopLayoutState extends State<DesktopLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CollectionPage(),
    const SubjectsPage(),
    const UserPage(),
  ];

  void _onMenuItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左边的菜单栏
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onMenuItemTapped,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.collections_sharp),
                label: Text('收藏'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tv),
                label: Text('条目'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_circle),
                label: Text('我的'),
              ),
            ],
          ),
          // 右边的内容区域
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
