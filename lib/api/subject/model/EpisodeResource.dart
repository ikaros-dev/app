import 'package:json_annotation/json_annotation.dart';

part 'EpisodeResource.g.dart';

@JsonSerializable()
class EpisodeResource {
  final int attachmentId;
  final int parentAttachmentId;
  final int episodeId;
  final String url;
  final bool? canRead;
  final String name;
  final Set<String>? tags;

  EpisodeResource(
      {required this.attachmentId,
      required this.parentAttachmentId,
      required this.episodeId,
      required this.url,
      this.canRead,
      required this.name,
      this.tags});

  factory EpisodeResource.fromJson(Map<String, dynamic> json) =>
      _$EpisodeResourceFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeResourceToJson(this);
}
