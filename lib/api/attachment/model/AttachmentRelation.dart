import 'package:json_annotation/json_annotation.dart';


import '../enums/AttachmentRelationType.dart';

part 'AttachmentRelation.g.dart';

@JsonSerializable()
class AttachmentRelation {
  final String id;
  @JsonKey(name: "attachment_id")
  final String attachmentId;
  final AttachmentRelationType type;
  @JsonKey(name: "relation_attachment_id")
  final String relationAttachmentId;

  AttachmentRelation({
    required this.id, required this.attachmentId,
    required this.type, required this.relationAttachmentId
  });

  factory AttachmentRelation.fromJson(Map<String, dynamic> json) => _$AttachmentRelationFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentRelationToJson(this);
}