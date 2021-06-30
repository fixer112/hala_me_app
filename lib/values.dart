//import 'package:flutter_pusher_client/flutter_pusher.dart';
import 'package:flutter/material.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:laravel_echo/src/channel/private-channel.dart';
import 'package:laravel_echo/src/channel/channel.dart';

int currentChatPage = 0;
String currentSocketId = "";
Echo? globalEcho;
// Map<int, PrivateChannel> echos = {};
Color primaryColor = Color(0xFF075e54);
