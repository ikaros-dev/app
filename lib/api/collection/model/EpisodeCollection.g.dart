// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EpisodeCollection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpisodeCollection _$EpisodeCollectionFromJson(Map<String, dynamic> json) =>
    EpisodeCollection(
      progress: (json['progress'] as num?)?.toInt(),
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      episodeId: (json['episode_id'] as num).toInt(),
      finish: json['finish'] as bool?,
      duration: (json['duration'] as num?)?.toInt(),
      subjectId: (json['subject_id'] as num?)?.toInt(),
      name: json['name'] as String,
      nameCn: json['name_cn'] as String?,
      description: json['description'] as String?,
      group: $enumDecode(_$EpisodeGroupEnumMap, json['ep_group']),
      updateTime: json['update_time'] as String?,
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
      'ep_group': _$EpisodeGroupEnumMap[instance.group]!,
      'update_time': instance.updateTime,
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
  EpisodeGroup.ORIGINAL_SOUND_TRACK: 'ORIGINAL_SOUND_TRACK',
  EpisodeGroup.ORIGINAL_VIDEO_ANIMATION: 'ORIGINAL_VIDEO_ANIMATION',
  EpisodeGroup.ORIGINAL_ANIMATION_DISC: 'ORIGINAL_ANIMATION_DISC',
  EpisodeGroup.MUSIC_DIST1: 'MUSIC_DIST1',
  EpisodeGroup.MUSIC_DIST2: 'MUSIC_DIST2',
  EpisodeGroup.MUSIC_DIST3: 'MUSIC_DIST3',
  EpisodeGroup.MUSIC_DIST4: 'MUSIC_DIST4',
  EpisodeGroup.MUSIC_DIST5: 'MUSIC_DIST5',
  EpisodeGroup.OTHER: 'OTHER',
};
