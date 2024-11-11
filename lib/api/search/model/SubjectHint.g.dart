// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SubjectHint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectHint _$SubjectHintFromJson(Map<String, dynamic> json) => SubjectHint(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      nameCn: json['nameCn'] as String?,
      infobox: json['infobox'] as String?,
      summary: json['summary'] as String?,
      airTime: json['airTime'] as String?,
      nsfw: json['nsfw'] as bool,
      type: $enumDecode(_$SubjectTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$SubjectHintToJson(SubjectHint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nameCn': instance.nameCn,
      'infobox': instance.infobox,
      'summary': instance.summary,
      'airTime': instance.airTime,
      'nsfw': instance.nsfw,
      'type': _$SubjectTypeEnumMap[instance.type]!,
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
