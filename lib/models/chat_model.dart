import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_model.g.dart';

@JsonSerializable()
class Chat {
  final int id;
  final List<Message?>? messages;
  final List<User?>? users;
  final DateTime created_at;
  Chat({
    required this.id,
    this.messages,
    this.users,
    required this.created_at,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
  Map<String, dynamic> toJson() => _$ChatToJson(this);
}
