
import 'package:json_annotation/json_annotation.dart';

import 'SearchEpisodesAnime.dart';

part 'SearchEpisodesResponse.g.dart';

@JsonSerializable()
class SearchEpisodesResponse {
  /// 是否有更多未显示的搜索结果。当返回的搜索结果过多时此值为true ,
  final bool hasMore;
  /// 搜索结果（作品信息）列表
  final List<SearchEpisodesAnime> animes;
  /// 错误代码，0表示没有发生错误，非0表示有错误，详细信息会包含在errorMessage属性中
  final int errorCode;
  /// 接口是否调用成功
  final bool success;
  /// 当发生错误时，说明错误具体原因
  final String? errorMessage;

  SearchEpisodesResponse({required this.hasMore, required this.animes, required this.errorCode, required this.success, required this.errorMessage});



  factory SearchEpisodesResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchEpisodesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchEpisodesResponseToJson(this);
}