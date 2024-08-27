
import 'package:ikaros/api/dandanplay/enums/SearchEpisodesAnimeType.dart';
import 'package:json_annotation/json_annotation.dart';

import 'SearchEpisodeDetails.dart';

part 'SearchEpisodesAnime.g.dart';

@JsonSerializable()
class SearchEpisodesAnime {
  /// 作品编号
  final int animeId;
  /// 作品标题
  final String? animeTitle;
  /// 作品类型
  final SearchEpisodesAnimeType type;
  /// 类型描述
  final String? typeDescription;
  /// 此作品的剧集列表
  final List<SearchEpisodeDetails> episodes;

  SearchEpisodesAnime({required this.animeId, required this.animeTitle, required this.type, required this.typeDescription, required this.episodes});


  factory SearchEpisodesAnime.fromJson(Map<String, dynamic> json) =>
      _$SearchEpisodesAnimeFromJson(json);

  Map<String, dynamic> toJson() => _$SearchEpisodesAnimeToJson(this);

}
