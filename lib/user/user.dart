import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/main.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
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
          FutureBuilder(
              future: _fetchAppVersion(),
              builder: (context, snapshot) {
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
                }
                ;
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
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("取消"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("确认"),
                ),
              ],
            );
          });
      if (cancel == null) {
        return;
      }
      await AuthApi().logout();
      Toast.show(context, "已成功登出");
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const MyApp()));
    }
  }

  String _getDownloadUrl(List assets) {
    if (!(Platform.isWindows || Platform.isAndroid)) {
      Toast.show(context, "操作失败：更新功能只支持Windows和Android平台");
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

  void _checkAppUpdate() async {
    final response = await Dio().get<String>(
        "https://api.github.com/repos/ikaros-dev/app/releases/latest");
    if (response.statusCode == 200) {
      final data = json.decode(response.data ?? "{}");
      String latestVersion = data['tag_name'];
      String downloadUrl = _getDownloadUrl(data['assets']);
      if ('v$_appVersion' == latestVersion) {
        Toast.show(context, "当前已经是最新版本:$_appVersion");
        return;
      }
      if (downloadUrl == "") {
        Toast.show(context, "操作取消：获取下载链接失败");
        return;
      }
      // 更新确认框
      bool? cancel = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("更新确认"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: const Text("发现新版本，您确定要更新嘛？"),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("取消"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("确认"),
                ),
              ],
            );
          });
      if (cancel == null) {
        Toast.show(context, "已取消更新");
        return;
      }
      // 下载更新
      Toast.show(context, "将要执行更新逻辑, 请耐心等待！完成后会自动重启应用！");
      _downloadUpdate(downloadUrl);
    } else {
      Toast.show(context, "获取GitHub的Release信息失败，请检查网络是否可以直连api.github.com.");
    }
  }

  Future<void> _downloadUpdate(String downloadUrl) async {
    if (downloadUrl.isEmpty) return;

    int index = downloadUrl.lastIndexOf('/');
    String fileName = downloadUrl.substring(index + 1, downloadUrl.length);

    final directory = await getApplicationCacheDirectory();
    final String filePath =
        directory.path + (Platform.isWindows ? "\\" : "/") + fileName;

    File tmpUpdateFile = File(filePath);
    if (!tmpUpdateFile.existsSync()) {
      await Dio().download(downloadUrl, filePath);
    }

    // 安卓直接打开apk文件即可跳转安装逻辑
    if (Platform.isAndroid) {
      if (await Permission.requestInstallPackages.request().isGranted) {
        await OpenFile.open(filePath,
            type: 'application/vnd.android.package-archive');
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
      Toast.show(context, "操作取消，Windows的DEBUG模式不支持更新");
      if (kDebugMode) {
        print("操作取消，Windows的DEBUG模式不支持更新");
      }
      // return;
    }
    // 需要更新的应用程序路径
    final appPath = Platform.resolvedExecutable;

    // PowerShell 脚本路径
    File appFile = File(appPath);
    Directory parentDirectory = appFile.parent;
    String parentPath = parentDirectory.absolute.path;

    // ZIP 文件路径
    String zipFilePath = zipPath;

    // 目标目录路径
    String destinationDir = parentPath;

    // 创建 CMD 文件的路径
    String cmdFilePath = path.join(parentDirectory.path, 'install.cmd');

    // 写入 CMD 文件内容
    File cmdFile = File(cmdFilePath);
    await cmdFile.writeAsString('setlocal\n'
        '\n'
        '\n'
        'echo Delete old update dir'
        '\n'
        'rmdir /S /Q .\\update'
        '\n'
        '\n'
        'echo Extracting update.zip to the update folder'
        '\n'
        "powershell -Command \"Expand-Archive -Path '"
        '$zipFilePath'
        "' -DestinationPath '.\\update' -Force\""
        '\n'
        '\n'
        'echo Waiting until ikaros.exe ends'
        '\n'
        ':waitloop'
        '\n'
        'tasklist /FI "IMAGENAME eq ikaros.exe" 2>NUL '
        '\n'
        'if "%ERRORLEVEL%"=="0" ('
        '\n'
        '    taskkill /F /IM "ikaros.exe" >NUL'
        '\n'
        '    echo Process ikaros.exe killed.'
        '\n'
        ')'
        '\n'
        '\n'
        '\n'
        '\n'
        'echo Deleting the specified files and directories'
        '\n'
        'del /F /Q "ikaros.exe"'
        '\n'
        'del /F /Q "*.ddl"'
        '\n'
        'rmdir /S /Q "data"'
        '\n'
        'rmdir /S /Q "plugins"'
        '\n'
        '\n'
        'echo Copying everything from ./update to ./'
        '\n'
        'xcopy /E /H /R /Y ".\\update\\*" "."'
        '\n'
        '\n'
        'echo Deleting the extracted Ani directory'
        '\n'
        'rmdir /S /Q ".\\update"'
        '\n'
        '\n'
        'echo Deleting the update zip file'
        '\n'
        'del /F /Q \"'
        '$zipPath'
        '\"'
        '\n'
        '\n'
        '\n'
        'echo Launching ikaros.exe'
        '\n'
        'start "" ".\\ikaros.exe"'
        '\n'
        '\n'
        'echo Exiting script'
        '\n'
        'exit');

    await Process.run('icacls', [cmdFilePath, '/grant', 'Everyone:F']);

    // 在当前应用退出前启动 CMD 文件
    Process.start('cmd.exe', ['/c', cmdFilePath],
            mode: ProcessStartMode.detached)
        .timeout(const Duration(milliseconds: 500), onTimeout: () {
      exit(0);
    });
  }
}
