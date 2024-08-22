// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SubjectCollection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectCollection _$SubjectCollectionFromJson(Map<String, dynamic> json) =>
    SubjectCollection(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      subjectId: (json['subject_id'] as num).toInt(),
      type: $enumDecode(_$CollectionTypeEnumMap, json['type']),
      mainEpisodeProgress: (json['main_ep_progress'] as num?)?.toInt(),
      isPrivate: json['is_private'] as bool,
      subjectType:
          $enumDecodeNullable(_$SubjectTypeEnumMap, json['subject_type']),
      name: json['name'] as String,
      nameCn: json['name_cn'] as String?,
      infobox: json['infobox'] as String?,
      summary: json['summary'] as String?,
      nsfw: json['nsfw'] as bool,
      cover: json['cover'] as String,
    );

Map<String, dynamic> _$SubjectCollectionToJson(SubjectCollection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'subject_id': instance.subjectId,
      'type': _$CollectionTypeEnumMap[instance.type]!,
      'main_ep_progress': instance.mainEpisodeProgress,
      'is_private': instance.isPrivate,
      'subject_type': _$SubjectTypeEnumMap[instance.subjectType],
      'name': instance.name,
      'name_cn': instance.nameCn,
      'infobox': instance.infobox,
      'summary': instance.summary,
      'nsfw': instance.nsfw,
      'cover': instance.cover,
    };

const _$CollectionTypeEnumMap = {
  CollectionType.WISH: 'WISH',
  CollectionType.DOING: 'DOING',
  CollectionType.DONE: 'DONE',
  CollectionType.SHELVE: 'SHELVE',
  CollectionType.DISCARD: 'DISCARD',
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
