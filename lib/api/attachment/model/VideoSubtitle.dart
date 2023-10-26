import 'package:json_annotation/json_annotation.dart';


part 'VideoSubtitle.g.dart';

@JsonSerializable()
class VideoSubtitle {
  @JsonKey(name: "attachment_id")
  final int attachmentId;
  final String name;
  final String url;

  VideoSubtitle({
    required this.attachmentId, required this.name,
    required this.url
  });

  factory VideoSubtitle.fromJson(Map<String, dynamic> json) => _$VideoSubtitleFromJson(json);

  Map<String, dynamic> toJson() => _$VideoSubtitleToJson(this);
}