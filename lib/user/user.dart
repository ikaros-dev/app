import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/api/actuator/ActuatorInfoApi.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/user/UserApi.dart';
import 'package:ikaros/api/user/model/User.dart';
import 'package:ikaros/collection/episode_collections.dart';
import 'package:ikaros/main.dart';
import 'package:ikaros/component/setting.dart';
import 'package:ikaros/utils/message_utils.dart';
import 'package:ikaros/utils/screen_utils.dart';
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
  String? _serverVersion;
  String? _appVersion;
  SettingConfig config = SettingConfig();
  User? _me;
  String _baseUrl = "";
  final FocusNode _proxyUrlFocusNode = FocusNode();
  final TextEditingController _proxyUrlController = TextEditingController();
  String _filePath = "";
  final ValueNotifier<double> _updateDownloadProgress = ValueNotifier(0);
  final List<Map<String, dynamic>> gridItems = [
    {'icon': Icons.history, 'text': '历史记录'},
  ];

  Future<void> _fetchServerVersion() async {
    String? v = await ActuatorInfo().getVersion();
    _serverVersion = v;
    setState(() {});
  }

  Future<void> _fetchAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _appVersion = packageInfo.version;
  }

  Future<void> _loadSettingConfig() async {
    config = await SharedPrefsUtils.getSettingConfig();
    if (config.proxyUrl != "") {
      _proxyUrlController.text = config.proxyUrl;
    }
    setState(() {});
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
    _fetchMe();
    _fetchServerVersion();
    _fetchAppVersion();
  }

  Future<void> _fetchMe() async {
    await _fetchBaseUrl();
    _me = await UserApi().getMe();
    setState(() {});
  }

  Future<void> _fetchBaseUrl() async {
    AuthParams? authParams = await AuthApi().getAuthParams();
    _baseUrl = authParams?.baseUrl ?? "";
    setState(() {});
  }

  String getAvatarTitle(User? user) {
    var res = user?.username ?? "";
    if (user?.nickname != null && user?.nickname != "") {
      res = '$res(${user!.nickname!})';
    }
    return res;
  }

  Widget _buildAppbarUser() {
    if (_me == null || _baseUrl == "") return const CircularProgressIndicator();
    return Row(
      children: [
        CircleAvatar(
          radius: 28, // 半径控制头像的大小
          backgroundImage:
          NetworkImage(UrlUtils.getCoverUrl(_baseUrl, _me?.avatar ?? "")),
        ),
        const SizedBox(
          width: 10,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getAvatarTitle(_me),
              style: const TextStyle(fontSize: 28, overflow: TextOverflow.ellipsis),
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
                    overflow: TextOverflow.ellipsis
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: _buildAppbarUser(),
        actionsIconTheme: const IconThemeData(
          color: Colors.black,
          size: 35,
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) =>
            <PopupMenuItem<String>>[
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
      body: ListView(
        children: [
          Setting(
            title: "服务端版本号",
            subtitle: "这是服务端当前的版本号",
            rightWidget: _serverVersion != null
                ? Text(
              "v$_serverVersion",
              style: const TextStyle(fontSize: 20),
            )
                : const CircularProgressIndicator(),
          ),
          Setting(
            title: "APP版本号",
            subtitle: "这是APP当前的版本号",
            rightWidget: ValueListenableBuilder<double>(
                valueListenable: _updateDownloadProgress,
                builder: (context, progress, child) {
                  if (_updateDownloadProgress.value > 0 &&
                      _updateDownloadProgress.value < 100) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: CircularProgressIndicator(
                            value: _updateDownloadProgress.value / 100, // 设置进度
                            strokeWidth: 12.0, // 设置圆圈的宽度
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blueAccent), // 设置颜色
                          ),
                        ),
                        Text(
                          '${_updateDownloadProgress.value.toInt()}%', // 显示百分比
                          style: const TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                    return Center(
                      child: CircularProgressIndicator(
                        value: _updateDownloadProgress.value / 100,
                        // 设置进度
                        strokeWidth: 12.0,
                        // 设置圆圈的宽度
                        semanticsLabel: '安装包下载中',
                        semanticsValue: '已完成 ${_updateDownloadProgress
                            .value}%',
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blueAccent), // 设置颜色
                      ),
                    );
                  } else if (_updateDownloadProgress.value == 100) {
                    return OutlinedButton(
                        onPressed: () {
                          _installPackage();
                        },
                        child: const Text("点击安装"));
                  }
                  return _appVersion != null
                      ? Text(
                    "v$_appVersion",
                    style: const TextStyle(fontSize: 20),
                  )
                      : const CircularProgressIndicator();
                }),
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
          // 动态网格布局
          LayoutBuilder(
            builder: (context, constraints) {
              // 根据容器宽度计算每行列数
              final width = constraints.maxWidth;
              final crossAxisCount =  ScreenUtils.isDesktop(context) ? 6 : 4;

              return GridView.count(
                shrinkWrap: true,
                // 重要：让 GridView 适应 ListView
                physics: const NeverScrollableScrollPhysics(),
                // 禁止 GridView 自身滚动
                crossAxisCount: crossAxisCount,
                padding: const EdgeInsets.all(8.0),
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                children: gridItems.map((item) {
                  return GridItem(icon: item['icon'], text: item['text']);
                }).toList(),
              );
            },
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
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.8,
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

  Future<String> _getDownloadUrl(List assets, String tagName) async {
    if (!(Platform.isWindows || Platform.isAndroid)) {
      Toast.show(context, "操作失败：更新功能只支持Windows和Android平台");
      return "";
    }
    String platform = Platform.isAndroid ? 'android-arm64-v8a' : 'windows';
    for (var asset in assets) {
      if (asset['name'].contains(platform)) {
        String fileName = asset['name'];
        return "https://pub-bf2151a8e446476eac3583b3e45d5cc8.r2.dev/$tagName/$fileName";
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
      String downloadUrl = await _getDownloadUrl(data['assets'], latestVersion);
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
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.8,
                child: Text("发现新版本$latestVersion，您确定要更新嘛？"),
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
      Toast.show(context, "将要执行更新逻辑, 请耐心等待！");
      _downloadUpdate(downloadUrl);
    } else {
      Toast.show(context,
          "获取GitHub的Release信息失败，请检查网络是否可以直连api.github.com.");
    }
  }

  Future<void> _downloadUpdate(String downloadUrl) async {
    if (downloadUrl.isEmpty) return;

    int index = downloadUrl.lastIndexOf('/');
    String fileName = downloadUrl.substring(index + 1, downloadUrl.length);

    final directory = await getApplicationCacheDirectory();
    _filePath = directory.path + (Platform.isWindows ? "\\" : "/") + fileName;

    File tmpUpdateFile = File(_filePath);
    if (!tmpUpdateFile.existsSync()) {
      _configProxy(Dio()).download(downloadUrl, _filePath,
          onReceiveProgress: (received, total) {
            _updateDownloadProgress.value = (received / total) * 100;
          });
    } else {
      setState(() {
        _updateDownloadProgress.value = 100;
      });
    }
  }

  void _installPackage() async {
    if (_filePath == "") return;
    // 安卓直接打开apk文件即可跳转安装逻辑
    if (Platform.isAndroid) {
      if (await Permission.requestInstallPackages
          .request()
          .isGranted) {
        await OpenFile.open(_filePath,
            type: 'application/vnd.android.package-archive');
      } else {
        print('Install packages permission denied');
        openAppSettings();
      }
    }
    // windows需要起一个powershell，然后退出应用，让powershell执行解压命令覆盖指定目录，最后再启动目录
    if (Platform.isWindows) {
      _startUpdateProcess(_filePath);
    }
    _updateDownloadProgress.value = 0;
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
        'del /F /Q "'
        '$zipPath'
        '"'
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

class GridItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const GridItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // 点击事件处理
        print('点击了: $text');
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => EpisodeCollectionsPage()));
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30.0, color: Theme
                .of(context)
                .primaryColor),
            const SizedBox(height: 8.0),
            Text(text, style: const TextStyle(fontSize: 12.0)),
          ],
        ),
      ),
    );
  }
}
