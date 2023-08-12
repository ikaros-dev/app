import 'package:json_annotation/json_annotation.dart';

import 'EpisodeResource.dart';

part 'Episode.g.dart';

@JsonSerializable()
class Episode {
  final int id;
  @JsonKey(name: "subject_id")
  final int subjectId;
  final String name;
  @JsonKey(name: "name_cn")
  final String? nameCn;
  final String? description;
  final int sequence;
  final String? group;
  final List<EpisodeResource>? resources;

  Episode({
    required this.id, required this.subjectId, required this.name,
    this.nameCn, this.description, required this.sequence, this.group, this.resources
});

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeToJson(this);
}