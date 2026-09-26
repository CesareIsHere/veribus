import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs only the last call made within [duration] (search fields, autosave).
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 400)});

  final Duration duration;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() => _timer?.cancel();
}
