import 'dart:convert';

import 'package:hala_me/models/chat_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String phone_number;
  final String name;
  final String email;
  final String username;
  final String? imageUrl;
  List<Chat?>? chats;
  final DateTime created_at;
  DateTime updated_at;
  String? access_token;
  bool online;

  User({
    required this.online,
    required this.id,
    required this.phone_number,
    this.email = '',
    this.username = '',
    this.name = '',
    this.imageUrl = '',
    this.chats,
    required this.created_at,
    required this.updated_at,
    this.access_token,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
