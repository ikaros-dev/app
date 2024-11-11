import 'package:intl/intl.dart';

class TimeUtils {
  static String convertMinSec(int milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds);
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;

    return '$minutes 分 $seconds 秒';
  }

  String formatDateString(String isoDate) {
    // 解析 ISO 8601 格式的日期字符串
    DateTime dateTime = DateTime.parse(isoDate);
    // 格式化为“年-月-日”格式
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}