// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PagingWrap.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PagingWrap _$PagingWrapFromJson(Map<String, dynamic> json) => PagingWrap(
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$PagingWrapToJson(PagingWrap instance) =>
    <String, dynamic>{
      'page': instance.page,
      'size': instance.size,
      'total': instance.total,
      'items': instance.items,
    };
