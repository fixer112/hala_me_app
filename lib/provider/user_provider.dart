import 'dart:convert';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:hala_me/screens/login_screen.dart';

class UserProvider extends GetxController {
  //ChangeNotifier /* with DiagnosticableTreeMixin */ {
  User?
      _currentUser /* = User(
          online: false,
          id: 0,
          phone_number: '',
          created_at: DateTime.now(),
          updated_at: DateTime.now())
      .obs */
      ;

  List<Contact>? contacts;

  Map<String, String> _numberName = {};

  Future<Map<String, String>?> numberName() async {
    return _numberName;
    // var pref = await getPref();
    // Map<String, String>? numberName;
    // //await pref.reload();
    // try {
    //   var numberName = pref.getString('numberName') ??
    //       jsonDecode(pref.getString('numberName') ?? '');

    //   numberName = numberName != ""
    //       ? Map<String, String>.from(jsonDecode(numberName))
    //       : null;
    // } catch (e) {}
    // return _numberName ?? numberName;
  }

  setNumberName(Map<String, String> numberName) async {
    _numberName = numberName;
    update();
    // var pref = await getPref();
    // var n = jsonEncode(numberName);
    // pref.remove('numberName');
    // pref.setString('numberName', n);
  }

  Future<User?> currentUser() async {
    var pref = await getPref();
    User? user;
    //await pref.reload();
    try {
      var _user = pref.getString('currentUser') ??
          jsonDecode(pref.getString('currentUser') ?? '');

      user = _user != "" ? User.fromJson(jsonDecode(_user)) : null;
    } catch (e) {
      _currentUser = null as User;
      Get.off(LoginScreen());
    }
    //_currentUser.refresh();
    //update();

    //notifyListeners();
    //print("current ${_currentUser.value?.access_token}");
    return _currentUser ?? user;
    //?? user!;
  }

  setCurrentUser(User user, {bool save = true}) {
    //print("set ${user.toJson()}");
    //User? u;
    _currentUser = user;
    //_currentUser.refresh();
    update();

    //if (save == true) {
      getPref().then((pref) {
        try {
          var u = jsonEncode(user);
          pref.remove('currentUser');
          pref.setString('currentUser', u);
        } catch (e) {}
      });
    //}

    //notifyListeners();
    //await pref.reload();
  }
}
