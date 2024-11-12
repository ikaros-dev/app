// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'User.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      password: json['password'] as String,
      avatar: json['avatar'] as String,
      nickname: json['nickname'] as String?,
      introduce: json['introduce'] as String?,
      telephone: json['telephone'] as String?,
      site: json['site'] as String?,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'password': instance.password,
      'avatar': instance.avatar,
      'nickname': instance.nickname,
      'introduce': instance.introduce,
      'telephone': instance.telephone,
      'site': instance.site,
      'email': instance.email,
    };
