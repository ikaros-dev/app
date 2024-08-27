
import 'package:json_annotation/json_annotation.dart';

part 'CommentEpisode.g.dart';

@JsonSerializable()
class CommentEpisode {
  /// episodeId
  final int cid;
  /// p参数格式为出现时间,模式,颜色,用户ID，各个参数之间使用英文逗号分隔
  //
  // 弹幕出现时间：格式为 0.00，单位为秒，精确到小数点后两位，例如12.34、445.6、789.01
  // 弹幕模式：1-普通弹幕，4-底部弹幕，5-顶部弹幕
  // 颜色：32位整数表示的颜色，算法为 Rx256x256+Gx256+B，R/G/B的范围应是0-255
  // 用户ID：字符串形式表示的用户ID，通常为数字，不会包含特殊字符
  final String p;
  /// 弹幕文本
  final String m;

  CommentEpisode({required this.cid, required this.p, required this.m});

  factory CommentEpisode.fromJson(Map<String, dynamic> json) =>
      _$CommentEpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$CommentEpisodeToJson(this);
}