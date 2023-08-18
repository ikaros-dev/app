// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EpisodeCollection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpisodeCollection _$EpisodeCollectionFromJson(Map<String, dynamic> json) =>
    EpisodeCollection(
      progress: json['progress'] as int?,
      id: json['id'] as int,
      userId: json['user_id'] as int,
      episodeId: json['episode_id'] as int,
      finish: json['finish'] as bool?,
      duration: json['duration'] as int?,
      subjectId: json['subject_id'] as int?,
      name: json['name'] as String,
      nameCn: json['name_cn'] as String?,
      description: json['description'] as String?,
      sequence: json['sequence'] as int,
      group: $enumDecode(_$EpisodeGroupEnumMap, json['ep_group']),
    );

Map<String, dynamic> _$EpisodeCollectionToJson(EpisodeCollection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'episode_id': instance.episodeId,
      'finish': instance.finish,
      'progress': instance.progress,
      'duration': instance.duration,
      'subject_id': instance.subjectId,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'description': instance.description,
      'sequence': instance.sequence,
      'ep_group': _$EpisodeGroupEnumMap[instance.group]!,
    };

const _$EpisodeGroupEnumMap = {
  EpisodeGroup.MAIN: 'MAIN',
  EpisodeGroup.PROMOTION_VIDEO: 'PROMOTION_VIDEO',
  EpisodeGroup.OPENING_SONG: 'OPENING_SONG',
  EpisodeGroup.ENDING_SONG: 'ENDING_SONG',
  EpisodeGroup.SPECIAL_PROMOTION: 'SPECIAL_PROMOTION',
  EpisodeGroup.SMALL_THEATER: 'SMALL_THEATER',
  EpisodeGroup.LIVE: 'LIVE',
  EpisodeGroup.COMMERCIAL_MESSAGE: 'COMMERCIAL_MESSAGE',
  EpisodeGroup.OTHER: 'OTHER',
};
