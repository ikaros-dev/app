import 'package:json_annotation/json_annotation.dart';

part 'User.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String password;
  final String avatar;
  final String? nickname;
  final String? introduce;
  final String? telephone;
  final String? site;
  final String? email;

  User(
      {required this.id,
        required this.username,
        required this.password,
        required this.avatar,
        this.nickname,
        this.introduce,
        this.telephone,
        this.site,
        this.email});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);


  Map<String, dynamic> toJson() => _$UserToJson(this);
}
