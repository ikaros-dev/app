import 'package:flutter/cupertino.dart';

class ScreenUtils {
  static bool screenWidthGt600(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }
  static bool isDesktop(BuildContext context) {
    return screenWidthGt600(context);
  }
  static bool isMobile(BuildContext context) {
    return !isDesktop(context);
  }
}