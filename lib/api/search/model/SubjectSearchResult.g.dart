// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SubjectSearchResult.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectSearchResult _$SubjectSearchResultFromJson(Map<String, dynamic> json) =>
    SubjectSearchResult(
      hits: (json['hits'] as List<dynamic>)
          .map((e) => SubjectHint.fromJson(e as Map<String, dynamic>))
          .toList(),
      keyword: json['keyword'] as String,
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      processingTimeMillis: (json['processingTimeMillis'] as num).toDouble(),
    );

Map<String, dynamic> _$SubjectSearchResultToJson(
        SubjectSearchResult instance) =>
    <String, dynamic>{
      'hits': instance.hits,
      'keyword': instance.keyword,
      'total': instance.total,
      'limit': instance.limit,
      'processingTimeMillis': instance.processingTimeMillis,
    };
