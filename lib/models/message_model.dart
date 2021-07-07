import 'package:hala_me/global.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:json_annotation/json_annotation.dart';

import 'chat_model.dart';

part 'message_model.g.dart';

@JsonSerializable()
class Message {
  final int id;
  final User sender;
  final DateTime created_at;
  final String body;
  final Chat chat;
  bool read;
  bool delivered;
  bool dummy;
  final String uid;
  bool encrypted;
  bool alerted;

  Message({
    required this.read,
    required this.delivered,
    required this.id,
    required this.sender,
    required this.chat,
    required this.created_at,
    required this.body,
    this.dummy = false,
    required this.uid,
    this.encrypted = true,
    this.alerted = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
