import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:connectivity/connectivity.dart';
import 'package:encrypt/encrypt.dart' as E;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pusher_client/flutter_pusher.dart';
import 'package:get/get.dart';
import 'package:hala_me/config.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/chat_repository.dart';
import 'package:hala_me/repositories/user_repository.dart';
import 'package:hala_me/screens/login_screen.dart';
import 'package:hala_me/values.dart';
import 'package:intl/intl.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:laravel_echo/src/channel/private-channel.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:device_info/device_info.dart';

Future<SharedPreferences> getPref() async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  return _prefs;
}

String limitString(String message, int len) {
  return message.length > len ? "${message.substring(0, len)}..." : message;
}

String formatDate(DateTime date) {
  final f = new DateFormat('dd-MM-yyyy');
  return f.format(date);
}

String formatTime(DateTime date) {
  final f = new DateFormat('hh:mm a').format(date);
  //return f.format(date);

  return f;

  //return chatDate(date) == "Today" ? f : chatDate(date);
}

String lastChatPeriod(DateTime date) {
  return chatDate(date) == "Today" ? formatTime(date) : chatDate(date);
}

String chatDate(DateTime date) {
  return date.isAfter(DateTime.now().subtract(Duration(days: 1)))
      ? 'Today'
      : date.isAfter(DateTime.now().subtract(Duration(days: 2)))
          ? 'Yesterday'
          : DateFormat('EE, d MMM, yyyy').format(date);
}

