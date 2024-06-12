import 'dart:io';

class PlatformUtils {
  static bool isMobile() {
    return (Platform.isAndroid || Platform.isIOS);
  }
}
