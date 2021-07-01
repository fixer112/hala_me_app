import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Contacts extends StatefulWidget {
  Contacts({Key? key}) : super(key: key);

  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  SharedPreferences? pref;

  bool loading = false;

  @override
  void initState() {
    //getPref().then((value) => pref = value);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            loading == false
                ? IconButton(
                    icon: Icon(Icons.refresh),
                    color: Colors.white,
                    onPressed: loading == true
                        ? null
                        : () {
                            var provider = Get.put(UserProvider());
                            setState(() {
                              loading = true;
                            });
                            syncContacts(provider);
                            setState(() {
                              loading = false;
                            });
                          },
                  )
                : loader()
          ]),
      body: FutureBuilder<SharedPreferences>(
          future: getPref(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return Container();
            }

            var p = snap.data;

            var nums = Map<String, String>.from(
                jsonDecode(p?.getString('numberName') ?? '{}'));
            var numbers = nums.keys.toSet().toList();

            return Container(
              child: ListView.builder(
                  itemCount: numbers.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Card(
                        child: ListTile(
                          title: Text(getUserName(p!, numbers[index])),
                          subtitle: Text(numbers[index]),
                        ),
                      ),
                    );
                  }),
            );
          }),
    );
  }
}
