import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/chat_model.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/repositories/chat_repository.dart';
import 'package:hala_me/screens/chat_screen.dart';
import 'package:hala_me/values.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Contacts extends StatefulWidget {
  Contacts({Key? key}) : super(key: key);

  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  SharedPreferences? pref;

  bool loading = false;
  UserProvider provider = Get.put(UserProvider());

  User? currentUser;

  @override
  void initState() {
    //getPref().then((value) => pref = value);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        currentChatPage = 0;
        print(currentChatPage);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            brightness: Brightness.dark,
            elevation: 8,
            /* leading: IconButton(
            icon: Icon(Icons.menu),
            color: Colors.white,
            onPressed: () {},
          ), */
            title: Text(
              'Contacts',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            actions: <Widget>[
              loading == true
                  ? loader(color: Colors.white, scale: 0.4)
                  : IconButton(
                      icon: Icon(Icons.refresh),
                      color: Colors.white,
                      onPressed: () async {
                        var provider = Get.put(UserProvider());
                        setState(() {
                          loading = true;
                        });
                        await syncContacts(provider);
                        if (mounted) {
                          setState(() {
                            loading = false;
                          });
                        }
                      },
                    )
            ]),
        body: GetBuilder<UserProvider>(
            //init: UserProvider(),
            builder: (_) {
          provider.currentUser().then((value) => currentUser = value);
          return FutureBuilder<SharedPreferences>(
              future: getPref(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Container();
                }

                var p = snap.data;

                var nums = Map<String, String>.from(
                    jsonDecode(p?.getString('numberName') ?? '{}'));
                var data = Map<String, dynamic>.from(
                    jsonDecode(p?.getString('data') ?? '{}'));
                var numbers = nums.keys.toSet().toList();

                var datas = data.keys.toList();

                //print(numbers);

                List<String> validNumbers = [];
                numbers.forEach((element) {
                  numbers[numbers.indexOf(element)] = formatNumber(element);
                  if (datas.contains(formatNumber(element))) {
                    validNumbers.add(formatNumber(element));
                    //numbers.remove(formatNumber(element));
                  }
                });

                numbers = validNumbers.toSet().toList();
                numbers.removeWhere(
                    (number) => number == currentUser?.phone_number);

                //print(numbers);

                return currentUser == null
                    ? Container()
                    : Stack(
                        children: [
                          Container(
                            child: ListView.builder(
                                itemCount: numbers.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5.0),
                                    child: GestureDetector(
                                      onTap: loading
                                          ? null
                                          : () async {
                                              var id = int.parse(
                                                  data[numbers[index]]
                                                      .toString());
                                              Chat? chat = currentUser?.chats
                                                  ?.firstWhere(
                                                      (chat) => chat?.users
                                                          ?.where((u) =>
                                                              u?.id == id)
                                                          .isNotEmpty as bool,
                                                      orElse: () => null);
                                              //print(chat?.id);
                                              if (chat == null) {
                                                chat = Chat(
                                                  id: 0,
                                                  created_at: DateTime.now(),
                                                  users: [
                                                    currentUser,
                                                    User(
                                                      id: id,
                                                      online: false,
                                                      created_at:
                                                          DateTime.now(),
                                                      updated_at:
                                                          DateTime.now(),
                                                      phone_number:
                                                          numbers[index],
                                                    ),
                                                  ],
                                                  messages: [],
                                                );
                                              }

                                              //print(chat.users);
                                              if (chat.id == 0) {
                                                loading = true;
                                                setState(() {});
                                                chat = await ChatRepository
                                                    .getMessages(
                                                        chat, provider);
                                                loading = false;
                                                if (mounted) {
                                                  setState(() {});
                                                }
                                                if (chat != null) {
                                                  Get.to(
                                                      ChatScreen(chat: chat));
                                                } else {
                                                  snackbar('',
                                                      'unable to load chat.');
                                                }
                                              } else {
                                                Get.to(ChatScreen(chat: chat));
                                              }
                                            },
                                      child: Card(
                                        color: loading
                                            ? Colors.grey
                                            : Colors.white,
                                        child: ListTile(
                                          title: Text(
                                            getUserName(p!, numbers[index]),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(numbers[index]),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                          //loading == true ? loader() : Container(),
                        ],
                      );
              });
        }),
      ),
    );
  }
}
