import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hala_me/config.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/chat_repository.dart';
import 'package:hala_me/screens/home_screen.dart';
import 'package:hala_me/values.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:laravel_echo/src/channel/private-channel.dart';

// ignore: must_be_immutable
class ChatScreen extends StatefulWidget {
  Chat chat;

  ChatScreen({required this.chat});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //List<Message> messages = [];
  User? currentUser;
  User? user;
  int? prevUserId;
  Timer? timer;
  Timer? t1;
  Timer? t2;
  static AudioCache player = AudioCache(prefix: 'assets/sounds/');

  UserProvider provider = Get.find();

  DateTime? prevDate;

  TextEditingController? controller = TextEditingController();

  bool loading = false;

  PrivateChannel? channel;
  Map<String, String>? nums = {};

  SharedPreferences? pref;

  Widget _chatBubble(Message message, bool isMe, bool isSameUser) {
    //print(message.delivered);
    return isMe
        ? Column(
            children: <Widget>[
              Container(
                alignment: Alignment.topRight,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.80,
                  ),
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.body,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          statusIcon(message),
                          Text(
                            formatTime(message.created_at),
                            style: TextStyle(
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              /* !isSameUser
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      formatDate(message.created_at),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundImage: AssetImage(message.sender.imageUrl ??
                            'assets/images/black-widow.jpg'),
                      ),
                    ),
                  ],
                )
              : Container(
                  child: null,
                ), */
            ],
          )
        : Column(
            children: <Widget>[
              Container(
                alignment: Alignment.topLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.80,
                  ),
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    //mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.body,
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        //crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatTime(message.created_at),
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              /* !isSameUser
              ? Row(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundImage:
                            AssetImage('assets/images/black-widow.jpg'),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      formatDate(message.created_at),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                )
              : Container(
                  child: null,
                ),
         */
            ],
          );
  }

  _sendMessageArea() {
    var chat = widget.chat;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      height: 70,
      color: Colors.white,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            iconSize: 25,
            color: Theme.of(context).primaryColor,
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration.collapsed(
                hintText: 'Send a message..',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            iconSize: 25,
            color: Theme.of(context).primaryColor,
            onPressed: loading == true || chat.id == 0
                ? null
                : () async {
                    //print(controller!.text);
                    if (controller!.text.isNotEmpty) {
                      var m = Message(
                        read: false,
                        delivered: false,
                        id: 0,
                        body: controller!.text,
                        chat: chat,
                        created_at: DateTime.now(),
                        dummy: true,
                        sender: currentUser!,
                        uid: Uuid().v4(),
                      );
                      var c = currentUser?.chats?.firstWhere(
                          (c) => c?.id == chat.id,
                          orElse: () => null as Chat);

                      currentUser?.chats?.removeWhere((c) => c?.id == chat.id);
                      c?.messages = List.from(c.messages as List<Message>)
                        ..add(m);
                      currentUser?.chats =
                          List.from(currentUser?.chats as List<Chat>)..add(c);
                      provider.setCurrentUser(currentUser!, save: false);

                      controller!.text = "";

                      loading = true;
                      setState(() {});
                      //if (user != null) {
                      Message? message = await ChatRepository.saveMessage(
                          user!.id, m, provider);

                      loading = false;
                      setState(() {});

                      if (message != null) {
                        chat.messages
                            ?.removeWhere((value) => value?.uid == message.uid);
                        chat.messages?.add(message);
                        player.play('message_sent.wav', volume: 0.5);
                        //p.release();
                      }
                      // }

                      //User u = currentUser!;

                      /* currentUser?.chats
                    ?.firstWhere((c) => c?.id == chat.id)!
                    .messages.sort(a,b) */

                      //print(m.uid);

                      // return print(jsonEncode(User.fromJson(
                      //     jsonDecode(pref.getString('currentUser') as String))));
                      //return print(jsonEncode(currentUser));

                    }
                  },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    currentChatPage = widget.chat.id;
    //print(currentChatPage);

    //print(globalEcho?.connector);
    whisperType();
    getPref().then((value) => pref = value);
    getUser().then((value) {
      /* globalEcho
          ?.private('chat.${widget.chat.id.toString()}')
          .whisper('typing', {
        'user_id': user!.id,
        'typing': true,
      }); */
      //whisperType();
      // PrivateChannel channel = initPusher(value)
      /* globalEcho!
          .private('chat.${widget.chat.id.toString()}')
          .whisper('typing', () {}); */
      ChatRepository.getMessages(widget.chat, provider)?.then((chat) {
        if (chat != null) {
          widget.chat = chat;
          //setState(() {});
        }
      });
    });

    //print(channel.options);

    //listenType(channel);
    if (widget.chat.id != 0) {
      resend();
    }

    super.initState();
    timer = Timer.periodic(new Duration(seconds: 10), (timer) => resend());
  }

  @override
  void dispose() {
    timer?.cancel();
    t1?.cancel();
    super.dispose();
  }

  whisperType() async {
    //print('whisper');
    controller!.addListener(() async {
      //print(controller?.text);

      t1 = Timer(const Duration(milliseconds: 300), () async {
        /* channel?.whisper('typing', {
        'user_id': user!.id,
        'typing': true,
        }); */
        await ChatRepository.typing(widget.chat, provider);
        //var c = initPusher(us!)
        //var channel = globalEcho!.private('chat.${widget.chat.id.toString()}');
        // var channel = echos[currentChatPage];
        // //print('channel: ${channel.}');
        // //channel.subscribed(() {
        // print('working');
        // channel?.whisper('typing', {
        //   'user_id': user!.id,
        //   'typing': true,
        //   // });
        // });
      });
    });
  }

  resend() {
    //if (!mounted) return;
    //print("test");
    resendDummy(widget.chat, provider).then((chat) => widget.chat == chat);
  }

  Future<User> getUser() async {
    nums = await provider.numberName();
    /* currentUser =
        await Provider.of<UserProvider>(context, listen: false).currentUser(); */
    var us = await provider.currentUser();
    //await context.read<UserProvider>().currentUser();
    print(widget.chat.users);
    //print("${us?.id}");
    user = widget.chat.users?.firstWhere((u) => u?.id != us?.id) as User;
    prevUserId = user?.id;

    setState(() {});

    return user!;

    //await listenOnline(user!.id, currentUser!, context);
    //setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return user == null || pref == null
        ? loader()
        : WillPopScope(
            onWillPop: () async {
              currentChatPage = 0;
              print(currentChatPage);
              Get.to(HomeScreen());
              return true;
            },
            child: Scaffold(
              backgroundColor: Color(0xFFF6F6F6),
              appBar: AppBar(
                brightness: Brightness.dark,
                centerTitle: false,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedNetworkImage(
                      imageUrl: "${AppConfig.RAW_BASE_URL}${user!.imageUrl}",
                      imageBuilder: (context, imageProvider) => SizedBox(
                        height: 35,
                        width: 35,
                        child: CircleAvatar(
                            radius: 35,
                            backgroundImage:
                                imageProvider /* AssetImage(
                                                        chatUser!.imageUrl
                                                            as String)*/
                            ),
                      ),
                      placeholder: (context, url) => loader(scale: 0.5),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        children: [
                          TextSpan(
                              text:
                                  getUserName(pref!, user?.phone_number ?? ''),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              )),
                          TextSpan(text: '\n'),
                          widget.chat.typing == true
                              ? TextSpan(
                                  text: 'Typing...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                              : checkOnline(user!) ?? false
                                  ? TextSpan(
                                      text: 'Online',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    )
                                  : TextSpan(
                                      text: 'Offline',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    )
                        ],
                      ),
                    ),
                  ],
                ),
                /* leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios),
                    color: Colors.white,
                    onPressed: () {
                      currentChatPage = 0;
                      print(currentChatPage);
                      Navigator.pop(context);
                    }), */
              ),
              body:
                  /* GetBuilder<UserProvider>(
                  //init: UserProvider(),
                  builder: (_) {
                    return */
                  GetBuilder<UserProvider>(
                      //init: UserProvider(),
                      builder: (_) {
                return FutureBuilder<User?>(
                    future: provider.currentUser(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return loader();
                      }

                      currentUser = snapshot.data;
                      widget.chat = currentUser!.chats!.isEmpty
                          ? widget.chat
                          : widget.chat.id == 0
                              ? widget.chat
                              : currentUser?.chats?.firstWhere(
                                  (chat) => chat?.id == widget.chat.id) as Chat;
                      // });

                      user = widget.chat.users
                          ?.firstWhere((u) => u?.id != currentUser?.id) as User;
                      prevUserId = user?.id;

                      List<Message> messages =
                          widget.chat.messages as List<Message>;

                      messages
                          .sort((a, b) => b.created_at.compareTo(a.created_at));

                      prevDate = messages.isNotEmpty
                          ? messages.first.created_at
                          : DateTime.now();

                      return Column(
                        children: <Widget>[
                          Expanded(
                            child: ListView.builder(
                              reverse: true,
                              padding: EdgeInsets.all(20),
                              itemCount: messages.length,
                              itemBuilder: (BuildContext context, int index) {
                                //print(formatDate(prevDate));
                                messages.sort((a, b) =>
                                    b.created_at.compareTo(a.created_at));
                                Message? lastMessage = messages.lastWhere(
                                    (message) => isSameDate(
                                        message.created_at, prevDate!));

                                //print(lastMessage.uid);
                                // Message? lastMessage = messages.lastWhere(
                                //     (message) =>
                                //         isSameDate(message.created_at, prevDate),
                                //     orElse: () => null as Message);
                                final Message message = messages[index];
                                // print(
                                //     "last:${lastMessage?.uid} message:${message?.uid}");
                                final bool isMe =
                                    message.sender.id == currentUser?.id;
                                final bool isSameUser =
                                    prevUserId == message.sender.id;
                                //print("$prevUserId : ${message.sender.id}");
                                prevUserId = message.sender.id;
                                //setState(() {});
                                // bool sameDate =
                                //     isSameDate(prevDate, message.created_at);
                                prevDate = message.created_at;

                                //setState(() {});

                                return Column(
                                  children: [
                                    lastMessage.uid == message.uid
                                        // ||
                                        //         !isSameDate(lastMessage.created_at,
                                        //             message.created_at)
                                        //lastMessage.created_at != message.created_at
                                        //||firstMessage?.uid == message.uid
                                        ? Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                                chatDate(message.created_at),
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          )
                                        : Container(),
                                    _chatBubble(message, isMe, isSameUser),
                                  ],
                                );
                              },
                            ),
                          ),
                          _sendMessageArea(),
                        ],
                      );
                      //}),
                    });
              }),
            ),
          );

    // },),);
  }
}
