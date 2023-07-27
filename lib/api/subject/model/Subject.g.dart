// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subject _$SubjectFromJson(Map<String, dynamic> json) => Subject(
      id: json['id'] as int,
      type: $enumDecode(_$SubjectTypeEnumMap, json['type']),
      name: json['name'] as String,
      nameCn: json['name_cn'] as String?,
      infobox: json['infobox'] as String?,
      summary: json['summary'] as String?,
      nsfw: json['nsfw'] as bool,
      cover: json['cover'] as String,
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalEpisodes: json['total_episodes'] as int?,
      syncs: (json['syncs'] as List<dynamic>?)
          ?.map((e) => SubjectSync.fromJson(e as Map<String, dynamic>))
          .toList(),
      canRead: json['canRead'] as bool?,
    );

Map<String, dynamic> _$SubjectToJson(Subject instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$SubjectTypeEnumMap[instance.type]!,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'infobox': instance.infobox,
      'summary': instance.summary,
      'nsfw': instance.nsfw,
      'cover': instance.cover,
      'episodes': instance.episodes,
      'total_episodes': instance.totalEpisodes,
      'syncs': instance.syncs,
      'canRead': instance.canRead,
    };

const _$SubjectTypeEnumMap = {
  SubjectType.ANIME: 'ANIME',
  SubjectType.COMIC: 'COMIC',
  SubjectType.GAME: 'GAME',
  SubjectType.MUSIC: 'MUSIC',
  SubjectType.NOVEL: 'NOVEL',
  SubjectType.REAL: 'REAL',
  SubjectType.OTHER: 'OTHER',
};
