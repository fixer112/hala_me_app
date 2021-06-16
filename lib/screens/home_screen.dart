import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/message_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/user_repository.dart';
import 'package:hala_me/screens/chat_screen.dart';
import 'package:hala_me/screens/login_screen.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final bool first;

  HomeScreen({this.first = false});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  User? currentUser;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  resend(BuildContext con) async {
    User? user =
        await Provider.of<UserProvider>(con, listen: false).currentUser();
    user?.chats?.forEach((chat) async {
      await resendDummy(chat!, con);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    //initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    getUser(context).then((User user) {
      print(widget.first);
      if (widget.first == true) {
        Echo echo = initPusher(user);
        //return print("token ${user.access_token}");
        user.chats?.forEach((chat) async {
          User? u = chat?.users?.firstWhere((u) => u?.id != user.id);

          await listenChat(echo, chat!.id, user, context);

          if (u != null) {
            await listenOnline(echo, u.id, user, context);
          }
        });
      }
    });

    resend(context);
    // Timer.periodic(new Duration(minutes: 1), (timer) {
    //   resend(context);
    // });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
    if (state == AppLifecycleState.paused) {
      UserRepository.setOnlineStatus(context, status: 0);
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
        print(result);
        await UserRepository.fetchUser(context);
        await resend(context);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          brightness: Brightness.dark,
          elevation: 8,
          leading: IconButton(
            icon: Icon(Icons.menu),
            color: Colors.white,
            onPressed: () {},
          ),
          title: Text(
            'Inbox',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.logout),
              color: Colors.white,
              onPressed: () {
                Provider.of<UserProvider>(context, listen: false)
                    .setCurrentUser(null as User);
                Get.off(LoginScreen());
              },
            ),
          ],
        ),
        body: Consumer<UserProvider>(builder: (context, model, child) {
          model.currentUser().then((value) => currentUser = value);
          currentUser?.chats?.sort((a, b) {
            a?.messages?.sort((a, b) => b!.created_at.compareTo(a!.created_at));
            b?.messages?.sort((a, b) => b!.created_at.compareTo(a!.created_at));

            return b!.messages!.first!.created_at
                .compareTo(a!.messages!.first!.created_at);
          });
          //print(jsonEncode(currentUser?.chats));
          return currentUser == null
              ? loader()
              : ListView.builder(
                  itemCount: currentUser?.chats?.length,
                  itemBuilder: (BuildContext context, int index) {
                    Chat? chat = currentUser?.chats?[index];
                    //print(jsonEncode(chat));
                    User? chatUser = chat?.users
                        ?.firstWhere((user) => user?.id != currentUser?.id);
                    List<Message> messages = chat?.messages as List<Message>;
                    messages
                        .sort((a, b) => b.created_at.compareTo(a.created_at));
                    final Message? message =
                        messages.isNotEmpty ? messages.first : null;
                    bool read = messages.isNotEmpty
                        ? messages
                            .firstWhere(
                                (message) =>
                                    message.sender.id != currentUser?.id,
                                orElse: () => null as Message)
                            ?.read as bool
                        : false;

                    List<Message> unreads = chat?.messages
                        ?.where((message) =>
                            message!.read == false &&
                            message.sender.id != currentUser!.id)
                        .toSet()
                        .toList() as List<Message>;

                    //print(chat?.messages?.last?.id);
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
                              decoration: read ?? false //chat.unread
                                  ? BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(40)),
                                      border: Border.all(
                                        width: 2,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      // shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    )
                                  : BoxDecoration(
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
                                radius: 35,
                                backgroundImage: AssetImage(
                                    'assets/images/black-widow.jpg' /* chat.sender.imageUrl */),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.65,
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
                                            chatUser!.phone_number,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          checkOnline(chatUser)
                                              ? Container(
                                                  margin: const EdgeInsets.only(
                                                      left: 5),
                                                  width: 7,
                                                  height: 7,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Theme.of(context)
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
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  message.sender.id ==
                                                          currentUser?.id
                                                      ? Container(
                                                          child: statusIcon(
                                                              message),
                                                        )
                                                      : Container(),
                                                  SizedBox(
                                                    width: 5,
                                                  ),
                                                  Text(
                                                    message.body.length > 20
                                                        ? message.body
                                                            .substring(0, 20)
                                                        : message.body,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black54,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ],
                                              ),
                                              unreads.length > 0
                                                  ? Container(
                                                      height: 20,
                                                      width: 20,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    20)),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          unreads.length
                                                              .toString(),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
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
        }));
  }
}
