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
import 'package:hala_me/screens/otp_screen.dart';
import 'package:hala_me/values.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class UserRepository {
  static Future<void> login(String number, {String otp = ''}) async {
    var id = await getId();
    //String number = "";

    /* if (Platform.isIOS) {
      number = "2348034235999";
    } else {
      number = "2348106813749";
    } */
    //print(number);
    var res = await http
        .post(Uri.parse("${AppConfig.BASE_URL}/auth/login"), headers: {
      'Accept': 'application/json',
      //'X-Socket-ID': currentSocketId,
    }, body: {
      'phone_number': number,
      'device_id': id,
      'otp': otp,
    });
    print((res.statusCode));
    print((res.body));
    //print((res));
    //print(jsonDecode(res.body));
    if (![200, 201].contains(res.statusCode)) {
      return Get.snackbar(
          "",
          /* "Invalid number. Start with 234 and 13 digit." */ jsonDecode(
              res.body)['message']);
    }
    if (res.body == 'otp sent') {
      Get.off(OTPScreen(number));
      return null;
    }

    var map = HashMap<String, dynamic>.from(jsonDecode(res.body));
    //print(res.request);
    //print(map);

    User currentUser = User.fromJson(map);
    //print(currentUser.chats?[1]?.messages);

    Get.put(UserProvider()).setCurrentUser(currentUser);
    //print(currentUser.chats?[0]?.messages?[0]?.body);
    Get.off(HomeScreen(
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
      logout(provider);
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
    ////print(res.body);

    if (![200, 201].contains(res.statusCode)) {
      logout(provider);
      return null as User;
    }
    var map = HashMap<String, dynamic>.from(jsonDecode(res.body));

    User currentUser = User.fromJson(map);
    //print(currentUser.chats?.first?.messages?.first?.read);

    currentUser.access_token = access_token;

    if (user != null) {
      var dummys = user.chats?.map((chat) {
        var msg = chat
            ?.messages; //?.where((message) => message?.dummy == true).toList();
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

  static Future updateFcmToken(UserProvider provider, String token) async {
    //return;
    //UserProvider provider = Get.find();
    User? user = await provider.currentUser();

    if (user?.access_token != null) {
      var res = await http
          .put(Uri.parse("${AppConfig.BASE_URL}/update_fcm_token"), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${user?.access_token}',
        //'X-Socket-ID': currentSocketId,
      }, body: {
        'token': token
      });

      print(res.statusCode);
    }
  }

  static Future<Map<String, dynamic>> checkNumbers(
      UserProvider provider, List<String> numbers) async {
    //return;
    //UserProvider provider = Get.find();
    User? user = await provider.currentUser();

    if (user?.access_token != null) {
      //print(jsonEncode(numbers));
      var res = await http
          .post(Uri.parse("${AppConfig.BASE_URL}/check_numbers"), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${user?.access_token}',
        //'X-Socket-ID': currentSocketId,
      }, body: {
        'numbers': jsonEncode(numbers.isNotEmpty ? numbers : [''])
      });
      print("type ${jsonDecode(res.body).runtimeType}");
      print(jsonDecode(res.body));
      Map<String, dynamic> num =
          Map<String, dynamic>.from(jsonDecode(res.body));
      return num;
    }

    return {};
  }
}
