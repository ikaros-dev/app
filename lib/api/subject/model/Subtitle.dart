import 'package:json_annotation/json_annotation.dart';

part 'Subtitle.g.dart';

@JsonSerializable()
class Subtitle {
  @JsonKey(name: "file_id")
  final int fileId;
  final String name;
  final String url;
  final String? language;

  Subtitle({
    required this.fileId, required this.name,
    required this.url, this.language
  });

  factory Subtitle.fromJson(Map<String, dynamic> json) => _$SubtitleFromJson(json);

  Map<String, dynamic> toJson() => _$SubtitleToJson(this);
}