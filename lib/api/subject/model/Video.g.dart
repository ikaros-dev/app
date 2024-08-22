// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
      episodeId: (json['episode_id'] as num).toInt(),
      subjectId: (json['subject_id'] as num).toInt(),
      url: json['url'] as String,
      title: json['title'] as String?,
      subhead: json['subhead'] as String?,
      subtitleUrls: (json['subtitleUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
      'episode_id': instance.episodeId,
      'subject_id': instance.subjectId,
      'url': instance.url,
      'title': instance.title,
      'subhead': instance.subhead,
      'subtitleUrls': instance.subtitleUrls,
    };
