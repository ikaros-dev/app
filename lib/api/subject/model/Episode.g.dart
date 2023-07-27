// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Episode _$EpisodeFromJson(Map<String, dynamic> json) => Episode(
      id: json['id'] as int,
      subjectId: json['subject_id'] as int,
      name: json['name'] as String,
      nameCn: json['name_cn'] as String?,
      description: json['description'] as String?,
      sequence: (json['sequence'] as num).toDouble(),
      resources: (json['resources'] as List<dynamic>?)
          ?.map((e) => EpisodeResource.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EpisodeToJson(Episode instance) => <String, dynamic>{
      'id': instance.id,
      'subject_id': instance.subjectId,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'description': instance.description,
      'sequence': instance.sequence,
      'resources': instance.resources,
    };
