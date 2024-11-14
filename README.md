# ikaros_app

ikaros app by flutter

# 环境
```text
[✓] Flutter (Channel stable, 3.22.0, on Microsoft Windows [版本 10.0.22631.3593], locale zh-CN)
[✓] Windows Version (Installed version of Windows is version 10 or higher)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Chrome - develop for the web
[✓] Visual Studio - develop Windows apps (Visual Studio Community 2022 17.9.7)
[✓] Android Studio (version 2023.3)
[✓] IntelliJ IDEA Ultimate Edition (version 2024.1)
[✓] VS Code (version 1.89.1)
[✓] Connected device (4 available)
[✓] Network resources
```

## Json generate

```
flutter packages pub run build_runner build
```

## Version
APP的版本规定

服务端版本.主版本.子版本

app的服务端版本只取服务端版本的主版本和子版本，忽略第三级别的Bug版本，

比如当前APP适配的服务端是 0.15.5, 那么服务端版本就是15，此时APP的版本就是 15.3.0

如果服务端版本是1.0.0，此时服务端的子版本最大曾是两位数，则，app的服务端版本是 1 * 100 + 0 = 100
，此时APP的版本就是 100.3.0

## Build

```
git submodule init
git submodule update

cd dependencies/dart_vlc
flutter pub get

cd ../../
cd dependencies/flutter_vlc_player
flutter pub get

cd ../../
cd dependencies/ns_danmaku
flutter pub get


cd ../../
flutter pub get
```
用`Android Studio`打开后，如果依赖里还有红线的，进对应的目录，`flutter pub get`下就OK了。

