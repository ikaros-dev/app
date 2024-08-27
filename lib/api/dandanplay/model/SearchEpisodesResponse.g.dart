// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SearchEpisodesResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchEpisodesResponse _$SearchEpisodesResponseFromJson(
        Map<String, dynamic> json) =>
    SearchEpisodesResponse(
      hasMore: json['hasMore'] as bool,
      animes: (json['animes'] as List<dynamic>)
          .map((e) => SearchEpisodesAnime.fromJson(e as Map<String, dynamic>))
          .toList(),
      errorCode: (json['errorCode'] as num).toInt(),
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$SearchEpisodesResponseToJson(
        SearchEpisodesResponse instance) =>
    <String, dynamic>{
      'hasMore': instance.hasMore,
      'animes': instance.animes,
      'errorCode': instance.errorCode,
      'success': instance.success,
      'errorMessage': instance.errorMessage,
    };
