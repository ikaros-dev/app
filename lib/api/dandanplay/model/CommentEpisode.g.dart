// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommentEpisode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentEpisode _$CommentEpisodeFromJson(Map<String, dynamic> json) =>
    CommentEpisode(
      cid: (json['cid'] as num).toInt(),
      p: json['p'] as String,
      m: json['m'] as String,
    );

Map<String, dynamic> _$CommentEpisodeToJson(CommentEpisode instance) =>
    <String, dynamic>{
      'cid': instance.cid,
      'p': instance.p,
      'm': instance.m,
    };
