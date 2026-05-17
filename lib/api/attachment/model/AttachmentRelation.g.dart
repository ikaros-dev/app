// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AttachmentRelation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentRelation _$AttachmentRelationFromJson(Map<String, dynamic> json) =>
    AttachmentRelation(
      id: json['id'] as String,
      attachmentId: json['attachment_id'] as String,
      type: $enumDecode(_$AttachmentRelationTypeEnumMap, json['type']),
      relationAttachmentId: json['relation_attachment_id'] as String,
    );

Map<String, dynamic> _$AttachmentRelationToJson(AttachmentRelation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'attachment_id': instance.attachmentId,
      'type': _$AttachmentRelationTypeEnumMap[instance.type]!,
      'relation_attachment_id': instance.relationAttachmentId,
    };

const _$AttachmentRelationTypeEnumMap = {
  AttachmentRelationType.VIDEO_SUBTITLE: 'VIDEO_SUBTITLE',
};
