import 'package:json_annotation/json_annotation.dart';

part 'PagingWrap.g.dart';

@JsonSerializable()
class PagingWrap {
  final int page;
  final int size;
  final int total;
  final List<Map<String, dynamic>> items;

  PagingWrap({required this.page, required this.size, required this.total, required this.items});

  /// Connect the generated [_$PagingWrapToJson] function to the `fromJson`
  /// factory.
  factory PagingWrap.fromJson(Map<String, dynamic> json) => _$PagingWrapFromJson(json);

  /// Connect the generated [_$PagingWrapToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PagingWrapToJson(this);
}