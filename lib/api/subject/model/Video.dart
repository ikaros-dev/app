
import 'package:json_annotation/json_annotation.dart';

part 'Video.g.dart';

@JsonSerializable()
class Video {
  @JsonKey(name: "episode_id")
  final int episodeId;
  @JsonKey(name: "subject_id")
  final int subjectId;
  final String url;
  final String? title;
  final String? subhead;
  final List<String>? subtitleUrls;

  Video({required this.episodeId, required this.subjectId,
  required this.url, this.title, this.subhead, this.subtitleUrls});

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);

  Map<String, dynamic> toJson() => _$VideoToJson(this);
}