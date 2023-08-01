import 'package:json_annotation/json_annotation.dart';

part 'EpisodeResource.g.dart';

@JsonSerializable()
class EpisodeResource {
  @JsonKey(name: "file_id")
  final int fileId;
  @JsonKey(name: "episode_id")
  final int episodeId;
  final String url;
  final bool? canRead;
  final String name;
  final String? subtitleUrl;
  final Set<String>? tags;

  EpisodeResource(
      {required this.fileId,
      required this.episodeId,
      required this.url,
      this.canRead,
      required this.name,
      this.subtitleUrl,
      this.tags});

  factory EpisodeResource.fromJson(Map<String, dynamic> json) =>
      _$EpisodeResourceFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeResourceToJson(this);
}
