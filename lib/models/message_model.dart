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

  Message({
    this.read = false,
    this.delivered = false,
    required this.id,
    required this.sender,
    required this.chat,
    required this.created_at,
    required this.body,
    this.dummy = false,
    required this.uid,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
