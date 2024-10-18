// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Episode _$EpisodeFromJson(Map<String, dynamic> json) => Episode(
      id: (json['id'] as num).toInt(),
      subjectId: (json['subject_id'] as num).toInt(),
      name: json['name'] as String,
      nameCn: json['name_cn'] as String?,
      description: json['description'] as String?,
      sequence: (json['sequence'] as num).toDouble(),
      group: json['group'] as String?,
    );

Map<String, dynamic> _$EpisodeToJson(Episode instance) => <String, dynamic>{
      'id': instance.id,
      'subject_id': instance.subjectId,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'description': instance.description,
      'sequence': instance.sequence,
      'group': instance.group,
    };
