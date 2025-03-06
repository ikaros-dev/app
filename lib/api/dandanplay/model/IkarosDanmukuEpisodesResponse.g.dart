// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'IkarosDanmukuEpisodesResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IkarosDanmukuEpisodesResponse _$IkarosDanmukuEpisodesResponseFromJson(
        Map<String, dynamic> json) =>
    IkarosDanmukuEpisodesResponse(
      animes: (json['animes'] as List<dynamic>)
          .map((e) => SearchEpisodesAnime.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$IkarosDanmukuEpisodesResponseToJson(
        IkarosDanmukuEpisodesResponse instance) =>
    <String, dynamic>{
      'animes': instance.animes,
    };
