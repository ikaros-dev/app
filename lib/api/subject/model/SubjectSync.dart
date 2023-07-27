import 'package:ikaros/api/subject/enums/SubjectSyncPlatform.dart';
import 'package:json_annotation/json_annotation.dart';

part 'SubjectSync.g.dart';

@JsonSerializable()
class SubjectSync {
  final int subjectId;
  final SubjectSyncPlatform platform;
  final String platformId;

  SubjectSync(
      {required this.subjectId,
      required this.platform,
      required this.platformId});

  factory SubjectSync.fromJson(Map<String, dynamic> json) => _$SubjectSyncFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectSyncToJson(this);
}
