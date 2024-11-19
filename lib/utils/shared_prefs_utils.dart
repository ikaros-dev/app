import 'package:ns_danmaku/models/danmaku_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUtils {
  static void reload() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.reload();
  }

  static Future<void> saveDanmuConfig(DanmuConfig config) async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setDouble(SharedPrefsKey.danmuFontSize, config.fontSize);
    prefs.setDouble(SharedPrefsKey.danmuDisplayArea, config.area);
    prefs.setDouble(SharedPrefsKey.danmuOpacity, config.opacity);
    prefs.setBool(SharedPrefsKey.danmuHideTop, config.hideTop);
    prefs.setBool(SharedPrefsKey.danmuHideBottom, config.hideBottom);
    prefs.setBool(SharedPrefsKey.danmuHideScroll, config.hideScroll);
    prefs.setDouble(SharedPrefsKey.danmuLineHeight, config.lineHeight);
  }

  static Future<DanmuConfig> getDanmuConfig() async {
    reload();
    var prefs = await SharedPreferences.getInstance();
    final double fontSize = prefs.getDouble(SharedPrefsKey.danmuFontSize) ??
        SharedPrefsDefaultValue.danmuFontSize;
    final double area = prefs.getDouble(SharedPrefsKey.danmuDisplayArea) ??
        SharedPrefsDefaultValue.danmuDisplayArea;
    final double opacity = prefs.getDouble(SharedPrefsKey.danmuOpacity) ??
        SharedPrefsDefaultValue.danmuOpacity;
    final bool hideTop = prefs.getBool(SharedPrefsKey.danmuHideTop) ??
        SharedPrefsDefaultValue.danmuHideTop;
    final bool hideBottom = prefs.getBool(SharedPrefsKey.danmuHideBottom) ??
        SharedPrefsDefaultValue.danmuHideBottom;
    final bool hideScroll = prefs.getBool(SharedPrefsKey.danmuHideScroll) ??
        SharedPrefsDefaultValue.danmuHideScroll;
    final double lineHeight = prefs.getDouble(SharedPrefsKey.danmuLineHeight) ??
        SharedPrefsDefaultValue.danmuLineHeight;
    return DanmuConfig.name(
        fontSize, area, opacity, hideTop, hideBottom, hideScroll, lineHeight);
  }

  static Future<void> saveSettingConfig(SettingConfig config) async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setBool(SharedPrefsKey.hideNsfwWhenSubjectsOpen,
        config.hideNsfwWhenSubjectsOpen);
    prefs.setString(SharedPrefsKey.proxyUrl, config.proxyUrl);
  }

  static Future<SettingConfig> getSettingConfig() async {
    reload();
    var prefs = await SharedPreferences.getInstance();
    final bool enableEpisodeApiSplit =
        prefs.getBool(SharedPrefsKey.settingEnableEpisodeApiSplit) ??
            SharedPrefsDefaultValue.settingEnableEpisodeApiSplit;
    final bool hideNsfwWhenSubjectsOpen =
        prefs.getBool(SharedPrefsKey.hideNsfwWhenSubjectsOpen) ??
            SharedPrefsDefaultValue.hideNsfwWhenSubjectsOpen;
    final String proxyUrl = prefs.getString(SharedPrefsKey.proxyUrl) ?? "";
    return SettingConfig(
        hideNsfwWhenSubjectsOpen: hideNsfwWhenSubjectsOpen,
        proxyUrl: proxyUrl);
  }
}

class SharedPrefsKey {
  static const String danmuFontSize = "DANMU_FONT_SIZE";
  static const String danmuDisplayArea = "DANMU_DISPLAY_AREA";
  static const String danmuOpacity = "DANMU_OPACITY";
  static const String danmuHideTop = "DANMU_HIDE_TOP";
  static const String danmuHideBottom = "DANMU_HIDE_BOTTOM";
  static const String danmuHideScroll = "DANMU_HIDE_SCROLL";
  static const String danmuLineHeight = "DANMU_LINE_HEIGHT";
  static const String settingEnableEpisodeApiSplit =
      "SETTING_ENABLE_EPISODE_API_SPLIT";
  static const String hideNsfwWhenSubjectsOpen = "HIDE_NSFW_WHEN_SUBJECTS_OPEN";
  static const String proxyUrl = "PROXY_URL";
}

class SharedPrefsDefaultValue {
  static const double danmuFontSize = 16.0;
  static const double danmuDisplayArea = 1.0;
  static const double danmuOpacity = 1.0;
  static const bool danmuHideTop = false;
  static const bool danmuHideBottom = false;
  static const bool danmuHideScroll = false;
  static const double danmuLineHeight = 1.2;
  static const bool settingEnableEpisodeApiSplit = false;
  static const bool hideNsfwWhenSubjectsOpen = true;
}

class DanmuConfig {
  /// 默认的字体大小
  double fontSize = SharedPrefsDefaultValue.danmuFontSize;

  /// 显示区域，0.1-1.0
  late double area = SharedPrefsDefaultValue.danmuDisplayArea;

  /// 不透明度，0.1-1.0
  late double opacity = SharedPrefsDefaultValue.danmuOpacity;

  /// 隐藏顶部弹幕
  bool hideTop = SharedPrefsDefaultValue.danmuHideTop;

  /// 隐藏底部弹幕
  bool hideBottom = SharedPrefsDefaultValue.danmuHideBottom;

  /// 隐藏滚动弹幕
  bool hideScroll = SharedPrefsDefaultValue.danmuHideScroll;

  /// 弹幕行高
  /// - 1.0表示字体大小的1倍，数字越大弹幕上下间距越大
  /// - 默认值`1.2`
  double lineHeight = SharedPrefsDefaultValue.danmuLineHeight;

  DanmuConfig.name(this.fontSize, this.area, this.opacity, this.hideTop,
      this.hideBottom, this.hideScroll, this.lineHeight);

  DanmuConfig();

  @override
  String toString() {
    return 'DanmuConfig{fontSize: $fontSize, area: $area, opacity: $opacity, hideTop: $hideTop, hideBottom: $hideBottom, hideScroll: $hideScroll, lineHeight: $lineHeight}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DanmuConfig &&
          // runtimeType == other.runtimeType &&
          fontSize == other.fontSize &&
          area == other.area &&
          opacity == other.opacity &&
          hideTop == other.hideTop &&
          hideBottom == other.hideBottom &&
          hideScroll == other.hideScroll &&
          lineHeight == other.lineHeight;

  @override
  int get hashCode =>
      fontSize.hashCode ^
      area.hashCode ^
      opacity.hashCode ^
      hideTop.hashCode ^
      hideBottom.hashCode ^
      hideScroll.hashCode ^
      lineHeight.hashCode;

  DanmakuOption toOption() {
    return DanmakuOption(
        fontSize: fontSize,
        area: area,
        opacity: opacity,
        hideTop: hideTop,
        hideBottom: hideBottom,
        hideScroll: hideScroll,
        lineHeight: lineHeight);
  }

  static DanmuConfig fromOption(DanmakuOption option) {
    return DanmuConfig.name(
        option.fontSize,
        option.area,
        option.opacity,
        option.hideTop,
        option.hideBottom,
        option.hideScroll,
        option.lineHeight);
  }
}

class SettingConfig {
  bool hideNsfwWhenSubjectsOpen =
      SharedPrefsDefaultValue.hideNsfwWhenSubjectsOpen;
  String proxyUrl = "";

  SettingConfig(
      {this.hideNsfwWhenSubjectsOpen =
          SharedPrefsDefaultValue.hideNsfwWhenSubjectsOpen,
      this.proxyUrl = ""});
}
