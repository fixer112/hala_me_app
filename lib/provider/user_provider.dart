import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/models/user_model.dart';
import 'package:laravel_echo/laravel_echo.dart';

class UserProvider with ChangeNotifier, DiagnosticableTreeMixin {
  User? _currentUser;

  Future<User?> currentUser() async {
    var pref = await getPref();
    //await pref.reload();
    var _user = pref.getString('currentUser') ??
        jsonDecode(pref.getString('currentUser') ?? '');
    User? user;

    user = _user != null ? User.fromJson(jsonDecode(_user)) : null;

    notifyListeners();
    //print("current $_currentUser");
    return _currentUser ?? user;
    //?? user!;
  }

  setCurrentUser(User? user, {bool save = true}) async {
    //print("set ${user.toJson()}");
    _currentUser = user;
    var pref = await getPref();
    if (user != null && save == true) {
      pref.remove('currentUser');
      pref.setString('currentUser', jsonEncode(user));
    }
    //await pref.reload();
    notifyListeners();
  }
}
