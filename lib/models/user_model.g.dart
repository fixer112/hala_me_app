// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
    online: json['online'] == 1 ? true : false,
    id: json['id'] as int,
    phone_number: json['phone_number'] as String,
    email: json['email'] == null ? '' : json['email'] as String,
    username: json['username'] == null ? '' : json['username'] as String,
    name: json['name'] == null ? '' : json['name'] as String,
    imageUrl: json['imageUrl'] == null ? '' : json['imageUrl'] as String,
    chats: (json['chats'] as List)
        ?.map(
            (e) => e == null ? null : Chat.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    created_at: DateTime.parse(json['created_at'] as String),
    updated_at: DateTime.parse(json['updated_at'] as String),
    access_token: json['access_token'] as String,
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'phone_number': instance.phone_number,
      'name': instance.name,
      'email': instance.email,
      'username': instance.username,
      'imageUrl': instance.imageUrl,
      'chats': instance.chats,
      'created_at': instance.created_at?.toIso8601String(),
      'updated_at': instance.updated_at?.toIso8601String(),
      'access_token': instance.access_token,
      'online': instance.online,
    };
