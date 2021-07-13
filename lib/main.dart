// @dart=2.9
import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hala_me/global.dart';
import 'package:hala_me/provider/user_provider.dart';
import 'package:hala_me/screens/login_screen.dart';
import 'package:hala_me/screens/otp_screen.dart';
import 'package:hala_me/values.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

import 'screens/home_screen.dart';

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

Future<void> _messageHandler(RemoteMessage event) async {
  await Firebase?.initializeApp();
  //print('background message ${event.notification?.body}');
  // print(event.notification?.title);
  // print(event.notification?.body);
  // print(event.data);
  // print('Back');
  var data = event.data;
  data['sender'] = jsonDecode(event.data['sender']);
  data['chat'] = jsonDecode(event.data['chat']);
  messageCreatedAlert(data);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _enablePlatformOverrideForDesktop();
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      //'resource://drawable/res_app_icon',
      null,
      [
        NotificationChannel(
            channelKey: 'message_recieved',
            channelName: 'Message Notification',
            channelDescription: 'Notification for recieved messages.',
            defaultColor: primaryColor,
            ledColor: Colors.white)
      ]);
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      // Insert here your friendly dialog box before call the request method
      // This is very important to not harm the user experience
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  await Firebase?.initializeApp();
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(kReleaseMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  runApp(
    MyApp(),
    /* MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      //ChangeNotifierProvider(create: (_) => ChatProvider()),
    ], child: MyApp()), */
  );
}

//final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  FirebaseAnalytics analytics = FirebaseAnalytics();
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    Wakelock.enable();
    return GetMaterialApp(
      //navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      title: 'Hala Me',
      theme: ThemeData(
        primaryColor: primaryColor,
      ),
      home: /* OTPScreen('2348106813749') */ LoginScreen(force: false),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
    );
  }
}
