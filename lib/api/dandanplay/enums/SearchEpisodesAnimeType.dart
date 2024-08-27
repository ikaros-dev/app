
import 'package:json_annotation/json_annotation.dart';

/// 作品类型
enum SearchEpisodesAnimeType {
  @JsonValue("tvseries")
  tvseries,
  @JsonValue("tvspecial")
  tvspecial,
  @JsonValue("ova")
  ova,
  @JsonValue("movie")
  movie,
  @JsonValue("musicvideo")
  musicvideo,
  @JsonValue("web")
  web,
  @JsonValue("other")
  other,
  @JsonValue("jpmovie")
  jpmovie,
  @JsonValue("jpdrama")
  jpdrama,
  @JsonValue("unknown")
  unknown;
}