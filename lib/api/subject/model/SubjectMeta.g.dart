// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SubjectMeta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectMeta _$SubjectMetaFromJson(Map<String, dynamic> json) => SubjectMeta(
      id: (json['id'] as num).toInt(),
      type: $enumDecode(_$SubjectTypeEnumMap, json['type']),
      name: json['name'] as String,
      nameCn: json['name_cn'] as String?,
      infobox: json['infobox'] as String?,
      summary: json['summary'] as String?,
      nsfw: json['nsfw'] as bool,
      cover: json['cover'] as String,
      canRead: json['canRead'] as bool?,
      collectionType: $enumDecodeNullable(
          _$CollectionTypeEnumMap, json['collection_status']),
    );

Map<String, dynamic> _$SubjectMetaToJson(SubjectMeta instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SubjectTypeEnumMap[instance.type]!,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'infobox': instance.infobox,
      'summary': instance.summary,
      'nsfw': instance.nsfw,
      'cover': instance.cover,
      'canRead': instance.canRead,
      'collection_status': _$CollectionTypeEnumMap[instance.collectionType],
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

const _$CollectionTypeEnumMap = {
  CollectionType.NOT: 'NOT',
  CollectionType.WISH: 'WISH',
  CollectionType.DOING: 'DOING',
  CollectionType.DONE: 'DONE',
  CollectionType.SHELVE: 'SHELVE',
  CollectionType.DISCARD: 'DISCARD',
};
