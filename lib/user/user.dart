import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/user/UserApi.dart';
import 'package:ikaros/api/user/model/User.dart';
import 'package:ikaros/main.dart';
import 'package:ikaros/user/setting.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/shared_prefs_utils.dart';
import 'package:ikaros/utils/url_utils.dart';
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
  late SettingConfig config = SettingConfig();
  late User? _me;
  late String _baseUrl;
  final FocusNode _proxyUrlFocusNode = FocusNode();
  final TextEditingController _proxyUrlController = TextEditingController();

  Future<void> _fetchAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _appVersion = packageInfo.version;
  }

  Future<String> _getAppVersion() async {
    await _fetchAppVersion();
    return _appVersion;
  }

  Future<void> _loadSettingConfig() async {
    config = await SharedPrefsUtils.getSettingConfig();
    if (config.proxyUrl != "") {
      _proxyUrlController.text = config.proxyUrl;
    }
    setState(() {});
  }

  void onEnableEpisodeApiSplitSwitchChange(val) async {
    config.enableEpisodeApiSplit = val;
    await SharedPrefsUtils.saveSettingConfig(config);
    await _loadSettingConfig();
  }

  void onHideNsfwWhenSubjectsOpenSwitchChange(val) async {
    config.hideNsfwWhenSubjectsOpen = val;
    await SharedPrefsUtils.saveSettingConfig(config);
    await _loadSettingConfig();
  }

  @override
  void initState() {
    super.initState();
    _fetchAppVersion();
    _loadSettingConfig();
  }

  Future<User?> _fetchMe() async {
    await _fetchBaseUrl();
    _me = await UserApi().getMe();
    return _me;
  }

  Future<String> _fetchBaseUrl() async {
    AuthParams authParams = await AuthApi().getAuthParams();
    _baseUrl = authParams.baseUrl;
    return _baseUrl;
  }

  String getAvatarTitle(User? user) {
    var res = user?.username ?? "";
    if (user?.nickname != null && user?.nickname != "") {
      res = '$res(${user!.nickname!})';
    }
    return res;
  }

  Widget _buildAppbarUser() {
    return FutureBuilder(
        future: _fetchMe(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text("Load api base url error: ${snapshot.error}");
            } else {
              return Row(
                children: [
                  CircleAvatar(
                    radius: 28, // 半径控制头像的大小
                    backgroundImage: NetworkImage(
                        UrlUtils.getCoverUrl(_baseUrl, _me?.avatar ?? "")),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getAvatarTitle(_me),
                        style: const TextStyle(fontSize: 28),
                      ),
                      if (_me?.introduce != null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            _me?.introduce ?? "",
                            style: const TextStyle(
                              fontSize: 15, // 字体大小
                              fontWeight: FontWeight.w500, // 字体粗细
                              color: Colors.grey, // 字体颜色
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            }
          } else {
            return const CircularProgressIndicator();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: _buildAppbarUser(),
        // title: const CircleAvatar(
        //   radius: 32.5, // 半径控制头像的大小
        //   backgroundImage: NetworkImage('https://ikaros.run/img/favicon.ico'),
        // ),
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
      // appBar: PreferredSize(
      //   preferredSize: const DartUi.Size.fromHeight(70.0),
      //   child: AppBar(
      //     backgroundColor: Colors.white,
      //     title: const CircleAvatar(
      //       radius: 32.5, // 半径控制头像的大小
      //       backgroundImage: NetworkImage('https://ikaros.run/img/favicon.ico'),
      //     ),
      //     actionsIconTheme: const IconThemeData(
      //       color: Colors.black,
      //       size: 35,
      //     ),
      //     actions: <Widget>[
      //       PopupMenuButton<String>(
      //         itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
      //           _selectView(Icons.update, "更新", "app_update"),
      //           _selectView(Icons.exit_to_app_rounded, '退出', 'user_logout'),
      //         ],
      //         onSelected: (String action) {
      //           // 点击选项的时候
      //           switch (action) {
      //             case 'user_logout':
      //               _userLogout();
      //               break;
      //             case 'app_update':
      //               _checkAppUpdate();
      //               break;
      //           }
      //         },
      //       ),
      //     ],
      //   ),
      // ),
      body: ListView(
        children: [
          Setting(
            title: "版本号",
            subtitle: "这是APP当前的版本号",
            rightWidget: FutureBuilder(
                future: _getAppVersion(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Text(
                          "Load app version error: ${snapshot.error ?? ""}");
                    } else {
                      return Text(
                        "v${snapshot.data ?? "0.0.0"}",
                        style: const TextStyle(fontSize: 20),
                      );
                    }
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          ),
          Setting(
            title: "条目详情页剧集接口拆分",
            subtitle: "开启则每个剧集单独请求剧集资源，关闭则统一根据条目ID请求剧集和资源。",
            rightWidget: Switch(
                value: config.enableEpisodeApiSplit,
                onChanged: onEnableEpisodeApiSplitSwitchChange),
          ),
          Setting(
            title: "隐藏NSFW条目",
            subtitle: "条目详情页打开时是否隐藏NSFW条目",
            rightWidget: Switch(
                value: config.hideNsfwWhenSubjectsOpen,
                onChanged: onHideNsfwWhenSubjectsOpenSwitchChange),
          ),
          Setting(
            title: "HTTP代理Url",
            subtitle: "更新请求是否使用代理，为空则不启用，格式：http://127.0.0.1:7890",
            rightWidget: SizedBox(
              width: 200,
              child: GestureDetector(
                onTap: () {
                  // 点击其他区域时，失去焦点并提交
                  if (_proxyUrlFocusNode.hasFocus) {
                    _proxyUrlFocusNode.unfocus(); // 失去焦点
                    _saveProxyUrl(); // 提交文本
                  }
                },
                child: TextField(
                  controller: _proxyUrlController,
                  focusNode: _proxyUrlFocusNode,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() {
                      config.proxyUrl = v;
                    });
                  },
                  onSubmitted: (v) {
                    setState(() {
                      config.proxyUrl = v;
                    });
                    _saveProxyUrl();
                  },
                ),
              ),
            ),
            // rightWidget: Switch(
            //     value: config.hideNsfwWhenSubjectsOpen,
            //     onChanged: onHideNsfwWhenSubjectsOpenSwitchChange),
          ),
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

  Future<String> _getDownloadUrl(List assets) async {
    if (!(Platform.isWindows || Platform.isAndroid)) {
      Toast.show(context, "操作失败：更新功能只支持Windows和Android平台");
      return "";
    }
    String platform = Platform.isAndroid ? 'android-arm64-v8a' : 'windows';
    for (var asset in assets) {
      if (asset['name'].contains(platform)) {
        return asset['browser_download_url'];
      }
    }
    return '';
  }

  Dio _configProxy(Dio dio) {
    if (config.proxyUrl != "") {
      (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
          (client) {
        client.findProxy = (uri) {
          // 设置代理服务器地址
          var str = "";
          if (config.proxyUrl.contains("http://")) {
            str = config.proxyUrl.replaceAll("http://", "");
          }
          var stirs = str.split(':');
          return 'PROXY ${stirs[0]}:${stirs[1]}'; // 这里替换成你的代理地址和端口
        };
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return null; // 忽略证书错误
      };
    }
    return dio;
  }

  void _checkAppUpdate() async {
    final response = await _configProxy(Dio()).get<String>(
        "https://api.github.com/repos/ikaros-dev/app/releases/latest");
    if (response.statusCode == 200) {
      final data = json.decode(response.data ?? "{}");
      String latestVersion = data['tag_name'];
      String downloadUrl = await _getDownloadUrl(data['assets']);
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
      await _configProxy(Dio()).download(downloadUrl, filePath);
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

  void _saveProxyUrl() async {
    await SharedPrefsUtils.saveSettingConfig(config);
    await _loadSettingConfig();
  }
}
