import 'dart:core';

import 'package:ikaros/api/subject/model/SubjectSync.dart';
import 'package:json_annotation/json_annotation.dart';

import '../enums/SubjectType.dart';
import 'Episode.dart';

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

  Subject({required this.id, required this.type, required this.name,
  this.nameCn, this.infobox, this.summary, required this.nsfw,
  required this.cover});

  factory Subject.fromJson(Map<String, dynamic> json) => _$SubjectFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectToJson(this);
}