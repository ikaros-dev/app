
import 'package:json_annotation/json_annotation.dart';

import 'CommentEpisode.dart';

part 'CommentEpisodeIdResponse.g.dart';

@JsonSerializable()
class CommentEpisodeIdResponse {
  final int count;
  final List<CommentEpisode> comments;

  CommentEpisodeIdResponse({required this.count, required this.comments});

  factory CommentEpisodeIdResponse.fromJson(Map<String, dynamic> json) =>
      _$CommentEpisodeIdResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CommentEpisodeIdResponseToJson(this);
}