// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SubjectSync.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectSync _$SubjectSyncFromJson(Map<String, dynamic> json) => SubjectSync(
      subjectId: (json['subjectId'] as num).toInt(),
      platform: $enumDecode(_$SubjectSyncPlatformEnumMap, json['platform']),
      platformId: json['platformId'] as String,
    );

Map<String, dynamic> _$SubjectSyncToJson(SubjectSync instance) =>
    <String, dynamic>{
      'subjectId': instance.subjectId,
      'platform': _$SubjectSyncPlatformEnumMap[instance.platform]!,
      'platformId': instance.platformId,
    };

const _$SubjectSyncPlatformEnumMap = {
  SubjectSyncPlatform.BGM_TV: 'BGM_TV',
  SubjectSyncPlatform.TMDB: 'TMDB',
  SubjectSyncPlatform.AniDB: 'AniDB',
  SubjectSyncPlatform.TVDB: 'TVDB',
  SubjectSyncPlatform.VNDB: 'VNDB',
  SubjectSyncPlatform.DOU_BAN: 'DOU_BAN',
  SubjectSyncPlatform.OTHER: 'OTHER',
};
