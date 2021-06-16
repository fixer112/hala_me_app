// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) {
  return Message(
    read: json['read'] == 1 ? true : false,
    delivered: json['delivered'] == 1 ? true : false,
    id: json['id'] as int,
    sender: User.fromJson(json['sender'] as Map<String, dynamic>),
    chat: Chat.fromJson(json['chat'] as Map<String, dynamic>),
    created_at: DateTime.parse(json['created_at'] as String),
    body: json['body'] as String,
    dummy: json['dummy'] == 1 ? true : false,
    uid: json['uid'] as String,
  );
}

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'sender': instance.sender,
      'created_at': instance.created_at?.toIso8601String(),
      'body': instance.body,
      'chat': instance.chat,
      'read': instance.read,
      'delivered': instance.delivered,
      'dummy': instance.dummy,
      'uid': instance.uid,
    };
