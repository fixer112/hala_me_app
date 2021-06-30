// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chat _$ChatFromJson(Map<String, dynamic> json) {
  return Chat(
    id: json['id'] as int,
    messages: (json['messages'] as List)
        ?.map((e) =>
            e == null ? null : Message.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    users: (json['users'] as List)
        ?.map(
            (e) => e == null ? null : User.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    created_at: DateTime.parse(json['created_at'] as String),
    typing: json['typing'] == null ? false : json['typing'] as bool,
  );
}

Map<String, dynamic> _$ChatToJson(Chat instance) => <String, dynamic>{
      'id': instance.id,
      'messages': instance.messages,
      'users': instance.users,
      'created_at': instance.created_at?.toIso8601String(),
      'typing': instance.typing,
    };
