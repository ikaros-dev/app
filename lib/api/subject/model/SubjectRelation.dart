import 'dart:core';

import 'package:ikaros/api/subject/enums/SubjectRelationType.dart';
import 'package:json_annotation/json_annotation.dart';

part 'SubjectRelation.g.dart';

@JsonSerializable()
class SubjectRelation {
  final int subject;
  @JsonKey(name: "relation_type")
  final SubjectRelationType relationType;
  @JsonKey(name: "relation_subjects")
  final List<int> relationSubjects;

  SubjectRelation({required this.subject, required this.relationType, required this.relationSubjects});

  factory SubjectRelation.fromJson(Map<String, dynamic> json) => _$SubjectRelationFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectRelationToJson(this);
}