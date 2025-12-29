

import 'package:json_annotation/json_annotation.dart';

part 'BangumiEpisode.g.dart';

@JsonSerializable()
class BangumiEpisode {
  /// 剧集ID（弹幕库编号）
  final int episodeId;
  final int animeId;
  final int seasonId;
  final String bgmtvSubjectId;
  final String episodeNumber;
  /// 剧集标题
  final String? episodeTitle;
  final String? lastWatched;
  final String? airDate;

  BangumiEpisode(this.animeId, this.seasonId, this.bgmtvSubjectId, this.episodeNumber, this.lastWatched, this.airDate, {required this.episodeId, this.episodeTitle});


  factory BangumiEpisode.fromJson(Map<String, dynamic> json) =>
      _$BangumiEpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$BangumiEpisodeToJson(this);
}