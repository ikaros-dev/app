// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SearchEpisodeDetails.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchEpisodeDetails _$SearchEpisodeDetailsFromJson(
        Map<String, dynamic> json) =>
    SearchEpisodeDetails(
      episodeId: (json['episodeId'] as num).toInt(),
      episodeTitle: json['episodeTitle'] as String?,
    );

Map<String, dynamic> _$SearchEpisodeDetailsToJson(
        SearchEpisodeDetails instance) =>
    <String, dynamic>{
      'episodeId': instance.episodeId,
      'episodeTitle': instance.episodeTitle,
    };
