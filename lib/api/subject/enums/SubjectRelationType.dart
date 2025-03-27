import 'package:json_annotation/json_annotation.dart';

enum SubjectRelationType {
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
  @JsonValue("BEFORE")
  BEFORE,
  @JsonValue("AFTER")
  AFTER,
  @JsonValue("SAME_WORLDVIEW")
  SAME_WORLDVIEW,
  @JsonValue("ORIGINAL_SOUND_TRACK")
  ORIGINAL_SOUND_TRACK,
  @JsonValue("ORIGINAL_VIDEO_ANIMATION")
  ORIGINAL_VIDEO_ANIMATION,
  @JsonValue("ORIGINAL_ANIMATION_DISC")
  ORIGINAL_ANIMATION_DISC,
  @JsonValue("OTHER")
  OTHER;

}