import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pusher_client/flutter_pusher.dart';
import 'package:hala_me/config.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/chat_repository.dart';
import 'package:hala_me/repositories/user_repository.dart';
import 'package:intl/intl.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Future<SharedPreferences> getPref() async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  return _prefs;
}

String formatDate(DateTime date) {
  final f = new DateFormat('dd-MM-yyyy');
  return f.format(date);
}

String formatTime(DateTime date) {
  final f = new DateFormat('hh:mm a').format(date);
  //return f.format(date);

  return chatDate(date) == "Today" ? f : chatDate(date);
}

String chatDate(DateTime date) {
  return date.isAfter(DateTime.now().subtract(Duration(days: 1)))
      ? 'Today'
      : date.isAfter(DateTime.now().subtract(Duration(days: 2)))
          ? 'Yesterday'
          : DateFormat('EE, d MMM, yyyy').format(date);
}

Widget loader() {
  return Center(
    child: CircularProgressIndicator(),
  );
}

checkOnline(User user) {
  if (user.online) {
    return DateTime.now().difference(user.updated_at).inMinutes < 5;
  }
  return false;
}

bool isSameDate(DateTime first, DateTime other) {
  return first.year == other.year &&
      first.month == other.month &&
      first.day == other.day;
}

statusIcon(Message message) {
  if (message.dummy == true) {
    return
        //Icons.lock_clock,
        FaIcon(
      FontAwesomeIcons.clock,
      size: 12,
      color: Colors.blueGrey,
    );
  }
  if (message.read == true) {
    return FaIcon(
      FontAwesomeIcons.checkDouble,
      size: 12,
      color: Colors.blue,
    );
  }

  if (message.delivered == true) {
    return FaIcon(
      FontAwesomeIcons.check,
      size: 12,
      color: Colors.blue,
    );
  }

  return FaIcon(
    FontAwesomeIcons.check,
    size: 12,
    color: Colors.blueGrey,
  );
}

Echo initPusher(User currentUser) {
  //try {
  PusherOptions options = PusherOptions(
    auth: PusherAuth('${AppConfig.RAW_BASE_URL}/broadcasting/auth', headers: {
      //'Accept': 'application/json',
      'Authorization': 'Bearer ${currentUser.access_token}',
    }),
    cluster: PusherConfig.cluster,
    encrypted: PusherConfig.encrypted,
  );

  FlutterPusher? pusher = FlutterPusher(
    PusherConfig.key,
    options,
    enableLogging: true,
    onError: (ConnectionError y) => print(y.message),
  );

  pusher.connect(onConnectionStateChange: (ConnectionStateChange state) async {
    print('stateChange ${state.toJson()}');

    //if (pusher != null) {
    if (state.currentState == 'CONNECTED') {
      final String socketId = pusher.getSocketId();
      print('pusher socket id: $socketId');
    }

    if (state.currentState == 'DISCONNECTED') {
      pusher.connect();
    }
    //}
  });
  // } on PlatformException catch (e) {
  //   //print(e.message);
  // }

  //return null as Echo;

  //pusher?.connect();

  Echo echo = Echo(<String, dynamic>{
    'broadcaster': 'pusher',
    'client': pusher,
    //"forceTLS": false,
    'authEndpoint': '${AppConfig.RAW_BASE_URL}/broadcasting/auth',
    'auth': {
      'headers': {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${currentUser.access_token}',
      }
    }
  });

  //echo.connect();

  return echo;

  //socket.on('connect', (_) => print('connect'));
  //socket.on('disconnect', (_) => print('disconnect'));
}

Future<void> listenChat(
    Echo echo, int id, User currentUser, BuildContext context) async {
  //echo.socket.on();

  echo.private('chat.${id.toString()}').listen('MessageCreated',
      (Map<String, dynamic> message) {
    var map = HashMap.from(message);
    //print('working');
    print(map['message']);
    currentUser.chats
        ?.firstWhere((chat) => chat?.id == map['message']['chat']['id'])
        ?.messages
        ?.add(Message.fromJson(map['message']));
    Provider.of<UserProvider>(context, listen: false)
        .setCurrentUser(currentUser);
    print("body ${currentUser.chats?[0]?.messages?.last?.read}");
  }).listen('ChatLoaded', (Map<String, dynamic> message) {
    var map = HashMap.from(message);
    print(map['chat']);
    Chat c = Chat.fromJson(map['chat']);
    Chat? chat = currentUser.chats
        ?.firstWhere((chat) => chat?.id == c.id, orElse: () => null as Chat);

    var msgs =
        chat?.messages?.where((message) => message?.dummy == true).toList();

    msgs?.forEach((m) {
      var con = c?.messages?.firstWhere((message) => m?.uid == message?.uid,
          orElse: () => null as Message);

      if (con == null) {
        c?.messages?.add(m);
        currentUser?.chats?.removeWhere((chat) => m?.chat.id == chat?.id);
        currentUser?.chats?.add(c);
      }
    });
    /* chat.messages?.forEach((message) {
      currentUser.chats
          ?.firstWhere((c) => c?.id == chat.id, orElse: () => null)
          ?.messages
          ?.removeWhere((m) => m?.uid == message?.uid);

      currentUser.chats
          ?.firstWhere((c) => c?.id == chat.id, orElse: () => null)
          ?.messages!
          .add(message);
    });

    Provider.of<UserProvider>(context, listen: false)
        .setCurrentUser(currentUser); */
  });

  await Future.delayed(Duration(seconds: 2));
}

Future<void> listenOnline(
    Echo echo, int id, User currentUser, BuildContext context) async {
  echo.private('user.${id.toString()}').listen('UserOnline',
      (Map<String, dynamic> message) {
    var map = HashMap.from(message);
    print(map['user']);
    var u = currentUser.chats
        ?.firstWhere((chat) =>
            chat?.users?.firstWhere((user) => user?.id == map['user']['id']) !=
            null)
        ?.users!
        .firstWhere((user) => user?.id == map['user']['id'])
          ?..online = map['user']['online'] == 1 ? true : false
          ..updated_at = DateTime.parse(map['user']['updated_at'] as String);

    Provider.of<UserProvider>(context, listen: false)
        .setCurrentUser(currentUser);
  });

  await Future.delayed(Duration(seconds: 2));
}

Future<User> getUser(BuildContext context) async {
  //return await UserRepository.fetchUser(context);

  //return await UserRepository.login(context);
  User? user =
      await Provider.of<UserProvider>(context, listen: false).currentUser();
  /* if (user?.access_token == null) {
    return user = await UserRepository.login(context);
  } */
  return await UserRepository.fetchUser(context);
}

resendDummy(Chat chat, BuildContext context) async {
  User? currentUser =
      await Provider.of<UserProvider>(context, listen: false).currentUser();
  User user =
      chat.users?.firstWhere((user) => user?.id != currentUser?.id) as User;

  var dummys =
      chat.messages?.where((message) => message?.dummy == true).toList();

  dummys?.forEach((message) async {
    await ChatRepository.saveMessage(user!.id, message!, context);
  });
}
