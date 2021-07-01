import 'dart:convert';
import 'dart:ui';

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
                      setState(() {
                        loading = false;
                      });
                    },
                  )
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

            //print(numbers);

            return Container(
              child: ListView.builder(
                  itemCount: numbers.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Card(
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
                    );
                  }),
            );
          }),
    );
  }
}
