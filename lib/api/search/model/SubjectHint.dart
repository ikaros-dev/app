import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:json_annotation/json_annotation.dart';

part 'SubjectHint.g.dart';

@JsonSerializable()
class SubjectHint {
  final int id;
  final String name;
  final String? nameCn;
  final String? infobox;
  final String? summary;
  final String? airTime;
  final bool nsfw;
  final SubjectType type;

  factory SubjectHint.fromJson(Map<String, dynamic> json) =>
      _$SubjectHintFromJson(json);

  SubjectHint(
      {required this.id,
      required this.name,
      required this.nameCn,
      required this.infobox,
      required this.summary,
      required this.airTime,
      required this.nsfw,
      required this.type});

  Map<String, dynamic> toJson() => _$SubjectHintToJson(this);
}
