import 'package:json_annotation/json_annotation.dart';

enum CollectionStatus {
  /**
   * Not collection.
   */
  @JsonValue(0)
  NOT,
  /**
   * Wist watch.
   */
  @JsonValue(1)
  WISH,
  /**
   * Watching.
   */
  @JsonValue(2)
  DOING,
  /**
   * Watch done.
   */
  @JsonValue(3)
  DONE,
  /**
   * No time to watch it.
   */
  @JsonValue(4)
  SHELVE,
  /**
   * Discard it.
   */
  @JsonValue(5)
  DISCARD;
}