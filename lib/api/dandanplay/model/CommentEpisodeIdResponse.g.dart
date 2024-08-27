// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommentEpisodeIdResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentEpisodeIdResponse _$CommentEpisodeIdResponseFromJson(
        Map<String, dynamic> json) =>
    CommentEpisodeIdResponse(
      count: (json['count'] as num).toInt(),
      comments: (json['comments'] as List<dynamic>)
          .map((e) => CommentEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CommentEpisodeIdResponseToJson(
        CommentEpisodeIdResponse instance) =>
    <String, dynamic>{
      'count': instance.count,
      'comments': instance.comments,
    };