Widget loader({Color? color, double scale = 1, bool center = true}) {
  color = color ?? primaryColor;
  Widget child = center == true
      ? Center(
          child: CircularProgressIndicator(
            color: color,
            //value: 1,
          ),
        )
      : CircularProgressIndicator(
          color: color,
          //value: 1,
        );
  return Transform.scale(
    scale: scale,
    //color: Colors.white,
    child: child,
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
      currentSocketId = socketId;
      print('pusher socket id: $socketId');
    }

    if (state.currentState == 'DISCONNECTED') {
      ConnectivityResult result = await Connectivity().checkConnectivity();
      if (result != ConnectivityResult.none) {
        pusher.connect();
      }
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
  //print("socket ${echo.sockedId()}");
  //echo.connect();

  return echo;

  //socket.on('connect', (_) => print('connect'));
  //socket.on('disconnect', (_) => print('disconnect'));
}

Future listenChat(
    Echo echo, int id, UserProvider provider, BuildContext context) async {
  //echo.socket.on();
  //UserProvider provider = Get.find();
  AudioCache player = AudioCache(prefix: 'assets/sounds/');

  User? currentUser = await provider.currentUser();
  //await context.read<UserProvider>().currentUser();
  PrivateChannel channel = echo.private('chat.${id.toString()}');

  // echos[id] = channel;
  // print("channel all : ${echos}");
  /* .whisper('typing', {
    'user_id': currentUser?.id,
    'typing': true,
    // });
  }) */

  channel.listen('MessageCreated', (Map<String, dynamic> message) async {
    var map = HashMap.from(message);
    // Map<String, String> mC =
    //     map.map((key, value) => MapEntry(key.toString(), value.toString()));
    //print('working');
    //print(map['message']);
    var m = Message.fromJson(map['message']);
    var chat = currentUser?.chats
        ?.firstWhere((chat) => chat?.id == map['message']['chat']['id']);
    var messages = currentUser?.chats
        ?.firstWhere((chat) => chat?.id == map['message']['chat']['id'])
        ?.messages;
    if (messages!.where((msg) => msg?.uid == m.uid).isEmpty) {
      currentUser?.chats
          ?.firstWhere((chat) => chat?.id == map['message']['chat']['id'])
          ?.messages
          ?.add(m);
    }
    int read = 0;
    print('notification');
    //print(Get.currentRoute);
    print(currentChatPage);
    if (currentChatPage == id) {
      read = 1;
      if (m.sender.id != currentUser?.id) {
        player.play('message_recieved.mp3', volume: 0.5);
      }
    } else {
      if (m.sender.id != currentUser?.id && m.alerted == false) {
        AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
          if (!isAllowed) {
            // Insert here your friendly dialog box before call the request method
            // This is very important to not harm the user experience
            AwesomeNotifications().requestPermissionToSendNotifications();
          }
        });
        var pref = await getPref();
        //print(chat?.id);
        AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: m.chat.id,
              channelKey: 'message_recieved',
              title: limitString(getUserName(pref, m.sender.phone_number), 20),
              body: limitString(m.body, 30),
              payload: {
                'chat_id': chat?.id.toString() as String,
                'message_id': m.id.toString(),
                'user_id': m.sender.id.toString(),
              },
            ),
            actionButtons: [
              NotificationActionButton(
                key: 'REPLY',
                label: 'Reply',
                autoCancel: true,
                buttonType: ActionButtonType.InputField,
              ),
              NotificationActionButton(
                  key: 'READ', label: 'Mark as read', autoCancel: true),
            ]);
      }
    }
    await ChatRepository.alertMessage(m, provider);
    ChatRepository.getMessages(chat!, provider, read: read, notify: 0);

    provider.setCurrentUser(currentUser!, save: false);
    provider.update();

    /* Provider.of<UserProvider>(context, listen: false)
        .setCurrentUser(currentUser!); */
    //print("body ${currentUser.chats?[0]?.messages?.last?.read}");
  }).listen('ChatLoaded', (Map<String, dynamic> message) {
    var map = HashMap.from(message);
    print(map['chat']);
    Chat c = Chat.fromJson(map['chat']);
    Chat? chat = currentUser?.chats
        ?.firstWhere((chat) => chat?.id == c.id, orElse: () => null as Chat);

    var msgs =
        chat?.messages?.where((message) => message?.dummy == true).toList();

    msgs?.forEach((m) {
      var con = c?.messages?.firstWhere((message) => m?.uid == message?.uid,
          orElse: () => null as Message);

      if (con == null) {
        c.messages?.add(m);
      }
    });
    currentUser?.chats?.removeWhere((chat) => c.id == chat?.id);
    // chat?.messages?.removeWhere((element) =>
    //     c.messages?.map((e) => e?.uid).toList().contains(element?.uid) as bool);

    // chat?.messages = [...chat.messages as List<Message>, ...c.messages!];
    // currentUser?.chats = List.from(currentUser.chats as List<Chat>)..add(chat);
    currentUser?.chats = List.from(currentUser.chats as List<Chat>)..add(c);

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

        */
    provider.setCurrentUser(currentUser!, save: false);
    provider.update();
    ChatRepository.getMessages(chat!, provider, read: 0, notify: 0);
    /* Provider.of<UserProvider>(context, listen: false)
        .setCurrentUser(currentUser!); */
  }).listen('Typing', (Map<String, dynamic> data) {
    var map = HashMap.from(data);
    if (int.parse(map['user_id'].toString()) != currentUser?.id) {
      print(map);
      var chat = currentUser?.chats
          ?.firstWhere((chat) => chat?.id == id, orElse: () => null as Chat);

      currentUser?.chats?.removeWhere((chat) => id == chat?.id);
      chat?.typing = true;
      currentUser?.chats = List.from(currentUser.chats as List<Chat>)
        ..add(chat);

      provider.setCurrentUser(currentUser!, save: false);
      Timer(const Duration(milliseconds: 900), () {
        currentUser.chats?.removeWhere((chat) => id == chat?.id);
        chat?.typing = false;
        currentUser.chats = List.from(currentUser.chats as List<Chat>)
          ..add(chat);

        provider.setCurrentUser(currentUser, save: false);
      });
    }
  });
  //c.subscribed(() {
  //print("socket connect ${echo.sockedId()}");
  //});
  //channel.subscribed(() {});

  //print({id: channel});

  //UserRepository.fetchUser(context);
  await Future.delayed(Duration(seconds: 2));
}

