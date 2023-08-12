// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Subtitle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subtitle _$SubtitleFromJson(Map<String, dynamic> json) => Subtitle(
      fileId: json['file_id'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
      language: json['language'] as String?,
    );

Map<String, dynamic> _$SubtitleToJson(Subtitle instance) => <String, dynamic>{
      'file_id': instance.fileId,
      'name': instance.name,
      'url': instance.url,
      'language': instance.language,
    };
