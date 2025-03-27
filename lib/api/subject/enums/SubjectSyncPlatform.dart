import 'package:json_annotation/json_annotation.dart';

enum SubjectSyncPlatform {
  /// <a href="https://bgm.tv/">Bangumi 番组计划</a>.
  @JsonValue("BGM_TV")
  BGM_TV,
  /// <a href="https://www.themoviedb.org/">The Move Database(TMDb).</a>.
  @JsonValue("TMDB")
  TMDB,
  /// <a href="https://anidb.net/">AniDB</a>.
  @JsonValue("AniDB")
  AniDB,
  ///
  /// <a href="https://www.thetvdb.com/">tvdb</a>.
  @JsonValue("TVDB")
  TVDB,
  /// <a href="https://vndb.org/">The Visual Novel Database</a>.
  @JsonValue("VNDB")
  VNDB,

  /// <a href="https://www.douban.com/">豆瓣</a>.
  @JsonValue("DOU_BAN")
  DOU_BAN,
  /// other platform.
  @JsonValue("OTHER")
  OTHER;
}