Future<void> listenOnline(
    Echo echo, int id, UserProvider provider, BuildContext context) async {
  //UserProvider provider = Get.find();
  User? currentUser = await provider.currentUser();
  //await context.read<UserProvider>().currentUser();
  echo.private('user.${id.toString()}').listen('UserOnline',
      (Map<String, dynamic> message) {
    var map = HashMap.from(message);
    print(map['user']);
    var u = currentUser?.chats
        ?.firstWhere((chat) =>
            chat?.users?.firstWhere((user) => user?.id == map['user']['id']) !=
            null)
        ?.users!
        .firstWhere((user) =>
            user?.id != currentUser.id && user?.id == map['user']['id'])
          ?..online = map['user']['online'] == 1 ? true : false
          ..updated_at = DateTime.parse(map['user']['updated_at'] as String);

    provider.setCurrentUser(currentUser!, save: false);
    provider.update();
    /* Provider.of<UserProvider>(context, listen: false)
        .setCurrentUser(currentUser!); */
  });

  //UserRepository.fetchUser(context);

  await Future.delayed(Duration(seconds: 2));
}

Future<User> getUser(UserProvider provider) async {
  return await UserRepository.fetchUser(provider);
}

Future<Chat> resendDummy(Chat chat, UserProvider provider) async {
  //var provider = Get.put(UserProvider());
  User? currentUser = await provider.currentUser();
  //await Provider.of<UserProvider>(context, listen: false).currentUser();
  User user =
      chat.users?.firstWhere((user) => user?.id != currentUser?.id) as User;

  var dummys =
      chat.messages?.where((message) => message?.dummy == true).toList();

  dummys?.forEach((message) async {
    var m = await ChatRepository.saveMessage(user!.id, message!, provider);
    if (m != null) {
      chat.messages?.removeWhere((value) => value?.uid == m.uid);
      chat.messages?.add(m);
    }
  });
  return chat;
}

comparePhoneNumber(List<String> numbers, List<String> contacts) {
  List<String> n = [];
  numbers.forEach((number) {
    if (contacts.contains(number)) {
      n.add(number);
    }
    if (number.startsWith('+234')) {
      number = number.replaceFirst('+234', '0');
      if (contacts.contains(number)) {
        n.add(number);
      }
    }
    if (number.startsWith('234')) {
      number = number.replaceFirst('234', '0');
      if (contacts.contains(number)) {
        n.add(number);
      }
    }
    number = "+234$number";
    if (contacts.contains(number)) {
      n.add(number);
    }
  });
  return n;
}

String getUserName(SharedPreferences pref, String number) {
  Map<String, String> c = getUserContact(pref, number);
  return c.isEmpty ? number : c.values.toList().first;
}

Map<String, String> getUserContact(SharedPreferences pref, String number) {
  Map<String, String> numberName = Map<String, String>.from(
      jsonDecode(pref.getString('numberName') ?? '{}'));
  List<String> nums = [];
  if (number.startsWith('234') || number.startsWith('+234')) {
    if (number.startsWith('234')) {
      var n = number.replaceFirst('234', '0');
      nums = [number, '+$number', n];
    }

    if (number.startsWith('+234')) {
      var n = number.replaceFirst('+234', '0');
      var n1 = number.replaceFirst('234', '0');
      nums = [number, n1, n];
    }
  } else {
    nums = [number, "234$number", "+234$number"];
  }

  return numberName..removeWhere((k, v) => !nums.contains(k));
  // return List<String>.from(
  //     numberName.entries.where((nm) => nums.contains(nm.key)));

  // Contact? c = provider.contacts?.firstWhere(
  //     (contact) => contact.phones
  //         ?.where((phone) => nums.contains(phone.value))
  //         .isNotEmpty as bool,
  //     orElse: () => null as Contact);
  // c?.phones?.toList().removeWhere((phone) => !nums.contains(phone.value));
  // return c;
}

