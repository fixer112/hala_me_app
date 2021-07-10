import 'dart:async';

import 'package:flutter/cupertino.dart';

class Debouncer {
  final int miliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.miliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: miliseconds), action);
  }
}
