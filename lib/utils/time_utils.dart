import 'package:intl/intl.dart';

class TimeUtils {
  static String convertMinSec(int milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds);
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;

    return '$minutes 分 $seconds 秒';
  }

  static String formatDateString(String isoDate) {
    // 解析 ISO 8601 格式的日期字符串
    DateTime dateTime = DateTime.parse(isoDate);
    // 格式化为“年-月-日”格式
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  static String toIso8601Str(DateTime dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss').format(dateTime);
  }

  static String formatDateStringWithPattern(String? isoDate, String pattern) {
    if  (isoDate == null) return "";
    DateTime dateTime = DateTime.parse(isoDate);
    // 格式化为“年-月-日”格式
    return DateFormat(pattern).format(dateTime);
  }

  static String formatDateTimeWithPattern(DateTime dateTime, String pattern) {
    // 格式化为“年-月-日”格式
    return DateFormat(pattern).format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    // 格式化为“年-月-日”格式
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  static String formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '${minutes}分${seconds}秒';
  }
}