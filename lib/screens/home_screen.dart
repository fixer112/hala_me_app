import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/chat_repository.dart';
import 'package:hala_me/repositories/user_repository.dart';
import 'package:hala_me/screens/chat_screen.dart';
import 'package:hala_me/screens/contacts_screen.dart';
import 'package:hala_me/screens/login_screen.dart';
import 'package:hala_me/values.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  final bool first;

  HomeScreen({this.first = false});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? timer;
  UserProvider provider = Get.put(UserProvider());
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Map<String, String>? nums = {};
  SharedPreferences? pref;

  resend() async {
    //print('dummy');

    User? user = await provider.currentUser();
    //await Provider.of<UserProvider>(con, listen: false).currentUser();
    user?.chats?.forEach((chat) async {
      await resendDummy(chat!, provider);
    });
  }

  notificationAction() async {
    var u = await provider.currentUser();

    AwesomeNotifications().actionStream.listen((receivedNotification) async {
      print("message recieved : ${receivedNotification.channelKey}");
      if (receivedNotification.channelKey != 'message_recieved') {
        return;
      }
      Map<String, String> payload =
          receivedNotification.payload as Map<String, String>;
      int chatId = int.parse(payload['chat_id'] as String);
      int messageId = int.parse(payload['message_id'] as String);
      int userId = int.parse(payload['user_id'] as String);
      Chat chat = u?.chats?.firstWhere((chat) => chat?.id == chatId) as Chat;
      //print(chat.id);

      if (!StringUtils.isNullOrEmpty(receivedNotification.buttonKeyInput)) {
        var m = Message(
          read: false,
          delivered: false,
          id: 0,
          body: receivedNotification.buttonKeyInput,
          chat: chat,
          created_at: DateTime.now(),
          dummy: true,
          sender: u!,
          uid: Uuid().v4(),
        );
        await ChatRepository.saveMessage(userId, m, provider);
        await ChatRepository.getMessages(chat, provider);
        //processInputTextReceived(receivedNotification);
        return;
      } else if (!StringUtils.isNullOrEmpty(
              receivedNotification.buttonKeyPressed) &&
          receivedNotification.buttonKeyPressed == 'READ') {
        await ChatRepository.getMessages(chat, provider);
        return;
      }
      //else {
      //print('work');
      Get.to(ChatScreen(chat: chat));
    }

        // your page params. I recommend to you to pass all *receivedNotification* object
        // }
        );
  }

  @override
  void initState() {
    //initConnectivity();

    getUser(provider).then((User user) {
      //print(user.access_token);
      //return;

      if (widget.first == true) {
        WidgetsBinding.instance!.addObserver(this);
        notificationAction();
        _connectivitySubscription =
            _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

        Echo echo = initPusher(user);

        globalEcho = echo;
        //print("echo socket id ${echo.sockedId()}");
        //return print("token ${user.access_token}");
        user.chats?.forEach((chat) async {
          User? u = chat?.users?.firstWhere((u) => u?.id != user.id);

          listenChat(echo, chat!.id, provider, context);

          if (u != null) {
            listenOnline(echo, u.id, provider, context);
          }
        });

        syncContacts(provider);
        timer = Timer.periodic(new Duration(minutes: 2), (timer) => resend());
      }
    });
    //WidgetsBinding.instance!.addPostFrameCallback((_) => resend(context));
    // Timer.periodic(new Duration(minutes: 1), (timer) {
    //resend(context);

    // });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    AwesomeNotifications().actionSink.close();
    _connectivitySubscription.cancel();
    timer?.cancel();

    super.dispose();
  }

  /* @override
  void didChangeDependencies() {
    currentChatPage = 0;
    print("current page $currentChatPage");
    super.didChangeDependencies();
  } */

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print(state);
    if (state == AppLifecycleState.paused) {
      /* var p = Get.put(UserProvider());
      p.currentUser().then((value) => print(value?.chats)); */
      await UserRepository.setOnlineStatus(provider, status: 0);
    }
    if (state == AppLifecycleState.resumed) {
      //var p = Get.put(UserProvider());
      await UserRepository.fetchUser(provider);
      await resend();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> initConnectivity() async {
    ConnectivityResult result = ConnectivityResult.none;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
        //case ConnectivityResult.none:
        //print(result);
        var p = Get.put(UserProvider());
        await UserRepository.fetchUser(p);
        //await resend(context);
        break;
      case ConnectivityResult.none:
        //UserRepository.setOnlineStatus(context, status: 0);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    //currentChatPage = 0;
    getPref().then((value) => pref = value);
    //print("current page $currentChatPage");
    // return GetX<UserProvider>(
    //     init: UserProvider(),
    //     builder: (provider) {

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        floatingActionButton: GestureDetector(
          onTap: () {
            //print(pref!.getString('data'));
            //UserRepository.checkNumbers(provider, ['08034235999']);
          },
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            child: IconButton(
              icon: Icon(Icons.message, color: Colors.white),
              onPressed: () {
                Get.to(Contacts());
              },
            ),
          ),
        ),
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          brightness: Brightness.dark,
          elevation: 8,
          leading: null,
          title: Text(
            "Hala Me",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.logout),
              color: Colors.white,
              onPressed: () async {
                //print('test');
                // await syncContacts(provider);
                // Map<String, String>? nums = await provider.numberName();
                // print("end $nums");
                //print(provider.contacts?.length);
                // print(getUserContact(nums ?? {}, '2348034235999'));
                //print(getUserName(provider, '2348034235999'));

                //print(comparePhoneNumber(['2348034235999'], ['08034235999']));
                /* Provider.of<UserProvider>(context, listen: false)
                      .setCurrentUser(null as User); */
                provider.setCurrentUser(null as User);
                Get.off(LoginScreen());
              },
            ),
          ],
        ),
        body: GetBuilder<UserProvider>(
            //init: UserProvider(),
            builder: (_) {
          //provider.numberName().then((value) => nums = value);
          return FutureBuilder<User?>(
              future: provider.currentUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || pref == null) {
                  return loader();
                }
                User? currentUser = snapshot.data;
                //print("user ${currentUser?.chats}");
                // if (currentUser?.chats != null) {
                //   currentUser?.chats?.forEach((chat) {
                //     chat?.messages?.sort(
                //         (a, b) => b!.created_at.compareTo(a!.created_at));

                //     //chat?.messages?.forEach((m) {});
                //   });

                currentUser?.chats?.sort((a, b) {
                  var aD = a!.messages!.isNotEmpty
                      ? a.messages?.first?.created_at
                      : a.created_at;
                  var bD = b!.messages!.isNotEmpty
                      ? b.messages?.first?.created_at
                      : b.created_at;

                  return bD!.compareTo(aD!);
                });

                return currentUser?.chats == null
                    ? Container()
                    : ListView.builder(
                        itemCount: currentUser?.chats?.length,
                        itemBuilder: (BuildContext context, int index) {
                          Chat? chat = currentUser?.chats?[index];
                          //print(chat?.typing);
                          //print(jsonEncode(chat));
                          User? chatUser = chat?.users?.firstWhere(
                              (user) => user?.id != currentUser?.id);
                          List<Message> messages =
                              chat?.messages as List<Message>;
                          //if (messages.isNotEmpty) {
                          messages.sort(
                              (a, b) => b.created_at.compareTo(a.created_at));
                          //}
                          final Message? message =
                              messages.isNotEmpty ? messages.first : null;

                          final Message? uLm = messages.isNotEmpty
                              ? messages.firstWhere(
                                  (m) => m.sender.id != currentUser?.id,
                                  orElse: () => null as Message)
                              : null;

                          List<Message> unreads = messages
                              .where(
                                (message) =>
                                    message.read == false &&
                                    message.sender.id != currentUser!.id,
                              )
                              .toList();

                          //print(unreads.isNotEmpty ? unreads.first.read : 0);
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chat: chat!,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.all(2),
                                    decoration:
                                        (uLm?.read == false) //chat.unread
                                            ? BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(40)),
                                                border: Border.all(
                                                  width: 2,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                                // shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    spreadRadius: 2,
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              )
                                            : BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    spreadRadius: 2,
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundImage: AssetImage(
                                          'assets/images/black-widow.jpg' /* chat.sender.imageUrl */),
                                    ),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.65,
                                    padding: EdgeInsets.only(
                                      left: 20,
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Text(
                                                  getUserName(pref!,
                                                      chatUser!.phone_number),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                checkOnline(chatUser)
                                                    ? Container(
                                                        margin: const EdgeInsets
                                                            .only(left: 5),
                                                        width: 7,
                                                        height: 7,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                        ),
                                                      )
                                                    : Container(
                                                        child: null,
                                                      ),
                                              ],
                                            ),
                                            Text(
                                              formatTime(message != null
                                                  ? message.created_at
                                                  : chat!.created_at),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w300,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        message != null
                                            ? Container(
                                                alignment: Alignment.topLeft,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        message.sender.id ==
                                                                currentUser?.id
                                                            ? Container(
                                                                child:
                                                                    statusIcon(
                                                                        message),
                                                              )
                                                            : Container(),
                                                        SizedBox(
                                                          width: 5,
                                                        ),
                                                        /* (chat?.typing == null
                                                                ? true
                                                                :  */
                                                        chat?.typing == false
                                                            ? Text(
                                                                message.body.length >
                                                                        20
                                                                    ? message
                                                                        .body
                                                                        .substring(
                                                                            0,
                                                                            20)
                                                                    : message
                                                                        .body,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .black54,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 2,
                                                              )
                                                            : Text(
                                                                'Typing...',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .green),
                                                              ),
                                                      ],
                                                    ),
                                                    unreads.isNotEmpty
                                                        ? Container(
                                                            height: 20,
                                                            width: 20,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                              borderRadius: BorderRadius
                                                                  .all(Radius
                                                                      .circular(
                                                                          20)),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                unreads.length
                                                                    .toString(),
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : Container()
                                                  ],
                                                ),
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
              });
          //});
        }),
      ),
    );
  }
}
