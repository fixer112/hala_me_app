import 'dart:convert';

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

  Future<User?> currentUser() async {
    var pref = await getPref();
    User? user;
    //await pref.reload();
    try {
      var _user = pref.getString('currentUser') ??
          jsonDecode(pref.getString('currentUser') ?? '');

      user = _user != "" ? User.fromJson(jsonDecode(_user)) : null;
    } catch (e) {
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

    if (save == true) {
      getPref().then((pref) {
        try {
          var u = jsonEncode(user);
          pref.remove('currentUser');
          pref.setString('currentUser', u);
        } catch (e) {}
      });
    }

    //notifyListeners();
    //await pref.reload();
  }
}
