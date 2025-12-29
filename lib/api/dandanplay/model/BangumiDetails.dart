
import 'package:ikaros/api/dandanplay/enums/SearchEpisodesAnimeType.dart';
import 'package:json_annotation/json_annotation.dart';

import 'BangumiEpisode.dart';
import 'SearchEpisodeDetails.dart';

part 'BangumiDetails.g.dart';

@JsonSerializable()
class BangumiDetails {
  /// 作品编号
  final int animeId;
  final String bangumiId;
  final String bgmtvSubjectId;
  /// 作品标题
  final String? animeTitle;
  /// 作品类型
  final SearchEpisodesAnimeType type;
  /// 类型描述
  final String? typeDescription;
  /// 此作品的剧集列表
  final List<BangumiEpisode> episodes;

  BangumiDetails(this.bangumiId, this.bgmtvSubjectId, {required this.animeId, required this.animeTitle, required this.type, required this.typeDescription, required this.episodes});


  factory BangumiDetails.fromJson(Map<String, dynamic> json) =>
      _$BangumiDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$BangumiDetailsToJson(this);

}
