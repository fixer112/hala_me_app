import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pusher_client/flutter_pusher.dart';
import 'package:get/get.dart';
import 'package:hala_me/config.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/screens/chat_screen.dart';
import 'package:hala_me/screens/home_screen.dart';
import 'package:hala_me/screens/login_screen.dart';
import 'package:hala_me/values.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class UserRepository {
  static Future<void> login(String number) async {
    //String number = "";

    /* if (Platform.isIOS) {
      number = "2348034235999";
    } else {
      number = "2348106813749";
    } */
    print(number);
    var res = await http
        .post(Uri.parse("${AppConfig.BASE_URL}/auth/login"), headers: {
      'Accept': 'application/json',
      //'X-Socket-ID': currentSocketId,
    }, body: {
      'phone_number': number
    });
    //print(res.body);
    if (res.statusCode != 200) {
      return Get.snackbar("", "invalid number");
    }
    var map = HashMap<String, dynamic>.from(jsonDecode(res.body));
    //print(res.request);
    //print(map);

    User currentUser = User.fromJson(map);
    //print(currentUser.chats?[1]?.messages);

    Get.put(UserProvider()).setCurrentUser(currentUser);
    //print(currentUser.chats?[0]?.messages?[0]?.body);
    Get.to(HomeScreen(
      first: true,
    ));
    //return currentUser;
  }

  static Future<User> fetchUser(UserProvider provider) async {
    //UserProvider provider = Get.find();
    User? user = await provider.currentUser();
    //await Provider.of<UserProvider>(context, listen: false).currentUser();

    //print(user?.access_token);
    //return null as User;
    if (user?.access_token == null) {
      Get.off(LoginScreen());
    }
    //print(number);

    String? access_token = user?.access_token;

    var res = await http.get(
      Uri.parse("${AppConfig.BASE_URL}/user"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${user?.access_token}',
        //'X-Socket-ID': currentSocketId,
      },
    );

    //print(access_token);
    print(res.statusCode);
    //print(res.body);

    if (![200, 201].contains(res.statusCode)) {
      Get.off(LoginScreen());
      return null as User;
    }
    var map = HashMap<String, dynamic>.from(jsonDecode(res.body));

    User currentUser = User.fromJson(map);
    //print(currentUser.chats?.first?.messages?.first?.read);

    currentUser.access_token = access_token;

    if (user != null) {
      var dummys = user.chats?.map((chat) {
        var msg =
            chat?.messages?.where((message) => message?.dummy == true).toList();
        // .map((m) => m?.uid)
        // .toList();
        return msg;
      }).toList();

      List<Message> msgs = [];

      dummys?.forEach((messages) {
        msgs.addAll(messages as List<Message>);
      });

      msgs.forEach((m) {
        var c = currentUser.chats?.firstWhere((chat) => m?.chat.id == chat?.id,
            orElse: () => null as Chat);

        var con = c?.messages?.firstWhere((message) => m?.uid == message?.uid,
            orElse: () => null as Message);

        if (con == null) {
          c?.messages?.add(m);
          currentUser.chats?.removeWhere((chat) => m.chat.id == chat?.id);
          currentUser.chats = List.from(currentUser.chats as List<Chat>)
            ..add(c);
        }
      });
    }

    //print('login ${currentUser.}');
    provider.setCurrentUser(currentUser);
    //context.read<UserProvider>().setCurrentUser(currentUser);

    return currentUser;
  }

  static Future setOnlineStatus(UserProvider provider, {int status = 1}) async {
    //return;
    //UserProvider provider = Get.find();
    User? user = await provider.currentUser();

    if (user?.access_token != null) {
      var res = await http
          .put(Uri.parse("${AppConfig.BASE_URL}/set_online"), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${user?.access_token}',
        //'X-Socket-ID': currentSocketId,
      }, body: {
        'status': status.toString()
      });

      //var map = HashMap<String, dynamic>.from(jsonDecode(res.body));

      //User currentUser = User.fromJson(map);
      //print('login ${currentUser.}');

      // provider.setCurrentUser(currentUser);

      /* Provider.of<UserProvider>(context, listen: false)
          .setCurrentUser(currentUser); */
      //return currentUser;
    }
  }
}
