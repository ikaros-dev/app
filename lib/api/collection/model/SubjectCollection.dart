
import 'package:ikaros/api/collection/enums/CollectionType.dart';
import 'package:ikaros/api/subject/enums/SubjectType.dart';
import 'package:json_annotation/json_annotation.dart';

part 'SubjectCollection.g.dart';

@JsonSerializable()
class SubjectCollection {
  final int id;
  @JsonKey(name: "user_id")
  final int userId;
  @JsonKey(name: "subject_id")
  final int subjectId;
  final CollectionType type;

  /**
   * User main group episode watching progress.
   */
  @JsonKey(name: "main_ep_progress")
  final int? mainEpisodeProgress;

  /**
   * Whether it can be accessed without login.
   */
  @JsonKey(name: "is_private")
  final bool isPrivate;

  @JsonKey(name: "subject_type")
  final SubjectType? subjectType;
  final  String name;
  @JsonKey(name: "name_cn")
  final String? nameCn;
  final String? infobox;
  final String? summary;
  /**
   * Not Safe/Suitable For Work.
   */
  final bool nsfw;
  final String cover;

  SubjectCollection({required this.id, required this.userId, required this.subjectId,
  required this.type, this.mainEpisodeProgress, required this.isPrivate, this.subjectType,
  required this.name, this.nameCn, this.infobox, this.summary, required this.nsfw, required this.cover});


  factory SubjectCollection.fromJson(Map<String, dynamic> json) => _$SubjectCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectCollectionToJson(this);

}