Future syncContacts(UserProvider provider) async {
  var pref = await getPref();
  if (await Permission.contacts.request().isGranted) {
    Iterable<Contact> con = await ContactsService.getContacts();
    print('fetching contact');
    //provider.contacts = contacts;
    List<Contact> contacts = con.toList();

    List<String> numbers = [];

    contacts.forEach((c) {
      //c.phones?.forEach((p) {
      numbers
          .addAll(c.phones!.map((e) => formatNumber(e.value ?? '')).toList());
      //});
    });

    Map<String, dynamic> data =
        await UserRepository.checkNumbers(provider, numbers);

    print('data');
    pref.remove('data');
    pref.setString('data', jsonEncode(data));

    List<String> nums = data.keys
        .toList(); //await UserRepository.checkNumbers(provider, numbers);
    print(nums);
    List<String> validNum = comparePhoneNumber(nums, numbers);

    //print("numbers $validNum");

    //print(validNum);

    List<Contact> validContacts = contacts
        .where((contact) => contact.phones!
            .where(
                (phone) => validNum.contains(formatNumber(phone.value ?? '')))
            .isNotEmpty)
        .toList();

    Map<String, String>? numberName = {};
    validContacts.forEach((contact) {
      contact.phones?.forEach((phone) {
        numberName.addAll(
            {formatNumber(phone.value ?? ''): "${contact.displayName ?? ''}"});
      });
    });

    provider.contacts = validContacts;
    //if (numberName != {}) {
    pref.remove('numberName');
    pref.setString('numberName', jsonEncode(numberName));
    //}
    //print(numberName);
    // var num = await provider.getNumberName();
    // print("start $num");
    //});
  }

// You can request multiple permissions at once.
// Map<Permission, PermissionStatus> statuses = await [
//   Permission.location,
//   Permission.storage,
// ].request();
// print(statuses[Permission.location]);
}

String formatNumber(String number) {
  number = number.replaceAll(' ', '');
  if (number.startsWith('+234')) {
    return number.replaceFirst('+', '');
  } else if (number.startsWith('234')) {
    return "$number";
  } else {
    return "234${number.substring(1)}";
  }
}

Future<List<String?>> getDeviceDetails() async {
  String? deviceName;
  String? deviceVersion;
  String? identifier;

  final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      var build = await deviceInfoPlugin.androidInfo;
      deviceName = build.model;
      deviceVersion = build.version.toString();
      identifier = build.androidId; //UUID for Android
    } else if (Platform.isIOS) {
      var data = await deviceInfoPlugin.iosInfo;
      deviceName = data.name;
      deviceVersion = data.systemVersion;
      identifier = data.identifierForVendor; //UUID for iOS
    }
  } on PlatformException {
    print('Failed to get platform version');
  }

//if (!mounted) return;
  return [deviceName, deviceVersion, identifier];
}

Future<String> getId() async {
  var deviceInfo = DeviceInfoPlugin();
  if (Platform.isIOS) {
    // import 'dart:io'
    var iosDeviceInfo = await deviceInfo.iosInfo;
    return iosDeviceInfo.identifierForVendor; // unique ID on iOS
  } else {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    return androidDeviceInfo.androidId; // unique ID on Android
  }
}

bool checkBool(dynamic value) {
  if (value.runtimeType == bool) {
    return value;
  } else {
    return value.toString() == '1' ? true : false;
  }
}

String encrypt(plainText, id) {
  final key = E.Key.fromUtf8("$id$id");
  final iv = E.IV.fromLength(16);

  final encrypter = E.Encrypter(E.AES(key));

  final encrypted = encrypter.encrypt(plainText, iv: iv);

  return encrypted.base64;
}

String decrypt(String base64, id) {
  final key = E.Key.fromUtf8("$id$id");
  final iv = E.IV.fromLength(16);

  final encrypter = E.Encrypter(E.AES(key));

  final encrypted = E.Encrypted.from64(base64);
  return encrypter.decrypt(encrypted, iv: iv);
}

logout(UserProvider provider) {
  provider.setCurrentUser(null as User);
  Get.to(LoginScreen());
}
