import 'package:json_annotation/json_annotation.dart';

enum EpisodeGroup {
  @JsonValue("MAIN")
  MAIN,
  /**
   * PV.
   */
  @JsonValue("PROMOTION_VIDEO")
  PROMOTION_VIDEO,
  /**
   * OP.
   */
  @JsonValue("OPENING_SONG")
  OPENING_SONG,
  /**
   * ED.
   */
  @JsonValue("ENDING_SONG")
  ENDING_SONG,
  /**
   * SP.
   */
  @JsonValue("SPECIAL_PROMOTION")
  SPECIAL_PROMOTION,
  /**
   * ST.
   */
  @JsonValue("SMALL_THEATER")
  SMALL_THEATER,
  /**
   * Live.
   */
  @JsonValue("LIVE")
  LIVE,
  /**
   * commercial message, CM.
   */
  @JsonValue("COMMERCIAL_MESSAGE")
  COMMERCIAL_MESSAGE,
  @JsonValue("OTHER")
  OTHER;
}
