import 'package:flutter/material.dart';
import 'package:getwidget/components/alert/gf_alert.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/components/toast/gf_toast.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/layout.dart';
import 'package:ikaros/main.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserPageState();
  }
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    // return const Text("User Page");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("用户",
            style: TextStyle(color: Colors.black, fontSize: 25)),
        actionsIconTheme: const IconThemeData(
          color: Colors.black,
          size: 35,
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              _selectView(Icons.update, "更新", "app_update"),
              _selectView(Icons.exit_to_app_rounded, '退出', 'user_logout'),
            ],
            onSelected: (String action) {
              // 点击选项的时候
              switch (action) {
                case 'user_logout':
                  _userLogout();
                  break;
                case 'app_update':
                  print("open app updae");
                  break;
              }
            },
          ),
        ],
      ),
      body: const Text(""),
    );
  }

  // 返回每个隐藏的菜单项
  PopupMenuItem<String> _selectView(IconData icon, String text, String id) {
    return PopupMenuItem<String>(
        value: id,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(icon, color: Colors.blue),
            Text(text),
          ],
        ));
  }

  void _userLogout() async {
    if (mounted) {
      bool? cancel = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("登出确认"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: const Text("您确定要登出嘛？"),
              ),
              actions: [
                GFButton(
                  onPressed: () => Navigator.of(context).pop(),
                  color: Colors.green,
                  child: const Text("取消"),
                ),
                GFButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  color: Colors.red,
                  child: const Text("确认"),
                ),
              ],
            );
          });
      if (cancel == null) {
        return;
      }
      await AuthApi().logout();
      GFToast.showToast("已成功登出", context);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const MyApp()));
    }
  }
}
