// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SubjectRelation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectRelation _$SubjectRelationFromJson(Map<String, dynamic> json) =>
    SubjectRelation(
      subject: (json['subject'] as num).toInt(),
      relationType:
          $enumDecode(_$SubjectRelationTypeEnumMap, json['relation_type']),
      relationSubjects: (json['relation_subjects'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$SubjectRelationToJson(SubjectRelation instance) =>
    <String, dynamic>{
      'subject': instance.subject,
      'relation_type': _$SubjectRelationTypeEnumMap[instance.relationType]!,
      'relation_subjects': instance.relationSubjects,
    };

const _$SubjectRelationTypeEnumMap = {
  SubjectRelationType.ANIME: 'ANIME',
  SubjectRelationType.COMIC: 'COMIC',
  SubjectRelationType.GAME: 'GAME',
  SubjectRelationType.MUSIC: 'MUSIC',
  SubjectRelationType.NOVEL: 'NOVEL',
  SubjectRelationType.REAL: 'REAL',
  SubjectRelationType.BEFORE: 'BEFORE',
  SubjectRelationType.AFTER: 'AFTER',
  SubjectRelationType.SAME_WORLDVIEW: 'SAME_WORLDVIEW',
  SubjectRelationType.ORIGINAL_SOUND_TRACK: 'ORIGINAL_SOUND_TRACK',
  SubjectRelationType.ORIGINAL_VIDEO_ANIMATION: 'ORIGINAL_VIDEO_ANIMATION',
  SubjectRelationType.ORIGINAL_ANIMATION_DISC: 'ORIGINAL_ANIMATION_DISC',
  SubjectRelationType.OTHER: 'OTHER',
};
