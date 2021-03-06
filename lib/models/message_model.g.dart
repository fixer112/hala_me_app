// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) {
  return Message(
    read: json['read'].toString() == '1' ? true : false,
    delivered: json['delivered'].toString() == '1' ? true : false,
    id: int.parse(json['id'].toString()),
    sender: User.fromJson(json['sender'] as Map<String, dynamic>),
    chat: Chat.fromJson(json['chat'] as Map<String, dynamic>),
    created_at: DateTime.parse(json['created_at'] as String),
    body: json['body'] as String,
    dummy: json['dummy'].toString() == '1' ? true : false,
    uid: json['uid'] as String,
    encrypted: json['encrypted'].toString() == '1' ? true : false,
    alerted: json['alerted'].toString() == '1' ? true : false,
    hidden: json['hidden'].toString() == '1' ? true : false,
    replied: json['replied'] == null
        ? null
        : Message.fromJson(json['replied'] as Map<String, dynamic>),
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
      'encrypted': instance.encrypted,
      'alerted': instance.alerted,
      'hidden': instance.hidden,
      'replied': instance.replied,
    };
