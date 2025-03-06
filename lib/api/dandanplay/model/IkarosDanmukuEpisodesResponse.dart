
import 'package:json_annotation/json_annotation.dart';

import 'SearchEpisodesAnime.dart';

part 'IkarosDanmukuEpisodesResponse.g.dart';

@JsonSerializable()
class IkarosDanmukuEpisodesResponse {
  /// 搜索结果（作品信息）列表
  final List<SearchEpisodesAnime> animes;

  IkarosDanmukuEpisodesResponse({required this.animes});



  factory IkarosDanmukuEpisodesResponse.fromJson(Map<String, dynamic> json) =>
      _$IkarosDanmukuEpisodesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$IkarosDanmukuEpisodesResponseToJson(this);
}