
import 'package:ikaros/api/search/model/SubjectHint.dart';
import 'package:json_annotation/json_annotation.dart';

part 'SubjectSearchResult.g.dart';

@JsonSerializable()
class SubjectSearchResult {
  final List<SubjectHint> hits;
  final String keyword;
  final int total;
  final int limit;
  final double processingTimeMillis;

  SubjectSearchResult({required this.hits, required this.keyword, required this.total, required this.limit, required this.processingTimeMillis});

  factory SubjectSearchResult.fromJson(Map<String, dynamic> json) => _$SubjectSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectSearchResultToJson(this);
}