import 'package:flutter/material.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/home.dart';

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
        title: const Text("用户", style: TextStyle(color: Colors.black, fontSize: 25)),
        // centerTitle: true,
        // leading: const Icon(
        //   Icons.account_circle,
        //   color: Colors.black,
        //   size: 35,
        // ),
        actionsIconTheme: const IconThemeData(
          color: Colors.black,
          size: 35,
        ),
        actions: <Widget>[
          // 非隐藏的菜单
          // IconButton(
          //   icon: const Icon(Icons.add_alarm),
          //   onPressed: () {},
          //   color: Colors.black,
          //
          // ),
          // 隐藏的菜单
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              _selectView(Icons.exit_to_app_rounded, '退出', 'user_logout'),
            ],
            onSelected: (String action) {
              // 点击选项的时候
              switch (action) {
                case 'user_logout':
                  _userLogout();
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

  void _userLogout()async {
    await AuthApi().logout();
    if(mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const HomePage()));
    }
  }
}
