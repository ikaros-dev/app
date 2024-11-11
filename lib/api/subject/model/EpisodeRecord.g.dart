// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EpisodeRecord.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpisodeRecord _$EpisodeRecordFromJson(Map<String, dynamic> json) =>
    EpisodeRecord(
      episode: Episode.fromJson(json['episode'] as Map<String, dynamic>),
      resources: (json['resources'] as List<dynamic>)
          .map((e) => EpisodeResource.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EpisodeRecordToJson(EpisodeRecord instance) =>
    <String, dynamic>{
      'episode': instance.episode,
      'resources': instance.resources,
    };
