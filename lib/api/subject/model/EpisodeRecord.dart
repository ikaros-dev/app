import 'package:json_annotation/json_annotation.dart';

import 'Episode.dart';
import 'EpisodeResource.dart';

part 'EpisodeRecord.g.dart';

@JsonSerializable()
class EpisodeRecord {
  final Episode episode;
  final List<EpisodeResource> resources;

  EpisodeRecord({
    required this.episode, required this.resources
});

  factory EpisodeRecord.fromJson(Map<String, dynamic> json) => _$EpisodeRecordFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeRecordToJson(this);
}