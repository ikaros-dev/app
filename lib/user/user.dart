import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/components/accordion/gf_accordion.dart';
import 'package:getwidget/components/alert/gf_alert.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/components/toast/gf_toast.dart';
import 'package:getwidget/components/typography/gf_typography.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/layout.dart';
import 'package:ikaros/main.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserPageState();
  }
}

class _UserPageState extends State<UserPage> {
  late String _appVersion;

  Future<void> _fetchAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _appVersion = packageInfo.version;
  }

  @override
  void initState() {
    super.initState();
    _fetchAppVersion();
  }

  @override
  Widget build(BuildContext context) {
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
                  _checkAppUpdate();
                  break;
              }
            },
          ),
        ],
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder(future: _fetchAppVersion(), builder: (context, snapshot){
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Text("Load app version error: ${snapshot.error}");
              } else {
                return Text("当前版本：$_appVersion");
              }
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            };
          }),
        ],
      ),
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

  String _getDownloadUrl(List assets) {
    if (!(Platform.isWindows || Platform.isAndroid)) {
      GFToast.showToast("操作失败：更新功能只支持Windows和Android平台", context);
      return "";
    }
    String platform = Platform.isAndroid ? 'android' : 'windows';
    for (var asset in assets) {
      if (asset['name'].contains(platform)) {
        return asset['browser_download_url'];
      }
    }
    return '';
  }

  void _checkAppUpdate() async{
    final response = await Dio().get<String>("https://api.github.com/repos/ikaros-dev/app/releases/latest");
    if (response.statusCode == 200) {
      final data = json.decode(response.data ?? "{}");
      String latestVersion = data['tag_name'];
      String downloadUrl  = _getDownloadUrl(data['assets']);
      if (_appVersion == latestVersion) {
        GFToast.showToast("当前已经是最新版本:$_appVersion", context);
        return;
      }
      if (downloadUrl == "") {
        GFToast.showToast("操作取消：获取下载链接失败", context);
        return;
      }
      // 更新确认框
      bool? cancel = await showDialog<bool>(context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("更新确认"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: const Text("发现新版本，您确定要更新嘛？"),
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
        GFToast.showToast("已取消更新", context);
        return;
      }
      // 下载更新
      GFToast.showToast("将要执行更新逻辑, 请耐心等待！完成后会自动重启应用！", context);
      _downloadUpdate(downloadUrl);
    } else {
      GFToast.showToast("获取GitHub的Release信息失败，请检查网络是否可以直连api.github.com.", context);
    }
  }

  Future<void> _downloadUpdate(String downloadUrl) async {
    if (downloadUrl.isEmpty) return;

    int index = downloadUrl.lastIndexOf('/');
    String fileName = downloadUrl.substring(index + 1, downloadUrl.length);

    final directory = await getApplicationCacheDirectory();
    final String filePath = directory.path + (Platform.isWindows ? "\\" : "/") + fileName;

    File tmpUpdateFile = File(filePath);
    if (!tmpUpdateFile.existsSync()) {
      await Dio().download(downloadUrl, filePath);
    }

    // 安卓直接打开apk文件即可跳转安装逻辑
    if (Platform.isAndroid) {
      if (await Permission.requestInstallPackages.request().isGranted) {
        final OpenResult result = await OpenFile.open(filePath, type: 'application/vnd.android.package-archive');
        if (result.type != ResultType.done) {
          GFToast.showToast("错误：${result.message}", context);
        }
        print(result.message);
      } else {
        print('Install packages permission denied');
        openAppSettings();
      }

    }
    // windows需要起一个powershell，然后退出应用，让powershell执行解压命令覆盖指定目录，最后再启动目录
    if (Platform.isWindows) {
      _startUpdateProcess(filePath);
    }
  }

  void _startUpdateProcess(String zipPath) async {
    if (kDebugMode) {
      GFToast.showToast("操作取消，Windows的DEBUG模式不支持更新", context);
      print("操作取消，Windows的DEBUG模式不支持更新");
      return;
    }
    // 需要更新的应用程序路径
    final appPath = Platform.resolvedExecutable;

    // PowerShell 脚本路径
    File appFile = File(appPath);
    Directory parentDirectory = appFile.parent;
    String parentPath = parentDirectory.absolute.path;

    String scriptPath = parentPath + r'\data\flutter_assets\assets\scripts\windows_update.ps1';

    // ZIP 文件路径
    String zipFilePath = zipPath;

    // 目标目录路径
    String destinationDir = parentPath;

    // 构建 PowerShell 命令
    String command = '$scriptPath "$zipFilePath" "$destinationDir" "$appPath"';

    // 启动 PowerShell 执行脚本
    await Process.run('powershell', ['-Command', command]);

    // 退出 Flutter 应用
    exit(0);
  }

}
