// @dart=2.9
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/screens/login_screen.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() {
  _enablePlatformOverrideForDesktop();
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      //ChangeNotifierProvider(create: (_) => ChatProvider()),
    ], child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hala Me',
      theme: ThemeData(
        primaryColor: Color(0xFF01afbd),
      ),
      home: LoginScreen(force: false),
    );
  }
}
