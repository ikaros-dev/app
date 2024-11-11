// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subject _$SubjectFromJson(Map<String, dynamic> json) => Subject(
      id: (json['id'] as num).toInt(),
      type: $enumDecode(_$SubjectTypeEnumMap, json['type']),
      name: json['name'] as String,
      nameCn: json['name_cn'] as String?,
      infobox: json['infobox'] as String?,
      summary: json['summary'] as String?,
      nsfw: json['nsfw'] as bool,
      cover: json['cover'] as String,
      airTime: json['airTime'] as String?,
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
      'airTime': instance.airTime,
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
