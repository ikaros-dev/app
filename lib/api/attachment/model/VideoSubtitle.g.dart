// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'VideoSubtitle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoSubtitle _$VideoSubtitleFromJson(Map<String, dynamic> json) =>
    VideoSubtitle(
      attachmentId: json['attachment_id'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$VideoSubtitleToJson(VideoSubtitle instance) =>
    <String, dynamic>{
      'attachment_id': instance.attachmentId,
      'name': instance.name,
      'url': instance.url,
    };
