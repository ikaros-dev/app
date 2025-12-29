
import 'package:json_annotation/json_annotation.dart';

import 'BangumiDetails.dart';
import 'SearchEpisodesAnime.dart';

part 'IkarosDanmukuBangumiResponse.g.dart';

@JsonSerializable()
class IkarosDanmukuBangumiResponse {
  /// 搜索结果（作品信息）列表
  final BangumiDetails data;

  IkarosDanmukuBangumiResponse(this.data);



  factory IkarosDanmukuBangumiResponse.fromJson(Map<String, dynamic> json) =>
      _$IkarosDanmukuBangumiResponseFromJson(json);

  Map<String, dynamic> toJson() => _$IkarosDanmukuBangumiResponseToJson(this);
}