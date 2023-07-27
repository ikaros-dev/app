// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EpisodeResource.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpisodeResource _$EpisodeResourceFromJson(Map<String, dynamic> json) =>
    EpisodeResource(
      fileId: json['file_id'] as int,
      episodeId: json['episode_id'] as int,
      url: json['url'] as String,
      canRead: json['canRead'] as bool?,
      name: json['name'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toSet(),
    );

Map<String, dynamic> _$EpisodeResourceToJson(EpisodeResource instance) =>
    <String, dynamic>{
      'file_id': instance.fileId,
      'episode_id': instance.episodeId,
      'url': instance.url,
      'canRead': instance.canRead,
      'name': instance.name,
      'tags': instance.tags?.toList(),
    };
