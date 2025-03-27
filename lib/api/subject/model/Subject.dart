import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

import '../enums/SubjectType.dart';

part 'Subject.g.dart';

@JsonSerializable()
class Subject {
  final int id;
  final SubjectType type;
  final String name;
  @JsonKey(name: "name_cn")
  final String? nameCn;
  final String? infobox;
  final String? summary;
  final bool nsfw;
  final String cover;
  final String? airTime;

  factory Subject.fromJson(Map<String, dynamic> json) =>
      _$SubjectFromJson(json);

  Subject(
      {required this.id,
      required this.type,
      required this.name,
      required this.nameCn,
      required this.infobox,
      required this.summary,
      required this.nsfw,
      required this.cover,
      required this.airTime});

  Map<String, dynamic> toJson() => _$SubjectToJson(this);
}
