// import 'dart:io';
//
// import 'package:device_info_plus/device_info_plus.dart';
//
// class DeviceInfoUtils {
//   static DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//
//   static Future<AndroidDeviceInfo?> getAndroidDeviceInfo() async {
//     if (!Platform.isAndroid) return null;
//     return await deviceInfo.androidInfo;
//   }
//
//   static Future<bool> isAndroidArmv7a() async {
//     if (!Platform.isAndroid) return false;
//     AndroidDeviceInfo? androidInfo = await getAndroidDeviceInfo();
//     if (androidInfo == null) return false;
//     return "armv7" == androidInfo.hardware || "armeabi-v7a" == androidInfo.hardware;
//   }
//
//   static Future<bool> isAndroidArm64() async {
//     if (!Platform.isAndroid) return false;
//     AndroidDeviceInfo? androidInfo = await getAndroidDeviceInfo();
//     if (androidInfo == null) return false;
//     return "arm64" == androidInfo.hardware || "arm64-v8a" == androidInfo.hardware;
//   }
//
//   static Future<bool> isAndroidX86() async {
//     if (!Platform.isAndroid) return false;
//     AndroidDeviceInfo? androidInfo = await getAndroidDeviceInfo();
//     if (androidInfo == null) return false;
//     return "x86" == androidInfo.hardware || "x86_64" == androidInfo.hardware;
//   }
//
// }