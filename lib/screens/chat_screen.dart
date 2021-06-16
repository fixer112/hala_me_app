import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/chat_repository.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  ChatScreen({required this.chat});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //List<Message> messages = [];
  User? currentUser;
  User? user;
  int? prevUserId;
  int i = 0;

  DateTime? prevDate;

  TextEditingController? controller = TextEditingController();

  bool loading = false;

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
            onPressed: loading
                ? null
                : () async {
                    //print(controller!.text);
                    if (controller!.text.isNotEmpty) {
                      //return print(json.encode(currentUser));
                      // var pref = await getPref();
                      // var u = (HashMap<String, dynamic>.from(
                      //     jsonDecode(pref.getString('currentUser') as String)));
                      //return print((u.runtimeType));
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
                      currentUser?.chats
                          ?.firstWhere((c) => c?.id == chat.id,
                              orElse: () => null as Chat)
                          ?.messages
                          ?.add(m);

                      loading = true;
                      setState(() {});
                      if (user != null) {
                        await ChatRepository.saveMessage(user!.id, m, context);
                      }
                      loading = false;
                      setState(() {});

                      //User u = currentUser!;

                      /* currentUser?.chats
                    ?.firstWhere((c) => c?.id == chat.id)!
                    .messages.sort(a,b) */

                      //print(m.uid);

                      // return print(jsonEncode(User.fromJson(
                      //     jsonDecode(pref.getString('currentUser') as String))));
                      //return print(jsonEncode(currentUser));

                      Provider.of<UserProvider>(context, listen: false)
                          .setCurrentUser(currentUser, save: false);
                      setState(() {});
                      controller!.text = "";
                    }
                  },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    getUser();
    resendDummy(widget.chat, context);

    super.initState();
  }

  getUser() async {
    currentUser =
        await Provider.of<UserProvider>(context, listen: false).currentUser();
    user = widget.chat.users?.firstWhere((user) => user?.id != currentUser?.id)
        as User;
    prevUserId = user?.id;

    ChatRepository.getMessages(user!.id, context);

    //await listenOnline(user!.id, currentUser!, context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return user == null
        ? loader()
        : Scaffold(
            backgroundColor: Color(0xFFF6F6F6),
            appBar: AppBar(
              brightness: Brightness.dark,
              centerTitle: true,
              title: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: user?.phone_number,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        )),
                    TextSpan(text: '\n'),
                    checkOnline(user!) ?? false
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
              leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ),
            body: Consumer<UserProvider>(builder: (context, model, child) {
              model.currentUser().then((value) => currentUser = value);

              List<Message> messages = widget.chat.messages as List<Message>;

              messages.sort((a, b) => b.created_at.compareTo(a.created_at));
              //Message? firstMessage = messages.last;
              // Where((message) => isSameDate(message.created_at, DateTime.now()),
              //     orElse: () => null as Message);
              prevDate = messages.isNotEmpty
                  ? messages.first.created_at
                  : DateTime.now();
              return currentUser == null
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
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
                              i = index;

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
                                          padding: EdgeInsets.all(10),
                                          margin: EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.lightBlue,
                                            borderRadius:
                                                BorderRadius.circular(15),
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
            }),
          );
  }
}
