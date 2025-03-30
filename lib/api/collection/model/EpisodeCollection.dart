import 'package:ikaros/api/subject/enums/EpisodeGroup.dart';
import 'package:json_annotation/json_annotation.dart';

part 'EpisodeCollection.g.dart';

@JsonSerializable()
class EpisodeCollection {
  final int id;
  @JsonKey(name: "user_id")
  final int userId;
  @JsonKey(name: "episode_id")
  final int episodeId;

  /// 是否已经看过.
  final bool? finish;

  /// 观看进度，时间戳，单位 milliseconds.
  final int? progress;

  /// 总时长，时间戳.
  final int? duration;

  @JsonKey(name: "subject_id")
  final int? subjectId;
  final String? name;
  @JsonKey(name: "name_cn")
  final String? nameCn;
  final String? description;
  @JsonKey(name: "ep_group")
  final EpisodeGroup? group;
  @JsonKey(name: "update_time")
  final String? updateTime;

  EpisodeCollection({this.progress, required this.id, required this.userId,
    required this.episodeId, this.finish, this.duration, this.subjectId,
    this.name, this.nameCn, this.description,
    this.group, this.updateTime});


  factory EpisodeCollection.fromJson(Map<String, dynamic> json) => _$EpisodeCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeCollectionToJson(this);

}
