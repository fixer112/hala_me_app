import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_model.g.dart';

@JsonSerializable()
class Chat {
  final int id;
  List<Message?>? messages;
  List<User?>? users;
  final DateTime created_at;
  bool typing;
  Chat({
    required this.id,
    this.messages,
    this.users,
    required this.created_at,
    this.typing = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
  Map<String, dynamic> toJson() => _$ChatToJson(this);
}

class TextController {}
