import 'package:json_annotation/json_annotation.dart';

enum SubjectType {
  @JsonValue("ANIME")
  ANIME,
  @JsonValue("COMIC")
  COMIC,
  @JsonValue("GAME")
  GAME,
  @JsonValue("MUSIC")
  MUSIC,
  @JsonValue("NOVEL")
  NOVEL,
  @JsonValue("REAL")
  REAL,
  @JsonValue("OTHER")
  OTHER;
}