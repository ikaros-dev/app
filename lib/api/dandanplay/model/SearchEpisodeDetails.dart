

import 'package:json_annotation/json_annotation.dart';

part 'SearchEpisodeDetails.g.dart';

@JsonSerializable()
class SearchEpisodeDetails {
  /// 剧集ID（弹幕库编号）
  final int episodeId;
  /// 剧集标题
  final String? episodeTitle;

  SearchEpisodeDetails({required this.episodeId, this.episodeTitle});


  factory SearchEpisodeDetails.fromJson(Map<String, dynamic> json) =>
      _$SearchEpisodeDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$SearchEpisodeDetailsToJson(this);
}