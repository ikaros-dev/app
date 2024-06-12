import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/subject/subjects_view.dart';
import 'package:ikaros/user/user_view.dart';

import 'collection/collection_view.dart';

/// 主页面
class DesktopView extends StatefulWidget {
  const DesktopView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DesktopViewState();
  }
}

class _DesktopViewState extends State<DesktopView> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<NavigationPaneItem> items = [
    PaneItem(
      icon: const Icon(Icons.collections_sharp),
      title: const Text('收藏'),
      body: const CollectionView(),
    ),    PaneItem(
      icon: const Icon(Icons.tv),
      title: const Text('条目'),
      body: const SubjectsView(),
    ),    PaneItem(
      icon: const Icon(Icons.account_circle),
      title: const Text('我的'),
      body: const UserView(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        items: items,
      ),
    );
  }
}
