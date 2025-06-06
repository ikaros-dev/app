import 'package:json_annotation/json_annotation.dart';

enum CollectionType {
  /// Not collection.
  @JsonValue("NOT")
  NOT,
  /// Wist watch.
  @JsonValue("WISH")
  WISH,
  /// Watching.
  @JsonValue("DOING")
  DOING,
  /// Watch done.
  @JsonValue("DONE")
  DONE,
  /// No time to watch it.
  @JsonValue("SHELVE")
  SHELVE,
  /// Discard it.
  @JsonValue("DISCARD")
  DISCARD;
}