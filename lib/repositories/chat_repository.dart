import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hala_me/config.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ChatRepository {
  static Future saveMessage(
      int id, Message message, BuildContext context) async {
    User? user =
        await Provider.of<UserProvider>(context, listen: false).currentUser();

    if (user?.access_token != null) {
      var res = await http.post(
          Uri.parse("${AppConfig.BASE_URL}/messages/create/$id"),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${user?.access_token}',
          },
          body: {
            'body': message.body,
            'uid': message.uid,
          });
      //print(res.statusCode);
      if ([201, 200].contains(res.statusCode)) {
        var map = HashMap<String, dynamic>.from(jsonDecode(res.body));
        Message m = Message.fromJson(map);
        Chat? chat = user?.chats?.firstWhere((chat) => chat?.id == m.chat.id,
            orElse: () => null as Chat);
        chat?.messages?.removeWhere((message) => message?.uid == m.uid);
        chat?.messages?.add(m);

        user?.chats?.removeWhere((chat) => chat?.id == m.chat.id);
        user?.chats?.add(chat);

        //Provider.of<UserProvider>(context, listen: false).setCurrentUser(user!);
      }

      //print('login ${currentUser.}');

    }
  }

  static Future getMessages(int id, BuildContext context) async {
    User? user =
        await Provider.of<UserProvider>(context, listen: false).currentUser();

    if (user?.access_token != null) {
      var res = await http
          .get(Uri.parse("${AppConfig.BASE_URL}/messages/$id"), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${user?.access_token}',
      });
      //print(res.statusCode);
      if ([201, 200].contains(res.statusCode)) {
        var map = HashMap<String, dynamic>.from(jsonDecode(res.body));
        Chat c = Chat.fromJson(map);
        Chat? chat = user?.chats?.firstWhere((chat) => chat?.id == c.id,
            orElse: () => null as Chat);

        var msgs =
            chat?.messages?.where((message) => message?.dummy == true).toList();
        // .map((m) => m?.uid)
        // .toList();

        msgs?.forEach((m) {
          var con = c?.messages?.firstWhere((message) => m?.uid == message?.uid,
              orElse: () => null as Message);

          if (con == null) {
            c?.messages?.add(m);
            user?.chats?.removeWhere((chat) => m?.chat.id == chat?.id);
            user?.chats?.add(c);
          }
        });

        //Provider.of<UserProvider>(context, listen: false).setCurrentUser(user!);
      }

      //print('login ${currentUser.}');

    }
  }
}
