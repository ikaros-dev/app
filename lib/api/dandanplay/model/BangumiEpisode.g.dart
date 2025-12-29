// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BangumiEpisode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BangumiEpisode _$BangumiEpisodeFromJson(Map<String, dynamic> json) =>
    BangumiEpisode(
      (json['animeId'] as num).toInt(),
      (json['seasonId'] as num).toInt(),
      json['bgmtvSubjectId'] as String,
      json['episodeNumber'] as String,
      json['lastWatched'] as String?,
      json['airDate'] as String?,
      episodeId: (json['episodeId'] as num).toInt(),
      episodeTitle: json['episodeTitle'] as String?,
    );

Map<String, dynamic> _$BangumiEpisodeToJson(BangumiEpisode instance) =>
    <String, dynamic>{
      'episodeId': instance.episodeId,
      'animeId': instance.animeId,
      'seasonId': instance.seasonId,
      'bgmtvSubjectId': instance.bgmtvSubjectId,
      'episodeNumber': instance.episodeNumber,
      'episodeTitle': instance.episodeTitle,
      'lastWatched': instance.lastWatched,
      'airDate': instance.airDate,
    };
