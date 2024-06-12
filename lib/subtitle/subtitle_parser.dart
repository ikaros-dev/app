import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class SubtitleParser {
  static const String subtitle_dir_name = "subtitle";
  late String subtitle;
  final String url;

  SubtitleParser(this.url);

  Future<Directory> _getTmpSubtitleDir() async {
    Directory tmpDir = await getTemporaryDirectory();
    return tmpDir.createTemp("$subtitle_dir_name-${const Uuid().v4()}");
  }

  // 解析正文的字幕
  Future<List<Subtitle>> parseNtpSubtitlesWithUrl() async {
    if (url.lastIndexOf(".ass") < 0) {
      return Future(() => List.empty());
    }
    Directory subTitleDir = await _getTmpSubtitleDir();
    String subTitleDirPath = subTitleDir.path;
    subTitleDirPath += "${const Uuid().v4()}.ass";
    await Dio().download(url, subTitleDirPath);
    File file = File(subTitleDirPath);
    String subtitle = await file.readAsString();
    file.delete();
    List<Subtitle> subtitles = <Subtitle>[];

    List<String> contents = subtitle
        .split("\r\n")
        .where((element) => element.contains("Dialogue"))
        .toList();

    for (var element in contents) {
      // 去掉中括号
      element = element.replaceAll(RegExp(r'{[^}]*}'), "");
      List<String> subtitleLines = element.split(",");
      if (subtitleLines.isNotEmpty && subtitleLines.length >= 9) {
        // 0:23:47.24
        String startTimeStr = subtitleLines[1];
        String endTimeStr = subtitleLines[2];
        String contextStr = subtitleLines[subtitleLines.length - 1];

        List<String> times = startTimeStr.split(":");
        double micos = double.parse(times[2]) * 1000;
        Duration startTime = Duration(
            hours: int.parse(times[0]),
            minutes: int.parse(times[1]),
            microseconds: micos.toInt());
        times = endTimeStr.split(":");
        Duration endTime = Duration(
            hours: int.parse(times[0]),
            minutes: int.parse(times[1]),
            microseconds: micos.toInt());
        Subtitle subtitle = Subtitle(startTime, endTime, contextStr);

        subtitles.add(subtitle);
      }
    }

    return Future(() => subtitles);
  }
}

class Subtitle {
  final Duration start;
  final Duration end;
  final String context;

  Subtitle(this.start, this.end, this.context);
}
