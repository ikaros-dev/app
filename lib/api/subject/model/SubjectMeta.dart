import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

import '../enums/SubjectType.dart';

import '../enums/CollectionType.dart';

part 'SubjectMeta.g.dart';

@JsonSerializable()
class SubjectMeta {
  final int id;
  final SubjectType type;
  final String name;
  @JsonKey(name: "name_cn")
  final String? nameCn;
  final String? infobox;
  final String? summary;
  final bool nsfw;
  final String cover;
  final bool? canRead;
  @JsonKey(name: "collection_status")
  final CollectionType? collectionType;

  SubjectMeta({required this.id, required this.type, required this.name,
  this.nameCn, this.infobox, this.summary, required this.nsfw,
  required this.cover, this.canRead, required this.collectionType});

  factory SubjectMeta.fromJson(Map<String, dynamic> json) => _$SubjectMetaFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectMetaToJson(this);
}