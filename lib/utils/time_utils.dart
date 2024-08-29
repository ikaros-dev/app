class TimeUtils {
  static String convertMinSec(int milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds);
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;

    return '$minutes 分 $seconds 秒';
  }
}