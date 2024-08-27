// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SearchEpisodesAnime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchEpisodesAnime _$SearchEpisodesAnimeFromJson(Map<String, dynamic> json) =>
    SearchEpisodesAnime(
      animeId: (json['animeId'] as num).toInt(),
      animeTitle: json['animeTitle'] as String?,
      type: $enumDecode(_$SearchEpisodesAnimeTypeEnumMap, json['type']),
      typeDescription: json['typeDescription'] as String?,
      episodes: (json['episodes'] as List<dynamic>)
          .map((e) => SearchEpisodeDetails.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchEpisodesAnimeToJson(
        SearchEpisodesAnime instance) =>
    <String, dynamic>{
      'animeId': instance.animeId,
      'animeTitle': instance.animeTitle,
      'type': _$SearchEpisodesAnimeTypeEnumMap[instance.type]!,
      'typeDescription': instance.typeDescription,
      'episodes': instance.episodes,
    };

const _$SearchEpisodesAnimeTypeEnumMap = {
  SearchEpisodesAnimeType.tvseries: 'tvseries',
  SearchEpisodesAnimeType.tvspecial: 'tvspecial',
  SearchEpisodesAnimeType.ova: 'ova',
  SearchEpisodesAnimeType.movie: 'movie',
  SearchEpisodesAnimeType.musicvideo: 'musicvideo',
  SearchEpisodesAnimeType.web: 'web',
  SearchEpisodesAnimeType.other: 'other',
  SearchEpisodesAnimeType.jpmovie: 'jpmovie',
  SearchEpisodesAnimeType.jpdrama: 'jpdrama',
  SearchEpisodesAnimeType.unknown: 'unknown',
};
