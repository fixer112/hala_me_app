import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hala_me/config.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/user_repository.dart';
import 'package:hala_me/screens/login_screen.dart';
import 'package:hala_me/values.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ChatRepository {
  static Future typing(Chat chat, UserProvider provider) async {
    User? user = await provider.currentUser();
    User? u = chat.users?.firstWhere((u) => u?.id != user?.id);
    if (user?.access_token != null) {
      var res = await http
          .post(Uri.parse("${AppConfig.BASE_URL}/typing/${u?.id}"), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${user?.access_token}',
        //'X-Socket-ID': currentSocketId,
      });
      if ([401].contains(res.statusCode)) {
        logout(provider);
        return;
      }
      print(res.statusCode);
      //print(res.body);
    }
  }

  static Future<Message?>? saveMessage(
      int id, Message message, UserProvider provider) async {
    //if (user == null) {
    UserProvider provider = Get.find();
    User? user = await provider.currentUser();
    //await Provider.of<UserProvider>(context, listen: false).currentUser();
    //}
    if (user?.access_token != null) {
      var data = {
        'body': message.body,
        'uid': message.uid,
      };
      if (message.replied != null) {
        data['replied_id'] = message.replied!.id.toString();
      }
      var res = await http.post(
          Uri.parse("${AppConfig.BASE_URL}/messages/create/$id"),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${user?.access_token}',
            //'X-Socket-ID': currentSocketId,
          },
          body: data);
      print(res.statusCode);
      ////print(res.body);

      if ([401].contains(res.statusCode)) {
        logout(provider);
      }

      if ([201, 200].contains(res.statusCode)) {
        var map = HashMap<String, dynamic>.from(jsonDecode(res.body));
        Message m = Message.fromJson(map);
        Chat? chat = user?.chats?.firstWhere((chat) => chat?.id == m.chat.id,
            orElse: () => null as Chat);
        if (chat == null) {
          await getMessages(m.chat, provider);
        } else {
          chat.messages?.removeWhere((message) => message?.uid == m.uid);
          chat.messages = List.from(chat.messages as List<Message>)..add(m);

          user?.chats?.removeWhere((chat) => chat?.id == m.chat.id);
          user?.chats = List.from(user.chats as List<Chat>)..add(chat);

          provider.setCurrentUser(user!);
          //context.read<UserProvider>().setCurrentUser(user!, save: true);
        }
        return m;
      }
      /* if (res.statusCode == 422) {
        //print('loaded');
        user?.chats
            ?.firstWhere((chat) => chat?.id == message.chat.id)!
            .messages
            ?.firstWhere((m) => message?.uid == m?.uid)
            ?.delivered = true;
        
      } */

      //print('login ${currentUser.}');

    }
    return null as Message;
  }

  static Future<Chat?>? getMessages(Chat chat, UserProvider provider,
      {int read: 1, notify: 1}) async {
    //UserProvider provider = Get.find();

    User? user = await provider.currentUser();

    User? u = chat.users?.firstWhere((u) => u?.id != user?.id);

    //await context.read<UserProvider>().currentUser();

    if (user?.access_token != null) {
      //print("${AppConfig.BASE_URL}/messages/$id");
      var res = await http.get(
          Uri.parse(
              "${AppConfig.BASE_URL}/messages/${u?.id}?read=${read.toString()}&notify=${notify.toString()}"),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${user?.access_token}',
            //'X-Socket-ID': currentSocketId,
          });
      print(res.statusCode);
      //print(res.body);

      if ([401].contains(res.statusCode)) {
        logout(provider);
      }

      if ([201, 200].contains(res.statusCode)) {
        //print(jsonDecode(res.body));
        var map = HashMap<String, dynamic>.from(jsonDecode(res.body));
        //print(map);
        Chat c = Chat.fromJson(map);
        //print(c.messages?.first?.body);
        Chat? chat = user?.chats?.firstWhere((chat) => chat?.id == c.id,
            orElse: () => null as Chat);
        if (chat != null) {
          var msgs = chat
              .messages; //?.where((message) => message?.dummy == true).toList();
          msgs?.removeWhere((m) => m?.chat.id != chat.id);
          msgs?.forEach((m) {
            var con = c.messages?.firstWhere(
                (message) => m?.uid == message?.uid,
                orElse: () => null as Message);

            if (con == null) {
              c.messages?.add(m);
              //user?.chats?.removeWhere((chat) => m?.chat.id == chat?.id);
            }
          });
          if (read == 1) {
            c.messages?.forEach((m) {
              if (m?.sender.id != user?.id) {
                m?.read = true;
              }
            });
          }
          user?.chats?.removeWhere((chat) => c.id == chat?.id);
        }

        user?.chats = List.from(user.chats as List<Chat>)..add(c);
        var un = c.messages
            ?.where(
              (message) =>
                  message?.read == false && message?.sender.id != user?.id,
            )
            .toList();
        //print(un!.isNotEmpty ? un.first?.body : 0);

        //print(c.messages?[0]?.read);
        provider.setCurrentUser(user!);
        //context.read<UserProvider>().setCurrentUser(user!, save: true);

        return c;
      }

      //print('login ${currentUser.}');

    }
    return null as Chat;
  }

  static alertMessage(Message message, UserProvider provider,
      {int alerted: 1}) async {
    User? user = await provider.currentUser();

    if (user?.access_token != null) {
      var res = await http.post(
          Uri.parse("${AppConfig.BASE_URL}/message/alert/${message.id}"),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${user?.access_token}',
          },
          body: {
            'alerted': alerted.toString(),
          });
      print(res.statusCode);
    }
  }

  static deleteMessages(
      Chat chat, List<String> ids, UserProvider provider) async {
    User? user = await provider.currentUser();

    if (user?.access_token != null) {
      var res = await http
          .delete(Uri.parse("${AppConfig.BASE_URL}/messages/delete"), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${user?.access_token}',
      }, body: {
        'ids': jsonEncode(ids.isNotEmpty ? ids : ['']),
      });
      print(res.statusCode);
      //print(res.body);
      if (res.statusCode == 200) {
        user?.chats
            ?.firstWhere((c) => c?.id == chat.id, orElse: null)
            ?.messages
            ?.removeWhere((m) => ids.contains(m?.uid));

        provider.setCurrentUser(user!);

        getMessages(chat, provider);
      }
    }
  }

  static deleteChat(Chat chat, UserProvider provider) async {
    User? user = await provider.currentUser();
    var u = chat.users?.firstWhere((e) => e?.id != user?.id);

    if (user?.access_token != null) {
      var res = await http.delete(
          Uri.parse("${AppConfig.BASE_URL}/chat/delete/${u?.id.toString()}"),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${user?.access_token}',
          },
          body: {});
      print(res.statusCode);
      //print(res.body);
      if (res.statusCode == 200) {
        user?.chats
            ?.firstWhere((c) => c?.id == chat.id, orElse: null)
            ?.messages = [];
        provider.setCurrentUser(user!);
        UserRepository.fetchUser(provider);
      }
    }
  }
}
