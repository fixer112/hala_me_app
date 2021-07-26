import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:hala_me/config.dart';
import 'package:hala_me/debouncer.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/chat_repository.dart';
import 'package:hala_me/screens/home_screen.dart';
import 'package:hala_me/values.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
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
  final debouncer = Debouncer(miliseconds: 700);

  UserProvider provider = Get.find();

  DateTime? prevDate;

  TextEditingController? controller = TextEditingController();

  bool loading = false;

  PrivateChannel? channel;
  Map<String, String>? nums = {};

  SharedPreferences? pref;

  List<String> deleting = [];

  List<Message> pressedMessages = [];

  Message? repling;

  AutoScrollController? scrollController;
  //final _slidableKey = GlobalKey();

  Map<int, int> indexes = {};

  bool scrollUpdating = false;

  Widget _chatBubble(Message message, bool isMe, bool isSameUser) {
    var repliedMessage = widget.chat.messages?.firstWhere(
        (msg) => msg?.id == message.replied_id,
        orElse: () => null as Message);
    //print(message.replied_id);
    return /* isMe
        ?  */
        Slidable(
      key: ValueKey(message.uid),

      //actionPane: SlidableDrawerActionPane(),
      //actionExtentRatio: 0.1,
      //showAllActionsThreshold: 0.1,
      //dismissal: SlidableDismissal(),
      startActionPane: ActionPane(
        motion: ScrollMotion(),
        extentRatio: 0.2,
        openThreshold: 0.3,
        //closeThreshold: 0.4,

        children: message.dummy == true
            ? []
            : [
                IconButton(
                    onPressed: () {
                      repling = message;
                      //if (mounted) {
                      setState(() {});

                      Slidable.of(context)?.close();
                      //}
                    },
                    icon: Icon(
                      Icons.reply,
                      color: primaryColor,
                    ))
              ],
      ),
      endActionPane: ActionPane(
        motion: ScrollMotion(),
        extentRatio: 0.2,
        openThreshold: 0.3,
        //closeThreshold: 0.4,
        children: [
          deleting.contains(message.uid)
              ? loader(scale: 0.4)
              : IconButton(
                  onPressed: deleting.contains(message.uid)
                      ? null
                      : () async {
                          deleting.add(message.uid);

                          setState(() {});
                          await ChatRepository.deleteMessages(
                              widget.chat, [message.uid], provider);

                          deleting.removeWhere((id) => id == message.uid);

                          if (mounted) {
                            Slidable.of(context)?.close();
                            setState(() {});
                          }
                        },
                  icon: Icon(
                    Icons.delete,
                    color: primaryColor,
                  ))
        ],
      ),
      child: InkWell(
        onLongPress: () {
          pressedMessages.contains(message)
              ? pressedMessages.removeWhere((msg) => message.uid == msg.uid)
              : pressedMessages.add(message);
          setState(() {});
        },
        onTap: () {
          if (pressedMessages.isNotEmpty) {
            pressedMessages.contains(message)
                ? pressedMessages.removeWhere((msg) => message.uid == msg.uid)
                : pressedMessages.add(message);
            setState(() {});
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              alignment: Alignment.topRight,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.80,
                ),
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isMe ? Theme.of(context).primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  /* boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 1,
                    ),
                  ], */
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    repliedMessage == null
                        ? Container()
                        : GestureDetector(
                            onTap: () {
                              print(repliedMessage.id);
                              if (indexes.containsKey(repliedMessage.id)) {
                                print(indexes[repliedMessage.id]);
                                scrollController?.scrollToIndex(
                                    indexes[repliedMessage.id]!,
                                    preferPosition: AutoScrollPosition.end);
                                scrollController
                                    ?.highlight(indexes[repliedMessage.id]!);
                              }

                              print('tap');
                            },
                            child: Container(
                              width: Get.width,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: EdgeInsets.all(5),
                              margin: EdgeInsets.all(5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    repliedMessage.sender.id == currentUser?.id
                                        ? 'You'
                                        : getUserName(pref!,
                                            repliedMessage.sender.phone_number),
                                    style: TextStyle(
                                      color: repliedMessage.sender.id ==
                                              currentUser?.id
                                          ? primaryColor
                                          : Colors.purple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(repliedMessage.body,
                                      style: TextStyle(
                                        color: Colors.white,
                                      )),
                                  SizedBox(
                                    height: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      //mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          message.body,
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black54),
                        ),
                        SizedBox(
                          height: 1,
                        ),
                        Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.end,
                          //crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            isMe ? statusIcon(message) : Container(),
                            Text(
                              formatTime(message.created_at),
                              style: TextStyle(
                                color: isMe ? Colors.blueGrey : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sendMessageArea() {
    var chat = widget.chat;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      height: 50,
      color: Colors.white,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            iconSize: 25,
            color: Theme.of(context).primaryColor,
            onPressed: () {
              snackbar('', 'Coming soon');
            },
          ),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.multiline,
              maxLines: null,
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
            onPressed:
                /* loading == true || chat.id == 0
                ? null
                :  */
                () async {
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
                  replied_id: repling == null ? null : repling?.id,
                );
                var c = currentUser?.chats?.firstWhere((c) => c?.id == chat.id,
                    orElse: () => null as Chat);

                currentUser?.chats?.removeWhere((c) => c?.id == chat.id);
                c?.messages = List.from(c.messages as List<Message>)..add(m);
                currentUser?.chats = List.from(currentUser?.chats as List<Chat>)
                  ..add(c);
                provider.setCurrentUser(currentUser!, save: true);

                controller!.text = "";
                repling = null;
                scrollController?.animateTo(0.0,
                    curve: Curves.easeOut,
                    duration: Duration(milliseconds: 300));

                loading = true;
                setState(() {});
                //if (user != null) {
                Message? message =
                    await ChatRepository.saveMessage(user!.id, m, provider);

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
    scrollController = AutoScrollController(
      //add this for advanced viewport boundary. e.g. SafeArea
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),

      //choose vertical/horizontal
      axis: Axis.vertical,

      //this given value will bring the scroll offset to the nearest position in fixed row height case.
      //for variable row height case, you can still set the average height, it will try to get to the relatively closer offset
      //and then start searching.
      //suggestedRowHeight: 200,
    );
    scrollController?.addListener(() {});
    currentChatPage = widget.chat.id;
    print(currentChatPage);

    //print(globalEcho?.connector);
    whisperType();
    getPref().then((value) => pref = value);
    getUser().then((value) async {
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
      if (widget.chat.id != 0) {
        ChatRepository.getMessages(widget.chat, provider)?.then((chat) {
          if (chat != null) {
            /* chat.messages?.forEach((m) {

              m?.read = true;
            }); */
            widget.chat = chat;

            //setState(() {});
          }
        });
      }

      /* var cu = await provider.currentUser();
      cu?.chats?.removeWhere((chat) => widget.chat.id == chat?.id);
      cu?.chats = List.from(cu.chats as List<Chat>)..add(widget.chat);
      provider.setCurrentUser(cu!); */
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
    scrollController?.dispose();
    super.dispose();
  }

  whisperType() async {
    //print('whisper');
    controller!.addListener(() async {
      //print(controller?.text);

      //t1 = Timer(const Duration(milliseconds: 500), () async {
      debouncer.run(() => ChatRepository.typing(widget.chat, provider));
    });
  }

  resend() {
    //if (!mounted) return;
    //print("test");
    if (widget.chat.id != 0) {
      resendDummy(widget.chat, provider).then((chat) => widget.chat == chat);
    }
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
              if (pressedMessages.isNotEmpty) {
                pressedMessages = [];
                setState(() {});
                return false;
              }
              currentChatPage = 0;
              print(currentChatPage);
              Get.to(HomeScreen());

              return true;
            },
            child: Scaffold(
              floatingActionButton: scrollUpdating == false
                  ? Container()
                  : Container(
                      margin: EdgeInsets.only(bottom: 50),
                      child: ClipOval(
                        child: Material(
                          color: Colors.white, // button color
                          child: InkWell(
                            splashColor:
                                primaryColor.withOpacity(0.5), // inkwell color
                            child: SizedBox(
                                width: 35,
                                height: 35,
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color: primaryColor,
                                )),
                            onTap: () {
                              scrollController?.animateTo(0.0,
                                  curve: Curves.easeOut,
                                  duration: Duration(milliseconds: 300));
                            },
                          ),
                        ),
                      ),
                    ),
              backgroundColor: Color(0xFFF6F6F6),
              appBar: AppBar(
                brightness: Brightness.dark,
                centerTitle: false,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    pressedMessages.isNotEmpty
                        ? Container(
                            child: Text(pressedMessages.length.toString()),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "${AppConfig.RAW_BASE_URL}/${user!.imageUrl}",
                                  imageBuilder: (context, imageProvider) =>
                                      SizedBox(
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
                                  placeholder: (context, url) =>
                                      loader(scale: 0.5),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                RichText(
                                  textAlign: TextAlign.start,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                          text: limitString(
                                              getUserName(pref!,
                                                  user?.phone_number ?? ''),
                                              20),
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
                              ]),
                    pressedMessages.isEmpty
                        ? Container()
                        : Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  var text = '';
                                  pressedMessages.forEach((msg) {
                                    text += "${msg.body} \t";
                                  });
                                  Clipboard.setData(
                                          new ClipboardData(text: text))
                                      .then((_) {
                                    snackbar('', 'message(s) copied.',
                                        duration: 2);
                                  });
                                  pressedMessages = [];
                                  if (mounted) {
                                    Slidable.of(context)?.close();
                                    setState(() {});
                                  }
                                },
                                icon: Icon(Icons.copy),
                                color: Colors.white,
                              ),
                              deleting.isNotEmpty
                                  ? loader(scale: 0.4, color: Colors.white)
                                  : IconButton(
                                      onPressed: () async {
                                        var ids = pressedMessages
                                            .map((m) => m.uid)
                                            .toSet()
                                            .toList();
                                        deleting.addAll(ids);
                                        setState(() {});
                                        await ChatRepository.deleteMessages(
                                            widget.chat, ids, provider);
                                        deleting = [];
                                        pressedMessages = [];
                                        if (mounted) {
                                          Slidable.of(context)?.close();
                                          setState(() {});
                                        }
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      )),
                            ],
                          )
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
                                  (chat) => chat?.id == widget.chat.id,
                                  orElse: null) as Chat;
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
                            child: NotificationListener<ScrollEndNotification>(
                              onNotification: (notify) {
                                var metrics = notify.metrics;
                                /* if (notify is ScrollStartNotification) {
                                  scrollUpdating = true;
                                  setState(() {});

                                  //_onStartScroll(scrollNotification.metrics);
                                } else if (notify is ScrollUpdateNotification) {
                                  scrollUpdating = true;
                                  setState(() {});
                                  //_onUpdateScroll(scrollNotification.metrics);
                                } else if (notify is ScrollEndNotification) {
                                  scrollUpdating = false;
                                  setState(() {});
                                  //_onEndScroll(scrollNotification.metrics);
                                } */
                                //print(scrollUpdating);

                                if (metrics.hasPixels) {
                                  if (metrics.pixels == 0) {
                                    print('At bottom');
                                    scrollUpdating = false;
                                  } else {
                                    print('At top');
                                    scrollUpdating = true;
                                  }
                                  print(metrics.pixels);
                                  print(scrollUpdating);
                                  setState(() {});
                                }

                                return true;
                              },
                              child: ListView.builder(
                                controller: scrollController,
                                reverse: true,
                                //padding: EdgeInsets.all(20),
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
                                  indexes[message.id] = index;
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

                                  return AutoScrollTag(
                                    controller: scrollController!,
                                    index: index,
                                    key: ValueKey(index),
                                    child: Column(
                                      //mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            lastMessage.uid == message.uid
                                                // ||
                                                //         !isSameDate(lastMessage.created_at,
                                                //             message.created_at)
                                                //lastMessage.created_at != message.created_at
                                                //||firstMessage?.uid == message.uid
                                                ? Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                            vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                    ),
                                                    child: Text(
                                                        chatDate(
                                                            message.created_at),
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  )
                                                : Container(),
                                          ],
                                        ),
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: isSameUser ? 1 : 10),
                                          padding:
                                              EdgeInsets.symmetric(vertical: 3),
                                          color:
                                              !pressedMessages.contains(message)
                                                  ? Colors.transparent
                                                  : primaryColor.withAlpha(50),
                                          child: Row(
                                            /* crossAxisAlignment:
                                                CrossAxisAlignment.start, */
                                            mainAxisAlignment: !isMe
                                                ? MainAxisAlignment.start
                                                : MainAxisAlignment.end,
                                            children: [
                                              _chatBubble(
                                                  message, isMe, isSameUser),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              repling == null
                                  ? Container()
                                  : Container(
                                      margin: EdgeInsets.only(top: 10),
                                      width: Get.width,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(15),
                                            topRight: Radius.circular(15)),
                                      ),
                                      height: 80,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        padding: EdgeInsets.all(20),
                                        margin: EdgeInsets.only(
                                            left: 15, right: 15, top: 5),
                                        //padding: ,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  repling?.sender.id ==
                                                          currentUser?.id
                                                      ? 'You'
                                                      : getUserName(
                                                          pref!,
                                                          repling!.sender
                                                              .phone_number),
                                                  style: TextStyle(
                                                    color: repling?.sender.id ==
                                                            currentUser?.id
                                                        ? primaryColor
                                                        : Colors.purple,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  limitString(
                                                      repling!.body, 30),
                                                  style:
                                                      TextStyle(fontSize: 10),
                                                ),
                                              ],
                                            ),
                                            IconButton(
                                                onPressed: () {
                                                  repling = null;
                                                  setState(() {});
                                                },
                                                icon: Icon(
                                                  Icons.cancel_outlined,
                                                  size: 15,
                                                  color: primaryColor,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ),
                              _sendMessageArea(),
                            ],
                          ),
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
